// Lógica compartida (servidor + cliente) de visibilidad de secciones públicas.
// Los datos se cargan en el servidor (ver $lib/server/secciones-publicas.ts);
// aquí solo vive la regla de "¿se ve esta sección?", para no duplicarla.
//
// Relación con el resto del sistema:
//  - El muro `estado = publicado` y la atenuación por obra (visible_publico /
//    editor asignado) NO se deciden aquí: ver $lib/server/public-obras.ts.
//  - Esto solo decide, dentro de lo ya accesible, qué secciones mostrar.

import type { PublicViewerScope } from '$lib/server/public-obras';

export type SectionScope = PublicViewerScope; // 'anon' | 'authenticated' | 'admin_ip'

export interface PublicSection {
	seccion_id: string;
	label: string;
	descripcion: string | null;
	activa: boolean;
	scope_minimo: SectionScope;
	orden: number;
}

/** Mapa resuelto que baja al cliente: seccion_id -> ¿visible para este visitante? */
export type SectionVisibilityMap = Record<string, boolean>;

/** Slugs de las sub-secciones de ficha (deben existir en secciones_publicas). */
export const FICHA_SECTION_IDS = {
	autoria: 'ficha.autoria',
	fuentes: 'ficha.autoria.fuentes',
	metrica: 'ficha.metrica',
	sinopsisMetrica: 'ficha.sinopsis_metrica',
	observaciones: 'ficha.observaciones',
	bibliografia: 'ficha.bibliografia',
	comentarios: 'ficha.comentarios_publicos'
} as const;

/** Slugs de bloques internos del catálogo público. */
export const CATALOG_SECTION_IDS = {
	filtrosBasicos: 'catalogo.filtros.basicos',
	filtrosDatacionExtension: 'catalogo.filtros.datacion_extension',
	filtrosMetrica: 'catalogo.filtros.metrica',
	filtrosDramaturgia: 'catalogo.filtros.dramaturgia',
	resultadosPerfilMetrico: 'catalogo.resultados.perfil_metrico',
	laboratorio: 'catalogo.laboratorio'
} as const;

// Orden de menor a mayor privilegio. Una sección es visible si el scope del
// visitante alcanza al menos su scope_minimo.
const SCOPE_RANK: Record<SectionScope, number> = {
	anon: 0,
	authenticated: 1,
	admin_ip: 2
};

/** ¿El scope del visitante alcanza el mínimo exigido por la sección? */
export function scopeMeets(viewerScope: SectionScope, required: SectionScope): boolean {
	return SCOPE_RANK[viewerScope] >= SCOPE_RANK[required];
}

/** Regla única de visibilidad: activa Y el scope alcanza el mínimo. */
export function isSectionAvailable(section: PublicSection, viewerScope: SectionScope): boolean {
	return section.activa && scopeMeets(viewerScope, section.scope_minimo);
}

/**
 * Resuelve la lista de secciones contra un scope concreto y devuelve el mapa
 * plano que se serializa al cliente. Falta de una sección en el mapa = no visible.
 */
export function buildSectionVisibilityMap(
	sections: PublicSection[],
	viewerScope: SectionScope
): SectionVisibilityMap {
	const map: SectionVisibilityMap = {};
	for (const section of sections) {
		map[section.seccion_id] = isSectionAvailable(section, viewerScope);
	}
	return map;
}

/**
 * Consulta el mapa resuelto. Default seguro: una sección desconocida se trata
 * como NO visible (mejor ocultar de más que filtrar de menos).
 */
export function isSectionVisible(map: SectionVisibilityMap, seccionId: string): boolean {
	return map[seccionId] === true;
}
