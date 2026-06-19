// Acceso cacheado al vocabulario para superficies públicas (catálogo, ficha, autor…).
//
// Estrategia de etiquetas: las tablas precomputadas (obras_resumen, etc.) guardan
// SLUGS (`termino`, clave estable), nunca `etiqueta` (editable → se quedaría obsoleta
// al renombrar). La etiqueta visible se resuelve en LECTURA desde el vocabulario.
// Para no repetir una consulta por superficie/desplegable, el vocabulario relevante
// se carga UNA vez y se cachea en memoria del servidor (TTL corto), igual que
// loadPublicSections. Tras editar vocabularios, llamar a
// invalidatePublicVocabularioCache() para reflejar el cambio al instante.

import { displayTerm } from '$lib/utils/vocabulario';

/** Categorías de vocabulario que consumen las superficies públicas. */
export const PUBLIC_VOCAB_CATEGORIES = [
	'genero',
	'estrofa_tipo',
	'metro',
	'caracterizacion_rango'
] as const;

export type PublicVocabularioTerm = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	categoria: string;
	termino_padre_id: string | null;
	nivel: number | null;
	tipo_forma: string | null;
	orden: number | null;
};

const VOCAB_CACHE_TTL_MS = 60_000;
let vocabCache: { value: PublicVocabularioTerm[]; expiresAt: number } | null = null;

export function invalidatePublicVocabularioCache(): void {
	vocabCache = null;
}

/**
 * Vocabulario público (categorías de PUBLIC_VOCAB_CATEGORIES), cacheado en memoria.
 * Si la consulta falla, devuelve [] sin cachear el fallo.
 */
export async function loadPublicVocabulario(
	locals: App.Locals
): Promise<PublicVocabularioTerm[]> {
	const now = Date.now();
	if (vocabCache && vocabCache.expiresAt > now) {
		return vocabCache.value;
	}

	const { data, error } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,termino,etiqueta,categoria,termino_padre_id,nivel,tipo_forma,orden')
		.in('categoria', [...PUBLIC_VOCAB_CATEGORIES]);

	if (error || !data) {
		return [];
	}

	const value = data as PublicVocabularioTerm[];
	vocabCache = { value, expiresAt: now + VOCAB_CACHE_TTL_MS };
	return value;
}

export type PublicVocabularioMaps = {
	/** termino_id → etiqueta visible (p. ej. para resolver obras.genero_id). */
	labelByTerminoId: Map<string, string>;
	/** categoria → (slug `termino` → etiqueta visible). */
	labelBySlug: Map<string, Map<string, string>>;
	/** categoria → (slug hijo → slug del padre), para reconstruir la jerarquía. */
	parentSlugBySlug: Map<string, Map<string, string>>;
};

/**
 * Construye los mapas de resolución desde los términos cargados. Pensado para
 * resolver etiquetas (slug → etiqueta) y jerarquía (slug → slug padre) sin más
 * consultas, reutilizable por cualquier superficie pública.
 */
export function buildPublicVocabularioMaps(terms: PublicVocabularioTerm[]): PublicVocabularioMaps {
	const labelByTerminoId = new Map<string, string>();
	const labelBySlug = new Map<string, Map<string, string>>();
	const slugByTerminoId = new Map<string, string>();

	for (const term of terms) {
		const label = displayTerm(term);
		labelByTerminoId.set(term.termino_id, label);
		slugByTerminoId.set(term.termino_id, term.termino);
		const byCat = labelBySlug.get(term.categoria) ?? new Map<string, string>();
		byCat.set(term.termino, label);
		labelBySlug.set(term.categoria, byCat);
	}

	const parentSlugBySlug = new Map<string, Map<string, string>>();
	for (const term of terms) {
		if (!term.termino_padre_id) continue;
		const parentSlug = slugByTerminoId.get(term.termino_padre_id);
		if (!parentSlug) continue;
		const byCat = parentSlugBySlug.get(term.categoria) ?? new Map<string, string>();
		byCat.set(term.termino, parentSlug);
		parentSlugBySlug.set(term.categoria, byCat);
	}

	return { labelByTerminoId, labelBySlug, parentSlugBySlug };
}
