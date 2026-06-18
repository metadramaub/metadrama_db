// Acceso a datos de las secciones públicas (solo servidor).
// La regla de visibilidad vive en $lib/secciones-publicas.ts (compartida).

import type { PublicSection, SectionScope } from '$lib/secciones-publicas';

// Las 10 filas de secciones_publicas cambian casi nunca (solo cuando el admin usa
// el panel). Cachearlas en memoria del servidor con un TTL corto evita una query
// por cada visita pública. El panel admin debe llamar a invalidatePublicSectionsCache()
// tras escribir para que el cambio se refleje al instante.
const SECTIONS_CACHE_TTL_MS = 60_000;
let sectionsCache: { value: PublicSection[]; expiresAt: number } | null = null;

export function invalidatePublicSectionsCache(): void {
	sectionsCache = null;
}

/**
 * Carga todas las secciones públicas ordenadas, cacheadas en memoria (TTL corto).
 * Si falla la consulta, devuelve [] (la web sigue funcionando con todo oculto por
 * defecto, que es el lado seguro) y NO cachea el fallo.
 */
export async function loadPublicSections(locals: App.Locals): Promise<PublicSection[]> {
	const now = Date.now();
	if (sectionsCache && sectionsCache.expiresAt > now) {
		return sectionsCache.value;
	}

	const { data, error } = await locals.supabase
		.from('secciones_publicas')
		.select('seccion_id,label,descripcion,activa,scope_minimo,orden')
		.order('orden');

	if (error || !data) {
		return [];
	}

	const value = data.map((row) => ({
		seccion_id: row.seccion_id,
		label: row.label,
		descripcion: row.descripcion,
		activa: row.activa,
		scope_minimo: (row.scope_minimo as SectionScope) ?? 'admin_ip',
		orden: row.orden
	}));

	sectionsCache = { value, expiresAt: now + SECTIONS_CACHE_TTL_MS };
	return value;
}
