// Tipos y helpers de la zona pública de autores (Fase 6).
// Metodología: docs/metodologia-perfil-metrico.md §2-§3.

import type { CatalogStructureTramo, CatalogTramo } from '$lib/catalogo/catalog-filters';
import { colorForForma } from '$lib/utils/metric-colors';

// --- Payload de get_autor_publico ---

export type AutorPublicoVinculo = {
	scope: 'obra' | 'jornada';
	jornada_num: number | null;
	composicion_term: string;
	perfil_metrico: boolean;
	unica_propuesta: boolean;
};

export type AutorPublicoObra = {
	obra_id: string;
	slug: string;
	titulo: string;
	genero_term: string | null;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	total_versos: number | null;
	visible_publico: boolean;
	tramos: CatalogTramo[];
	jornadas_tramos: CatalogStructureTramo[];
	cuadros_tramos: CatalogStructureTramo[];
	numero_efectivo_formas: number | null;
	densidad_transiciones: number | null;
	n_formas_distintas: number | null;
	sostiene_perfil: boolean;
	vinculos: AutorPublicoVinculo[];
};

export type AutorPublicoIdentidad = {
	autor_id: string;
	slug: string;
	nombre_completo: string;
	variantes_nombre: string[];
	viaf_id: string | null;
	wikidata_id: string | null;
	bnedatos_id: string | null;
};

export type AutorWikidataData = {
	image: {
		url: string;
		commonsFile: string;
		sourceUrl: string;
	} | null;
	birthDateLabel: string | null;
	deathDateLabel: string | null;
} | null;

export type AutorPublicoPayload = {
	autor: AutorPublicoIdentidad;
	obras: AutorPublicoObra[];
};

// --- Perfil métrico agregado (autores_resumen) ---

export type AutorResumen = {
	perfil_formas: Record<string, number>;
	perfil_formas_hijos: Record<string, number>;
	numero_efectivo_formas_medio: number | null;
	numero_efectivo_formas_agregado: number | null;
	total_versos_autor: number;
	n_obras_completas: number;
	n_jornadas_sueltas: number;
};

export type AutorListadoItem = {
	slug: string;
	nombre_completo: string;
	wikidata_id: string | null;
	imagen_wikidata: {
		url: string;
		commonsFile: string;
		sourceUrl: string;
	} | null;
	total_versos_autor: number;
	n_obras_completas: number;
	n_jornadas_sueltas: number;
	numero_efectivo_formas_agregado: number | null;
	perfil_formas: Record<string, number>;
	/** Obras principales del autor (top 5 por extensión). */
	top_obras?: AutorListadoObra[];
};

export type AutorListadoObra = {
	slug: string;
	titulo: string;
	total_versos: number | null;
};

// --- Fiabilidad (derivada en lectura; ver metodología §2.5) ---
//
// Umbrales por volumen de versos atribuidos al perfil. Editar estos números NO
// requiere recompute ni migración: la banda se calcula al renderizar.
export const FIABILIDAD_UMBRAL_VERSOS = { media: 1500, alta: 6000 } as const;

export type FiabilidadNivel = 'baja' | 'media' | 'alta';

export function fiabilidadDeVersos(totalVersos: number | null | undefined): FiabilidadNivel {
	const v = totalVersos ?? 0;
	if (v >= FIABILIDAD_UMBRAL_VERSOS.alta) return 'alta';
	if (v >= FIABILIDAD_UMBRAL_VERSOS.media) return 'media';
	return 'baja';
}

// --- Perfil de formas → slices para visualización ---

export type PerfilFormaSlice = {
	slug: string;
	label: string;
	versos: number;
	pct: number;
	color: string;
};

/** Prettifica un slug de forma a etiqueta legible (simplificación; sin vocabulario). */
export function prettyForma(slug: string): string {
	return slug.replace(/[_-]+/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
}

/** Convierte un perfil_formas {slug: versos} en slices ordenadas por peso. */
export function buildPerfilSlices(perfil: Record<string, number> | null | undefined): PerfilFormaSlice[] {
	const entries = Object.entries(perfil ?? {}).filter(([, versos]) => versos > 0);
	const total = entries.reduce((sum, [, versos]) => sum + versos, 0);
	return entries
		.map(([slug, versos]) => ({
			slug,
			label: prettyForma(slug),
			versos,
			pct: total > 0 ? (versos / total) * 100 : 0,
			color: colorForForma({ slug })
		}))
		.sort((a, b) => b.versos - a.versos || a.label.localeCompare(b.label, 'es'));
}
