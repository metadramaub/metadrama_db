import { error } from '@sveltejs/kit';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, Tables } from '$lib/types/database.types';

type Rango = Pick<
	Tables<'jornadas'> | Tables<'cuadros'> | Tables<'secuencias_metricas'>,
	'v_ini' | 'v_fin'
>;

export function hasOverlap(ranges: Rango[], input: Rango, excludeBy?: Rango): boolean {
	return ranges.some((current) => {
		if (excludeBy && current.v_ini === excludeBy.v_ini && current.v_fin === excludeBy.v_fin) {
			return false;
		}
		return input.v_ini <= current.v_fin && input.v_fin >= current.v_ini;
	});
}

export async function getEstadoTerm(
	supabase: SupabaseClient<Database>,
	estadoId: string
): Promise<string> {
	const { data } = await supabase
		.from('vocabularios')
		.select('termino')
		.eq('termino_id', estadoId)
		.eq('categoria', 'estado')
		.single();

	return (data?.termino ?? 'borrador').trim().toLowerCase();
}

export async function getObraOrFail(
	supabase: SupabaseClient<Database>,
	obraId: string
): Promise<Tables<'obras'>> {
	const { data, error: obraError } = await supabase
		.from('obras')
		.select('*')
		.eq('obra_id', obraId)
		.single();
	const obra = (data ?? null) as Tables<'obras'> | null;
	if (obraError || !obra) {
		throw error(404, 'Obra no encontrada');
	}
	return obra;
}

export async function computeObraProgress(
	supabase: SupabaseClient<Database>,
	obra: Tables<'obras'>
) {
	const flags = {
		datos: Boolean(obra.titulo?.trim() && obra.genero_id && obra.edicion?.trim()),
		estructura: false,
		secuencias: false,
		autoria: false,
		observaciones: Boolean((obra.observaciones ?? '').trim().length > 100),
		bibliografia: Boolean((obra.bibliografia ?? '').trim().length > 0)
	};

	const jornadasResp = await supabase
		.from('jornadas')
		.select('jornada_id', { count: 'exact', head: true })
		.eq('obra_id', obra.obra_id);
	const secuenciasResp = await supabase
		.from('secuencias_metricas')
		.select('secuencia_id', { count: 'exact', head: true })
		.eq('obra_id', obra.obra_id);
	const jornadasRowsResp = await supabase
		.from('jornadas')
		.select('jornada_id')
		.eq('obra_id', obra.obra_id);
	const jornadaIds = [...new Set((jornadasRowsResp.data ?? []).map((row) => row.jornada_id))];

	const [adoptadaObraResp, adoptadaJornadaResp] = await Promise.all([
		supabase
			.from('atribuciones')
			.select('atribucion_id', { count: 'exact', head: true })
			.eq('obra_id', obra.obra_id)
			.eq('adoptada', true),
		supabase
			.from('atribuciones')
			.select('atribucion_id', { count: 'exact', head: true })
			.eq('adoptada', true)
			.in('jornada_id', jornadaIds.length > 0 ? jornadaIds : ['00000000-0000-0000-0000-000000000000'])
	]);

	flags.estructura = (jornadasResp.count ?? 0) > 0;
	flags.secuencias = (secuenciasResp.count ?? 0) > 0;
	flags.autoria = (adoptadaObraResp.count ?? 0) + (adoptadaJornadaResp.count ?? 0) > 0;

	const values = Object.values(flags);
	const completed = values.filter(Boolean).length;
	return Math.round((completed / values.length) * 100);
}
