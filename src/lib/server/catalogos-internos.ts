import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, Tables } from '$lib/types/database.types';

export type InternalVocabularioTerm = Pick<
	Tables<'vocabularios'>,
	'termino_id' | 'categoria' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden' | 'tipo_forma'
>;

const INTERNAL_CATALOG_CACHE_TTL_MS = 60_000;

const vocabularioByCategoryCache = new Map<
	string,
	{ value: InternalVocabularioTerm[]; expiresAt: number }
>();
const vocabularioByIdCache = new Map<string, { value: InternalVocabularioTerm | null; expiresAt: number }>();

function normalizeCategories(categorias: readonly string[]): string[] {
	return [...new Set(categorias.map((categoria) => categoria.trim()).filter(Boolean))].sort();
}

function categoryCacheKey(categorias: readonly string[]): string {
	return normalizeCategories(categorias).join('|');
}

export function invalidateInternalCatalogCache(): void {
	vocabularioByCategoryCache.clear();
	vocabularioByIdCache.clear();
}

export async function loadInternalVocabulario(
	supabase: SupabaseClient<Database>,
	categorias: readonly string[]
): Promise<InternalVocabularioTerm[]> {
	const normalized = normalizeCategories(categorias);
	if (normalized.length === 0) {
		return [];
	}

	const key = categoryCacheKey(normalized);
	const now = Date.now();
	const cached = vocabularioByCategoryCache.get(key);
	if (cached && cached.expiresAt > now) {
		return cached.value;
	}

	const { data, error } = await supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,etiqueta,termino_padre_id,orden,tipo_forma')
		.eq('activo', true)
		.in('categoria', normalized)
		.order('categoria')
		.order('orden', { ascending: true });

	if (error || !data) {
		return [];
	}

	const value = data as InternalVocabularioTerm[];
	vocabularioByCategoryCache.set(key, { value, expiresAt: now + INTERNAL_CATALOG_CACHE_TTL_MS });
	return value;
}

export async function loadInternalVocabularioTermById(
	supabase: SupabaseClient<Database>,
	terminoId: string
): Promise<InternalVocabularioTerm | null> {
	const key = terminoId.trim();
	if (!key) {
		return null;
	}

	const now = Date.now();
	const cached = vocabularioByIdCache.get(key);
	if (cached && cached.expiresAt > now) {
		return cached.value;
	}

	const { data, error } = await supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,etiqueta,termino_padre_id,orden,tipo_forma')
		.eq('termino_id', key)
		.maybeSingle();

	if (error) {
		return null;
	}

	const value = (data ?? null) as InternalVocabularioTerm | null;
	vocabularioByIdCache.set(key, { value, expiresAt: now + INTERNAL_CATALOG_CACHE_TTL_MS });
	return value;
}
