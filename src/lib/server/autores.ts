import { error } from '@sveltejs/kit';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { AuthorWorkSummary } from '$lib/types/author.types';
import type { Database, Tables } from '$lib/types/database.types';

function uniqueByNormalizedText(items: string[]): string[] {
	const seen = new Set<string>();
	const output: string[] = [];
	for (const item of items) {
		const trimmed = item.trim();
		if (!trimmed) continue;
		const key = normalizeAuthorName(trimmed);
		if (!key || seen.has(key)) continue;
		seen.add(key);
		output.push(trimmed);
	}
	return output;
}

export function normalizeAuthorName(name: string): string {
	return name.normalize('NFD').replaceAll(/\p{M}/gu, '').trim().toLowerCase();
}

export function normalizeExternalAuthorId(value: string | null | undefined): string | null {
	if (typeof value !== 'string') return null;
	const trimmed = value.trim();
	return trimmed.length > 0 ? trimmed : null;
}

export function normalizeAuthorVariants(items: string[] | null | undefined): string[] | null {
	if (!Array.isArray(items)) return null;
	const normalized = uniqueByNormalizedText(items);
	return normalized.length > 0 ? normalized : null;
}

export async function getAuthorOrFail(
	supabase: SupabaseClient<Database>,
	authorId: string
): Promise<Tables<'autores'>> {
	const { data, error: dbError } = await supabase
		.from('autores')
		.select('*')
		.eq('autor_id', authorId)
		.maybeSingle();
	if (dbError) {
		throw error(500, `No se pudo cargar el autor: ${dbError.message}`);
	}
	if (!data) {
		throw error(404, 'Autor no encontrado.');
	}
	return data as Tables<'autores'>;
}

export async function getAuthorWorks(
	supabase: SupabaseClient<Database>,
	authorId: string
): Promise<{ items: AuthorWorkSummary[]; count: number; errorMessage: string | null }> {
	const rangosAutoresResp = await supabase
		.from('rangos_autores')
		.select('rango_id')
		.eq('autor_id', authorId);

	if (rangosAutoresResp.error) {
		return {
			items: [],
			count: 0,
			errorMessage: rangosAutoresResp.error.message
		};
	}

	const rangoIds = [...new Set((rangosAutoresResp.data ?? []).map((row) => row.rango_id))];
	if (rangoIds.length === 0) {
		return { items: [], count: 0, errorMessage: null };
	}

	const rangosResp = await supabase.from('rangos').select('rango_id,obra_id').in('rango_id', rangoIds);
	if (rangosResp.error) {
		return {
			items: [],
			count: 0,
			errorMessage: rangosResp.error.message
		};
	}

	const obraIds = [...new Set((rangosResp.data ?? []).map((row) => row.obra_id))];
	if (obraIds.length === 0) {
		return { items: [], count: 0, errorMessage: null };
	}

	const obrasResp = await supabase
		.from('obras')
		.select('obra_id,titulo,updated_at')
		.in('obra_id', obraIds)
		.order('updated_at', { ascending: false });
	if (obrasResp.error) {
		return {
			items: [],
			count: 0,
			errorMessage: obrasResp.error.message
		};
	}

	const worksById = new Map<string, AuthorWorkSummary>();
	for (const obra of obrasResp.data ?? []) {
		if (!worksById.has(obra.obra_id)) {
			worksById.set(obra.obra_id, {
				obra_id: obra.obra_id,
				titulo: obra.titulo,
				updated_at: obra.updated_at
			});
		}
	}

	const items = [...worksById.values()];
	return {
		items,
		count: items.length,
		errorMessage: null
	};
}

export async function getAuthorWorksCountMap(
	supabase: SupabaseClient<Database>,
	authorIds: string[]
): Promise<{ counts: Map<string, number>; errorMessage: string | null }> {
	if (authorIds.length === 0) {
		return { counts: new Map(), errorMessage: null };
	}

	const rangosAutoresResp = await supabase
		.from('rangos_autores')
		.select('autor_id,rango_id')
		.in('autor_id', authorIds);
	if (rangosAutoresResp.error) {
		return { counts: new Map(), errorMessage: rangosAutoresResp.error.message };
	}

	const rangeRows = rangosAutoresResp.data ?? [];
	const rangeIds = [...new Set(rangeRows.map((row) => row.rango_id))];
	if (rangeIds.length === 0) {
		return { counts: new Map(), errorMessage: null };
	}

	const rangosResp = await supabase.from('rangos').select('rango_id,obra_id').in('rango_id', rangeIds);
	if (rangosResp.error) {
		return { counts: new Map(), errorMessage: rangosResp.error.message };
	}

	const obraIds = [...new Set((rangosResp.data ?? []).map((row) => row.obra_id))];
	if (obraIds.length === 0) {
		return { counts: new Map(), errorMessage: null };
	}

	const obrasResp = await supabase.from('obras').select('obra_id').in('obra_id', obraIds);
	if (obrasResp.error) {
		return { counts: new Map(), errorMessage: obrasResp.error.message };
	}

	const allowedObraIds = new Set((obrasResp.data ?? []).map((row) => row.obra_id));
	const rangeToObra = new Map((rangosResp.data ?? []).map((row) => [row.rango_id, row.obra_id]));
	const perAuthorWorks = new Map<string, Set<string>>();

	for (const row of rangeRows) {
		const obraId = rangeToObra.get(row.rango_id);
		if (!obraId || !allowedObraIds.has(obraId)) continue;
		const current = perAuthorWorks.get(row.autor_id) ?? new Set<string>();
		current.add(obraId);
		perAuthorWorks.set(row.autor_id, current);
	}

	const counts = new Map<string, number>();
	for (const authorId of authorIds) {
		counts.set(authorId, perAuthorWorks.get(authorId)?.size ?? 0);
	}

	return { counts, errorMessage: null };
}
