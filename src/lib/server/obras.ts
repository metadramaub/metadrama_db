import { error } from '@sveltejs/kit';
import type { SupabaseClient } from '@supabase/supabase-js';
import { countUnambiguousAutoriaGroups } from '$lib/server/autoria';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
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
	const estados = await loadInternalVocabulario(supabase, ['estado']);
	const estado = estados.find((item) => item.termino_id === estadoId);

	return (estado?.termino ?? 'borrador').trim().toLowerCase();
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
	const autoriaNoAmbiguaCount = await countUnambiguousAutoriaGroups(supabase, obra.obra_id);

	flags.estructura = (jornadasResp.count ?? 0) > 0;
	flags.secuencias = (secuenciasResp.count ?? 0) > 0;
	flags.autoria = autoriaNoAmbiguaCount > 0;

	const values = Object.values(flags);
	const completed = values.filter(Boolean).length;
	return Math.round((completed / values.length) * 100);
}
