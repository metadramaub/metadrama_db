import type { PageServerLoad } from './$types';
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

	const [jornadasResp, cuadrosResp, secuenciasResp, secuenciasMetrosResp, vocabResp, rangosResp, autoresResp] =
		await Promise.all([
			locals.supabase.from('jornadas').select('*').eq('obra_id', obra.obra_id).order('v_ini'),
			locals.supabase.from('cuadros').select('*').order('v_ini'),
			locals.supabase
				.from('secuencias_metricas')
				.select('*')
				.eq('obra_id', obra.obra_id)
				.order('v_ini'),
			locals.supabase.from('secuencias_metros').select('*'),
			locals.supabase
				.from('vocabularios')
				.select('termino_id,categoria,termino,termino_padre_id,orden')
				.eq('activo', true)
				.in('categoria', [
					'genero',
					'estado',
					'estado_revision',
					'certeza_editor',
					'estrofa_tipo',
					'metro',
					'personajes_genero',
					'personajes_donaire',
					'personajes_sobrenatural'
				]),
			locals.supabase.from('rangos').select('*').eq('obra_id', obra.obra_id).order('v_ini'),
			locals.supabase
				.from('autores')
				.select('autor_id,nombre_completo,nombre_normalizado')
				.order('nombre_normalizado')
		]);

	const jornadas = (jornadasResp.data ?? []) as Tables<'jornadas'>[];
	const cuadros = ((cuadrosResp.data ?? []) as Tables<'cuadros'>[]).filter((cuadro) =>
		jornadas.some((jornada) => jornada.jornada_id === cuadro.jornada_id)
	);
	const secuencias = (secuenciasResp.data ?? []) as Tables<'secuencias_metricas'>[];
	const secuenciaIds = secuencias.map((row) => row.secuencia_id);
	const secuenciasMetros = (
		(secuenciasMetrosResp.data ?? []) as Tables<'secuencias_metros'>[]
	).filter((item) => secuenciaIds.includes(item.secuencia_id));

	const rangos = (rangosResp.data ?? []) as Tables<'rangos'>[];
	const rangoIds = rangos.map((row) => row.rango_id);
	const rangosAutoresResp =
		rangoIds.length > 0
			? await locals.supabase.from('rangos_autores').select('*').in('rango_id', rangoIds)
			: { data: [] };
	const rangosAutores = (rangosAutoresResp.data ?? []) as Tables<'rangos_autores'>[];
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
		secuenciasMetros,
		rangos,
		rangosAutores,
		autores: autoresResp.data ?? [],
		vocabularios: vocabResp.data ?? []
	};
};
