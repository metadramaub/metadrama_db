import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';

export type PublicArtifact<T> = {
	payload: T;
	generatedAt: string;
	/** Cuándo cambió por última vez lo que dice. No se mueve al recalcular sin cambios. */
	contentChangedAt: string;
	stale: boolean;
	version: number;
};

const TABLE_NOT_READY_CODES = new Set(['42P01', 'PGRST205']);

/**
 * Lee un artefacto por su clave estable. Durante el despliegue inicial, si la tabla todavía no
 * existe, devuelve null para que la ruta pueda usar su productor anterior como compatibilidad.
 * Un artefacto marcado como sucio sí se sirve: es la última versión coherente mientras termina
 * la cola de actualización.
 */
export async function loadPublicArtifact<T>(
	supabase: SupabaseClient<Database>,
	key: string
): Promise<PublicArtifact<T> | null> {
	const { data, error } = await supabase
		.from('artefactos_publicos')
		.select('payload,generado_en,contenido_cambiado_en,sucio,version_esquema')
		.eq('clave', key)
		.maybeSingle();

	if (error) {
		if (TABLE_NOT_READY_CODES.has(error.code ?? '')) return null;
		throw error;
	}
	if (!data) return null;

	return {
		payload: data.payload as T,
		generatedAt: data.generado_en,
		contentChangedAt: data.contenido_cambiado_en,
		stale: data.sucio,
		version: data.version_esquema
	};
}

export const publicArtifactKeys = {
	obraFicha: (obraId: string) => `obras/${obraId}/ficha/publico.json`,
	obraAnalisis: (obraId: string) => `obras/${obraId}/analisis/publico.json`,
	obrasIndice: (scope: 'publico' | 'completo') => `indices/obras/${scope}.json`,
	autorFicha: (autorId: string, scope: 'publico' | 'completo') =>
		`autores/${autorId}/ficha/${scope}.json`,
	autoresIndice: (scope: 'publico' | 'completo') => `indices/autores/${scope}.json`,
	corpusComparativas: (scope: 'publico' | 'completo') => `corpus/comparativas/${scope}.json`
} as const;
