import type { SupabaseClient } from '@supabase/supabase-js';
import { countAutoriaGroupsWithProposals } from '$lib/server/autoria';
import type { Database, Tables } from '$lib/types/database.types';
import {
	buildRevisionChecklist,
	type RevisionChecklistSummary
} from '$lib/utils/revision-checklist';

type JornadaChecklistRow = Pick<
	Tables<'jornadas'>,
	'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'
>;
type CuadroChecklistRow = Pick<
	Tables<'cuadros'>,
	'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'
>;
type SecuenciaChecklistRow = Pick<
	Tables<'secuencias_metricas'>,
	| 'secuencia_id'
	| 'v_ini'
	| 'v_fin'
	| 'estrofa_tipo_id'
	| 'inaugura_espacio'
	| 'versos_partidos'
	| 'evocacion_metrica'
	| 'evocacion_metrica_texto'
	| 'intervencion_personajes_femeninos'
	| 'intervencion_figuras_donaire'
	| 'intervencion_personajes_sobrenaturales'
	| 'sinopsis'
>;

export async function loadObraRevisionChecklist(
	supabase: SupabaseClient<Database>,
	obra: Tables<'obras'>
): Promise<{ summary: RevisionChecklistSummary | null; errorMessage: string | null }> {
	const [jornadasResult, secuenciasResult] = await Promise.all([
		supabase
			.from('jornadas')
			.select('jornada_id,jornada_num,v_ini,v_fin')
			.eq('obra_id', obra.obra_id),
		supabase
			.from('secuencias_metricas')
			.select(
				'secuencia_id,v_ini,v_fin,estrofa_tipo_id,inaugura_espacio,versos_partidos,evocacion_metrica,evocacion_metrica_texto,intervencion_personajes_femeninos,intervencion_figuras_donaire,intervencion_personajes_sobrenaturales,sinopsis'
			)
			.eq('obra_id', obra.obra_id)
	]);

	const initialError = jornadasResult.error ?? secuenciasResult.error;
	if (initialError) {
		return { summary: null, errorMessage: initialError.message };
	}

	const jornadas = (jornadasResult.data ?? []) as JornadaChecklistRow[];
	const jornadaIds = jornadas.map((jornada) => jornada.jornada_id);
	const [cuadrosResult, autoriaGroupCount] = await Promise.all([
		jornadaIds.length > 0
			? supabase
					.from('cuadros')
					.select('cuadro_id,cuadro_num,jornada_id,v_ini,v_fin')
					.in('jornada_id', jornadaIds)
			: Promise.resolve({ data: [] as CuadroChecklistRow[], error: null }),
		countAutoriaGroupsWithProposals(supabase, obra.obra_id, jornadaIds)
	]);

	if (cuadrosResult.error) {
		return { summary: null, errorMessage: cuadrosResult.error.message };
	}

	return {
		summary: buildRevisionChecklist({
			obra,
			jornadas,
			cuadros: (cuadrosResult.data ?? []) as CuadroChecklistRow[],
			secuencias: (secuenciasResult.data ?? []) as SecuenciaChecklistRow[],
			autoriaGroupCount
		}),
		errorMessage: null
	};
}
