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

type AuthorAttributionEdge = Pick<Tables<'atribucion_autores'>, 'autor_id' | 'atribucion_id'>;
type AttributionRow = Pick<Tables<'atribuciones'>, 'atribucion_id' | 'grupo_atribucion_id'>;
type AttributionGroupRow = Pick<Tables<'grupos_atribucion'>, 'grupo_atribucion_id' | 'obra_id'>;

async function resolveAuthorWorkIds(
	supabase: SupabaseClient<Database>,
	authorIds: string[]
): Promise<{ perAuthor: Map<string, Set<string>>; errorMessage: string | null }> {
	if (authorIds.length === 0) {
		return { perAuthor: new Map(), errorMessage: null };
	}

	const edgesResp = await supabase
		.from('atribucion_autores')
		.select('autor_id,atribucion_id')
		.in('autor_id', authorIds);
	if (edgesResp.error) {
		return { perAuthor: new Map(), errorMessage: edgesResp.error.message };
	}
	const edges = (edgesResp.data ?? []) as AuthorAttributionEdge[];
	if (edges.length === 0) {
		return { perAuthor: new Map(), errorMessage: null };
	}

	const atribucionIds = [...new Set(edges.map((edge) => edge.atribucion_id))];
	const atribucionesResp = await supabase
		.from('atribuciones')
		.select('atribucion_id,grupo_atribucion_id')
		.in('atribucion_id', atribucionIds);
	if (atribucionesResp.error) {
		return { perAuthor: new Map(), errorMessage: atribucionesResp.error.message };
	}
	const atribuciones = (atribucionesResp.data ?? []) as AttributionRow[];
	if (atribuciones.length === 0) {
		return { perAuthor: new Map(), errorMessage: null };
	}

	const grupoIds = [
		...new Set(
			atribuciones
				.map((row) => row.grupo_atribucion_id)
				.filter((id): id is string => typeof id === 'string' && id.length > 0)
		)
	];

	let groupById = new Map<string, AttributionGroupRow>();
	let attributionCountByGroup = new Map<string, number>();
	if (grupoIds.length > 0) {
		const [groupsResp, groupAttributionsResp] = await Promise.all([
			supabase.from('grupos_atribucion').select('grupo_atribucion_id,obra_id').in('grupo_atribucion_id', grupoIds),
			supabase.from('atribuciones').select('atribucion_id,grupo_atribucion_id').in('grupo_atribucion_id', grupoIds)
		]);
		if (groupsResp.error) {
			return { perAuthor: new Map(), errorMessage: groupsResp.error.message };
		}
		if (groupAttributionsResp.error) {
			return { perAuthor: new Map(), errorMessage: groupAttributionsResp.error.message };
		}
		groupById = new Map(
			((groupsResp.data ?? []) as AttributionGroupRow[]).map((row) => [row.grupo_atribucion_id, row])
		);
		attributionCountByGroup = new Map();
		for (const row of (groupAttributionsResp.data ?? []) as AttributionRow[]) {
			if (!row.grupo_atribucion_id) continue;
			attributionCountByGroup.set(row.grupo_atribucion_id, (attributionCountByGroup.get(row.grupo_atribucion_id) ?? 0) + 1);
		}
	}

	const atribucionById = new Map(atribuciones.map((row) => [row.atribucion_id, row]));
	const perAuthor = new Map<string, Set<string>>();
	for (const edge of edges) {
		const atribucion = atribucionById.get(edge.atribucion_id);
		if (!atribucion) continue;
		const groupId = atribucion.grupo_atribucion_id;
		if (!groupId || attributionCountByGroup.get(groupId) !== 1) continue;
		const obraId = groupById.get(groupId)?.obra_id ?? null;
		if (!obraId) continue;
		const current = perAuthor.get(edge.autor_id) ?? new Set<string>();
		current.add(obraId);
		perAuthor.set(edge.autor_id, current);
	}

	return { perAuthor, errorMessage: null };
}

export async function getAuthorWorks(
	supabase: SupabaseClient<Database>,
	authorId: string
): Promise<{ items: AuthorWorkSummary[]; count: number; errorMessage: string | null }> {
	const resolved = await resolveAuthorWorkIds(supabase, [authorId]);
	if (resolved.errorMessage) {
		return { items: [], count: 0, errorMessage: resolved.errorMessage };
	}

	const obraIds = [...(resolved.perAuthor.get(authorId) ?? new Set<string>())];
	if (obraIds.length === 0) {
		return { items: [], count: 0, errorMessage: null };
	}

	const obrasResp = await supabase
		.from('obras')
		.select('obra_id,titulo,updated_at')
		.in('obra_id', obraIds)
		.order('updated_at', { ascending: false });
	if (obrasResp.error) {
		return { items: [], count: 0, errorMessage: obrasResp.error.message };
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

	const resolved = await resolveAuthorWorkIds(supabase, authorIds);
	if (resolved.errorMessage) {
		return { counts: new Map(), errorMessage: resolved.errorMessage };
	}

	const counts = new Map<string, number>();
	for (const authorId of authorIds) {
		counts.set(authorId, resolved.perAuthor.get(authorId)?.size ?? 0);
	}
	return { counts, errorMessage: null };
}
