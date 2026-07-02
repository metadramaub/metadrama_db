import { error } from '@sveltejs/kit';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { AuthorWorkSummary } from '$lib/types/author.types';
import type { Database, Tables } from '$lib/types/database.types';

type AuthorIdentityFields = Pick<
	Tables<'autores'>,
	'autor_id' | 'nombre_completo' | 'nombre_normalizado' | 'variantes_nombre'
>;

export interface SimilarAuthorCandidate {
	autor_id: string;
	nombre_completo: string;
	nombre_normalizado: string;
	matched_value: string;
	reason: 'exact' | 'contains' | 'tokens' | 'distance';
	score: number;
}

function uniqueByNormalizedText(items: string[]): string[] {
	const seen = new Set<string>();
	const output: string[] = [];
	for (const item of items) {
		const trimmed = item.trim();
		if (!trimmed) continue;
		const key = normalizeAuthorSearchTerm(trimmed);
		if (!key || seen.has(key)) continue;
		seen.add(key);
		output.push(trimmed);
	}
	return output;
}

export function normalizeAuthorSearchTerm(name: string): string {
	return name
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.trim()
		.toLowerCase()
		.replaceAll(/\s+/g, ' ');
}

export function normalizeAuthorSortName(name: string): string {
	return name.trim();
}

function toDirectNameFromInvertedOrder(name: string): string | null {
	const parts = name
		.split(',')
		.map((part) => part.trim())
		.filter(Boolean);
	if (parts.length < 2) return null;
	const [surname, ...givenNameParts] = parts;
	return `${givenNameParts.join(' ')} ${surname}`.trim();
}

function buildAuthorNameValues(
	author: Pick<Tables<'autores'>, 'nombre_completo' | 'nombre_normalizado' | 'variantes_nombre'>
): string[] {
	const values = [
		author.nombre_completo,
		author.nombre_normalizado,
		...(author.variantes_nombre ?? [])
	].filter((value): value is string => typeof value === 'string' && value.trim().length > 0);

	const expandedValues = values.flatMap((value) => {
		const directName = toDirectNameFromInvertedOrder(value);
		return directName ? [value, directName] : [value];
	});

	return uniqueByNormalizedText(expandedValues);
}

export function buildAuthorSearchValues(
	author: Pick<
		Tables<'autores'>,
		| 'nombre_completo'
		| 'nombre_normalizado'
		| 'variantes_nombre'
		| 'bnedatos_id'
		| 'viaf_id'
		| 'wikidata_id'
	>
): string[] {
	const values = [
		...buildAuthorNameValues(author),
		author.bnedatos_id,
		author.viaf_id,
		author.wikidata_id
	].filter((value): value is string => typeof value === 'string' && value.trim().length > 0);

	return uniqueByNormalizedText(values);
}

export function matchesAuthorSearch(
	author: Pick<
		Tables<'autores'>,
		| 'nombre_completo'
		| 'nombre_normalizado'
		| 'variantes_nombre'
		| 'bnedatos_id'
		| 'viaf_id'
		| 'wikidata_id'
	>,
	searchTerm: string
): boolean {
	const normalizedTerm = normalizeAuthorSearchTerm(searchTerm);
	if (!normalizedTerm) return true;
	return buildAuthorSearchValues(author).some((value) =>
		normalizeAuthorSearchTerm(value).includes(normalizedTerm)
	);
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

function normalizedTokens(value: string): Set<string> {
	return new Set(
		normalizeAuthorSearchTerm(value)
			.split(' ')
			.map((token) => token.trim())
			.filter((token) => token.length > 1)
	);
}

function tokenOverlapScore(left: string, right: string): number {
	const leftTokens = normalizedTokens(left);
	const rightTokens = normalizedTokens(right);
	if (leftTokens.size < 2 || rightTokens.size < 2) return 0;
	let shared = 0;
	for (const token of leftTokens) {
		if (rightTokens.has(token)) shared += 1;
	}
	return shared / Math.min(leftTokens.size, rightTokens.size);
}

function levenshteinDistance(left: string, right: string): number {
	if (left === right) return 0;
	if (left.length === 0) return right.length;
	if (right.length === 0) return left.length;

	const previous = Array.from({ length: right.length + 1 }, (_, index) => index);
	const current = Array.from({ length: right.length + 1 }, () => 0);

	for (let i = 1; i <= left.length; i += 1) {
		current[0] = i;
		for (let j = 1; j <= right.length; j += 1) {
			const cost = left[i - 1] === right[j - 1] ? 0 : 1;
			current[j] = Math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost);
		}
		for (let j = 0; j <= right.length; j += 1) {
			previous[j] = current[j];
		}
	}

	return previous[right.length];
}

function compareAuthorValues(
	newValue: string,
	existingValue: string
): Pick<SimilarAuthorCandidate, 'reason' | 'score'> | null {
	const left = normalizeAuthorSearchTerm(newValue);
	const right = normalizeAuthorSearchTerm(existingValue);
	if (!left || !right) return null;
	if (left === right) return { reason: 'exact', score: 100 };

	const shorter = left.length <= right.length ? left : right;
	const longer = left.length > right.length ? left : right;
	if (shorter.length >= 6 && longer.includes(shorter) && shorter.length / longer.length >= 0.55) {
		return { reason: 'contains', score: 86 };
	}

	const overlap = tokenOverlapScore(left, right);
	if (overlap >= 0.67) {
		return { reason: 'tokens', score: Math.round(70 + overlap * 15) };
	}

	const maxLength = Math.max(left.length, right.length);
	if (maxLength >= 8) {
		const distanceRatio = levenshteinDistance(left, right) / maxLength;
		if (distanceRatio <= 0.18) {
			return { reason: 'distance', score: Math.round(70 + (0.18 - distanceRatio) * 70) };
		}
	}

	return null;
}

export function findSimilarAuthors(
	draft: Pick<Tables<'autores'>, 'nombre_completo' | 'nombre_normalizado' | 'variantes_nombre'>,
	existingAuthors: AuthorIdentityFields[],
	limit = 5
): SimilarAuthorCandidate[] {
	const draftValues = buildAuthorNameValues(draft);
	const candidates = new Map<string, SimilarAuthorCandidate>();

	for (const author of existingAuthors) {
		const existingValues = buildAuthorNameValues(author);
		for (const draftValue of draftValues) {
			for (const existingValue of existingValues) {
				const match = compareAuthorValues(draftValue, existingValue);
				if (!match) continue;

				const current = candidates.get(author.autor_id);
				if (!current || match.score > current.score) {
					candidates.set(author.autor_id, {
						autor_id: author.autor_id,
						nombre_completo: author.nombre_completo,
						nombre_normalizado: author.nombre_normalizado ?? '',
						matched_value: existingValue,
						reason: match.reason,
						score: match.score
					});
				}
			}
		}
	}

	return [...candidates.values()]
		.sort(
			(left, right) =>
				right.score - left.score ||
				left.nombre_normalizado.localeCompare(right.nombre_normalizado, 'es')
		)
		.slice(0, limit);
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
