// Acceso a datos de las secciones públicas (solo servidor).
// La regla de visibilidad vive en $lib/secciones-publicas.ts (compartida).

import { error } from '@sveltejs/kit';
import { isSectionAvailable, type PublicSection, type SectionScope } from '$lib/secciones-publicas';
import { resolvePublicViewerContext } from '$lib/server/public-obras';

// Las filas de secciones_publicas cambian casi nunca (solo cuando el admin usa
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

/**
 * Guard de página pública: lanza 404 si la sección no es visible para el visitante
 * (apagada o scope insuficiente). Pensado para llamarse al inicio del `load` de las
 * páginas que corresponden a una sección (catalogo, autores, laboratorio, demarcador).
 *
 * Lanza 404 (no 403) a propósito: una página oculta no debe delatar su existencia.
 */
export async function requireSectionVisible(
	locals: App.Locals,
	seccionId: string
): Promise<void> {
	const [viewer, sections] = await Promise.all([
		resolvePublicViewerContext(locals),
		loadPublicSections(locals)
	]);
	const section = sections.find((s) => s.seccion_id === seccionId);
	// Sección desconocida o no disponible = oculta (default seguro).
	if (!section || !isSectionAvailable(section, viewer.scope)) {
		throw error(404, 'Página no encontrada.');
	}
}
