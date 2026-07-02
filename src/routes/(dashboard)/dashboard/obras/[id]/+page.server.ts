import type { PageServerLoad } from './$types';
import { countUnambiguousAutoriaGroups } from '$lib/server/autoria';
import { getObraContext } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import type { Tables } from '$lib/types/database.types';

export const load: PageServerLoad = async ({ locals, params, depends }) => {
	depends(`dashboard:obra:${params.id}`);

	const { obra, profile, estadoTerm, assignedReviewer, capabilities } = await getObraContext(
		{ locals },
		params.id,
		{
			requireEdit: false
		}
	);

	const [jornadasResp, secuenciasResp, vocabularios] = await Promise.all([
		locals.supabase.from('jornadas').select('*').eq('obra_id', obra.obra_id).order('v_ini'),
		locals.supabase
			.from('secuencias_metricas')
			.select('*')
			.eq('obra_id', obra.obra_id)
			.order('v_ini'),
		loadInternalVocabulario(locals.supabase, [
			'genero',
			'estado',
			'estrofa_tipo',
			'caracterizacion_rango',
			'personajes_donaire',
			'personajes_sobrenatural'
		])
	]);

	const jornadas = (jornadasResp.data ?? []) as Tables<'jornadas'>[];
	const jornadaIds = jornadas.map((jornada) => jornada.jornada_id);
	const cuadrosResp =
		jornadaIds.length > 0
			? await locals.supabase
					.from('cuadros')
					.select('*')
					.in('jornada_id', jornadaIds)
					.order('v_ini')
			: { data: [] };
	const cuadros = (cuadrosResp.data ?? []) as Tables<'cuadros'>[];
	const secuencias = (secuenciasResp.data ?? []) as Tables<'secuencias_metricas'>[];
	const autoriaNoAmbiguaCount = await countUnambiguousAutoriaGroups(locals.supabase, obra.obra_id);

	// Estado de los datos públicos precomputados (Fase 2 del plan de precomputación).
	// Si no hay fila, la obra nunca ha publicado datos (resumenExiste = false).
	const resumenResp = await locals.supabase
		.from('obras_resumen')
		.select('metrica_sucia,actualizado_en')
		.eq('obra_id', obra.obra_id)
		.maybeSingle();
	const resumenRow = resumenResp.data as Pick<
		Tables<'obras_resumen'>,
		'metrica_sucia' | 'actualizado_en'
	> | null;
	const resumenPublico = {
		existe: Boolean(resumenRow),
		metricaSucia: resumenRow?.metrica_sucia ?? false,
		actualizadoEn: resumenRow?.actualizado_en ?? null
	};

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
		resumenPublico,
		vocabularios
	};
};
