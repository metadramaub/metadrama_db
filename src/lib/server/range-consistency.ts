import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, Tables } from '$lib/types/database.types';
import {
	analyzeSequenceRangeConsistency,
	analyzeStructureRangeConsistency,
	type RangeConsistencyIssue
} from '$lib/utils/range-consistency';

type JornadaRange = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type CuadroRange = Pick<
	Tables<'cuadros'>,
	'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'
>;
type SecuenciaRange = Pick<
	Tables<'secuencias_metricas'>,
	'secuencia_id' | 'v_ini' | 'v_fin'
>;

export async function loadObraRangeConsistency(
	supabase: SupabaseClient<Database>,
	obraId: string
): Promise<{ issues: RangeConsistencyIssue[]; errorMessage: string | null }> {
	const [jornadasResult, secuenciasResult] = await Promise.all([
		supabase
			.from('jornadas')
			.select('jornada_id,jornada_num,v_ini,v_fin')
			.eq('obra_id', obraId),
		supabase
			.from('secuencias_metricas')
			.select('secuencia_id,v_ini,v_fin')
			.eq('obra_id', obraId)
	]);

	const initialError = jornadasResult.error ?? secuenciasResult.error;
	if (initialError) {
		return { issues: [], errorMessage: initialError.message };
	}

	const jornadas = (jornadasResult.data ?? []) as JornadaRange[];
	const jornadaIds = jornadas.map((jornada) => jornada.jornada_id);
	let cuadros: CuadroRange[] = [];

	if (jornadaIds.length > 0) {
		const cuadrosResult = await supabase
			.from('cuadros')
			.select('cuadro_id,cuadro_num,jornada_id,v_ini,v_fin')
			.in('jornada_id', jornadaIds);
		if (cuadrosResult.error) {
			return { issues: [], errorMessage: cuadrosResult.error.message };
		}
		cuadros = (cuadrosResult.data ?? []) as CuadroRange[];
	}

	return {
		issues: [
			...analyzeStructureRangeConsistency(jornadas, cuadros),
			...analyzeSequenceRangeConsistency(
				(secuenciasResult.data ?? []) as SecuenciaRange[]
			)
		],
		errorMessage: null
	};
}
