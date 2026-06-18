import type { PageServerLoad } from './$types';
import { countUnambiguousAutoriaGroups } from '$lib/server/autoria';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';

export const load: PageServerLoad = async ({ locals, params }) => {
	const { obra, profile, estadoTerm, assignedReviewer, capabilities } = await getObraContext(
		{ locals },
		params.id,
		{
			requireEdit: false
		}
	);

	const [jornadasResp, cuadrosResp, secuenciasResp, vocabResp] = await Promise.all([
		locals.supabase.from('jornadas').select('*').eq('obra_id', obra.obra_id).order('v_ini'),
		locals.supabase.from('cuadros').select('*').order('v_ini'),
		locals.supabase
			.from('secuencias_metricas')
			.select('*')
			.eq('obra_id', obra.obra_id)
			.order('v_ini'),
		locals.supabase
			.from('vocabularios')
			.select('termino_id,categoria,termino,etiqueta,termino_padre_id,orden')
			.eq('activo', true)
			.in('categoria', [
				'genero',
				'estado',
				'certeza_editor',
				'estrofa_tipo',
				'caracterizacion_rango',
				'personajes_donaire',
				'personajes_sobrenatural'
			])
	]);

	const jornadas = (jornadasResp.data ?? []) as Tables<'jornadas'>[];
	const cuadros = ((cuadrosResp.data ?? []) as Tables<'cuadros'>[]).filter((cuadro) =>
		jornadas.some((jornada) => jornada.jornada_id === cuadro.jornada_id)
	);
	const secuencias = (secuenciasResp.data ?? []) as Tables<'secuencias_metricas'>[];
	const autoriaNoAmbiguaCount = await countUnambiguousAutoriaGroups(locals.supabase, obra.obra_id);

	const editorAsignadoResp = obra.editor_asignado
		? await locals.supabase
				.from('editores')
				.select('nombre_completo')
				.eq('user_id', obra.editor_asignado)
				.maybeSingle()
		: { data: null };

	return {
		profile,
		obra,
		estadoTerm,
		assignedReviewer,
		capabilities,
		editorAsignadoNombre: editorAsignadoResp.data?.nombre_completo ?? null,
		jornadas,
		cuadros,
		secuencias,
		autoriaNoAmbiguaCount,
		vocabularios: vocabResp.data ?? []
	};
};
