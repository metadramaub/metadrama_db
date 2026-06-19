import { CATALOG_SECTION_IDS, isSectionVisible, type SectionVisibilityMap } from '$lib/secciones-publicas';

export type CatalogSortId =
	| 'titulo'
	| 'autor'
	| 'fecha'
	| 'versos'
	| 'updated'
	| 'diversidad'
	| 'densidad';

/** Tramo de forma fusionado tal y como lo guarda obras_resumen.tramos. */
export type CatalogTramo = {
	i: number;
	f: number;
	s: string;
	t: string | null;
};

export type CatalogFilterOption = {
	id: string;
	label: string;
	/** Slug del padre en la jerarquía del vocabulario (p. ej. subquintilla → quintilla). */
	parentId?: string | null;
};

/** Ítem para el selector jerárquico (CheckDropdown en modo hierarchical). */
export type CatalogHierarchyItem = {
	id: string;
	label: string;
	parentId: string | null;
};

export type CatalogRangeBounds = {
	min: number;
	max: number;
};

export type CatalogFilterOptions = {
	autores: CatalogFilterOption[];
	generos: CatalogFilterOption[];
	formas: CatalogFilterOption[];
	metros: CatalogFilterOption[];
	tiposForma: CatalogFilterOption[];
	variaciones: CatalogFilterOption[];
	subtipos: CatalogFilterOption[];
	bounds: {
		datacion: CatalogRangeBounds | null;
		versos: CatalogRangeBounds | null;
		densidad: CatalogRangeBounds | null;
	};
};

export type CatalogFilters = {
	textQuery: string;
	autores: string[];
	generos: string[];
	datacionMin: number | null;
	datacionMax: number | null;
	versosMin: number | null;
	versosMax: number | null;
	// Filtros métricos (gated por catalogo.filtros.metrica). Arrays = "contiene alguno".
	formas: string[];
	metros: string[];
	tiposForma: string[];
	variaciones: string[];
	subtipos: string[];
	densidadMin: number | null;
	densidadMax: number | null;
	sortBy: CatalogSortId;
};

export type CatalogActiveChipId =
	| 'textQuery'
	| 'autores'
	| 'generos'
	| 'datacion'
	| 'versos'
	| 'formas'
	| 'metros'
	| 'tiposForma'
	| 'variaciones'
	| 'subtipos'
	| 'densidad';

export type CatalogActiveChip = {
	id: CatalogActiveChipId;
	label: string;
};

export type CatalogObraForFilters = {
	titulo: string;
	autoria_autores: string[];
	genero_term: string | null;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	total_versos: number | null;
	updated_at: string | null;
	numero_efectivo_formas?: number | null;
	densidad_transiciones?: number | null;
	formas_presentes?: string[] | null;
	metros_presentes?: string[] | null;
	tipos_forma_presentes?: string[] | null;
	variaciones_presentes?: string[] | null;
	subtipos_presentes?: string[] | null;
};

export const CATALOG_SORT_OPTIONS: CatalogFilterOption[] = [
	{ id: 'titulo', label: 'Título' },
	{ id: 'autor', label: 'Autor' },
	{ id: 'fecha', label: 'Fecha' },
	{ id: 'versos', label: 'Nº de versos' },
	{ id: 'updated', label: 'Última modificación' }
];

/** Órdenes métricos: solo disponibles cuando el grupo de filtros métricos es visible. */
export const CATALOG_METRIC_SORT_OPTIONS: CatalogFilterOption[] = [
	{ id: 'diversidad', label: 'Diversidad métrica' },
	{ id: 'densidad', label: 'Densidad de transiciones' }
];

const ALL_SORT_IDS = new Set<CatalogSortId>([
	...CATALOG_SORT_OPTIONS.map((option) => option.id as CatalogSortId),
	...CATALOG_METRIC_SORT_OPTIONS.map((option) => option.id as CatalogSortId)
]);
const METRIC_SORT_IDS = new Set<CatalogSortId>(
	CATALOG_METRIC_SORT_OPTIONS.map((option) => option.id as CatalogSortId)
);

export function isCatalogMetricSortVisible(visibility: SectionVisibilityMap): boolean {
	return isSectionVisible(visibility, CATALOG_SECTION_IDS.filtrosMetrica);
}

/** El grupo `catalogo.filtros.metrica` gobierna tanto los filtros como el orden métricos. */
export function isCatalogMetricFiltersVisible(visibility: SectionVisibilityMap): boolean {
	return isSectionVisible(visibility, CATALOG_SECTION_IDS.filtrosMetrica);
}

/** Opciones de orden disponibles para este visitante (incluye métricas si procede). */
export function catalogSortOptions(visibility: SectionVisibilityMap): CatalogFilterOption[] {
	return isCatalogMetricSortVisible(visibility)
		? [...CATALOG_SORT_OPTIONS, ...CATALOG_METRIC_SORT_OPTIONS]
		: CATALOG_SORT_OPTIONS;
}

export function withCatalogVisibilityDefaults(
	visibility: SectionVisibilityMap
): SectionVisibilityMap {
	return {
		[CATALOG_SECTION_IDS.filtrosBasicos]: true,
		[CATALOG_SECTION_IDS.filtrosDatacionExtension]: true,
		[CATALOG_SECTION_IDS.filtrosMetrica]: false,
		[CATALOG_SECTION_IDS.filtrosDramaturgia]: false,
		[CATALOG_SECTION_IDS.resultadosPerfilMetrico]: false,
		[CATALOG_SECTION_IDS.laboratorio]: false,
		...visibility
	};
}

export function isCatalogBasicFiltersVisible(visibility: SectionVisibilityMap): boolean {
	return isSectionVisible(visibility, CATALOG_SECTION_IDS.filtrosBasicos);
}

export function isCatalogRangeFiltersVisible(visibility: SectionVisibilityMap): boolean {
	return isSectionVisible(visibility, CATALOG_SECTION_IDS.filtrosDatacionExtension);
}

/** ¿Mostrar el perfil métrico (mini-barcode + diversidad/densidad) en cada resultado? */
export function isCatalogPerfilMetricoVisible(visibility: SectionVisibilityMap): boolean {
	return isSectionVisible(visibility, CATALOG_SECTION_IDS.resultadosPerfilMetrico);
}

/**
 * Ítems del selector único de forma estrófica: formas raíz + subtipos anidados bajo
 * su raíz (p. ej. subquintillas bajo quintilla), respetando la jerarquía del
 * vocabulario. Los subtipos cuyo padre no esté presente caen a la raíz (parentId null).
 */
export function buildFormaSelectorItems(options: CatalogFilterOptions): CatalogHierarchyItem[] {
	const formaIds = new Set(options.formas.map((option) => option.id));
	const items: CatalogHierarchyItem[] = options.formas.map((option) => ({
		id: option.id,
		label: option.label,
		parentId: null
	}));
	for (const subtipo of options.subtipos) {
		const parentId = subtipo.parentId && formaIds.has(subtipo.parentId) ? subtipo.parentId : null;
		items.push({ id: subtipo.id, label: subtipo.label, parentId });
	}
	return items;
}

/**
 * Divide la selección combinada del selector de forma en sus dos dimensiones reales
 * del filtro: `formas` (matchean formas_presentes) y `subtipos` (matchean
 * subtipos_presentes). Mantiene separadas las dos facetas del modelo de datos.
 */
export function splitFormaSelection(
	ids: string[],
	options: CatalogFilterOptions
): { formas: string[]; subtipos: string[] } {
	const subtipoIds = new Set(options.subtipos.map((option) => option.id));
	const formas: string[] = [];
	const subtipos: string[] = [];
	for (const id of ids) {
		if (subtipoIds.has(id)) subtipos.push(id);
		else formas.push(id);
	}
	return { formas, subtipos };
}

export function createDefaultCatalogFilters(options: CatalogFilterOptions): CatalogFilters {
	return {
		textQuery: '',
		autores: [],
		generos: [],
		datacionMin: options.bounds.datacion?.min ?? null,
		datacionMax: options.bounds.datacion?.max ?? null,
		versosMin: options.bounds.versos?.min ?? null,
		versosMax: options.bounds.versos?.max ?? null,
		formas: [],
		metros: [],
		tiposForma: [],
		variaciones: [],
		subtipos: [],
		densidadMin: options.bounds.densidad?.min ?? null,
		densidadMax: options.bounds.densidad?.max ?? null,
		sortBy: 'titulo'
	};
}

export function parseCatalogFilters(
	searchParams: URLSearchParams,
	options: CatalogFilterOptions,
	visibility: SectionVisibilityMap
): CatalogFilters {
	const defaults = createDefaultCatalogFilters(options);
	const filters: CatalogFilters = { ...defaults };

	if (isCatalogBasicFiltersVisible(visibility)) {
		filters.textQuery = searchParams.get('q')?.trim() ?? '';
		filters.autores = sanitizeSelectedIds(readListParam(searchParams, 'autor'), options.autores);
		filters.generos = sanitizeSelectedIds(readListParam(searchParams, 'genero'), options.generos);
		const sortParam = searchParams.get('orden');
		// Un orden métrico solo se acepta si su grupo de filtros es visible.
		const metricSortAllowed = isCatalogMetricSortVisible(visibility);
		filters.sortBy =
			isCatalogSortId(sortParam) &&
			(metricSortAllowed || !METRIC_SORT_IDS.has(sortParam as CatalogSortId))
				? sortParam
				: defaults.sortBy;
	}

	if (isCatalogRangeFiltersVisible(visibility)) {
		filters.datacionMin = parseBound(searchParams.get('fecha_min'), defaults.datacionMin);
		filters.datacionMax = parseBound(searchParams.get('fecha_max'), defaults.datacionMax);
		filters.versosMin = parseBound(searchParams.get('versos_min'), defaults.versosMin);
		filters.versosMax = parseBound(searchParams.get('versos_max'), defaults.versosMax);
	}

	if (isCatalogMetricFiltersVisible(visibility)) {
		filters.formas = sanitizeSelectedIds(readListParam(searchParams, 'forma'), options.formas);
		filters.metros = sanitizeSelectedIds(readListParam(searchParams, 'metro'), options.metros);
		filters.tiposForma = sanitizeSelectedIds(readListParam(searchParams, 'tipo_forma'), options.tiposForma);
		filters.variaciones = sanitizeSelectedIds(readListParam(searchParams, 'variacion'), options.variaciones);
		filters.subtipos = sanitizeSelectedIds(readListParam(searchParams, 'subtipo'), options.subtipos);
		filters.densidadMin = parseBound(searchParams.get('densidad_min'), defaults.densidadMin);
		filters.densidadMax = parseBound(searchParams.get('densidad_max'), defaults.densidadMax);
	}

	return normalizeCatalogFilters(filters, options);
}

export function serializeCatalogFilters(
	filters: CatalogFilters,
	options: CatalogFilterOptions,
	visibility: SectionVisibilityMap
): URLSearchParams {
	const defaults = createDefaultCatalogFilters(options);
	const normalized = normalizeCatalogFilters(filters, options);
	const params = new URLSearchParams();

	if (isCatalogBasicFiltersVisible(visibility)) {
		const q = normalized.textQuery.trim();
		if (q) params.set('q', q);
		for (const autor of normalized.autores) params.append('autor', autor);
		for (const genero of normalized.generos) params.append('genero', genero);
		const sortIsMetric = METRIC_SORT_IDS.has(normalized.sortBy);
		const sortAllowed = !sortIsMetric || isCatalogMetricSortVisible(visibility);
		if (normalized.sortBy !== defaults.sortBy && sortAllowed) params.set('orden', normalized.sortBy);
	}

	if (isCatalogRangeFiltersVisible(visibility)) {
		if (normalized.datacionMin !== defaults.datacionMin && normalized.datacionMin !== null) {
			params.set('fecha_min', String(normalized.datacionMin));
		}
		if (normalized.datacionMax !== defaults.datacionMax && normalized.datacionMax !== null) {
			params.set('fecha_max', String(normalized.datacionMax));
		}
		if (normalized.versosMin !== defaults.versosMin && normalized.versosMin !== null) {
			params.set('versos_min', String(normalized.versosMin));
		}
		if (normalized.versosMax !== defaults.versosMax && normalized.versosMax !== null) {
			params.set('versos_max', String(normalized.versosMax));
		}
	}

	if (isCatalogMetricFiltersVisible(visibility)) {
		for (const forma of normalized.formas) params.append('forma', forma);
		for (const metro of normalized.metros) params.append('metro', metro);
		for (const tipo of normalized.tiposForma) params.append('tipo_forma', tipo);
		for (const variacion of normalized.variaciones) params.append('variacion', variacion);
		for (const subtipo of normalized.subtipos) params.append('subtipo', subtipo);
		if (normalized.densidadMin !== defaults.densidadMin && normalized.densidadMin !== null) {
			params.set('densidad_min', String(normalized.densidadMin));
		}
		if (normalized.densidadMax !== defaults.densidadMax && normalized.densidadMax !== null) {
			params.set('densidad_max', String(normalized.densidadMax));
		}
	}

	return params;
}

export function normalizeCatalogFilters(
	filters: CatalogFilters,
	options: CatalogFilterOptions
): CatalogFilters {
	const datacion = normalizeRange(filters.datacionMin, filters.datacionMax, options.bounds.datacion);
	const versos = normalizeRange(filters.versosMin, filters.versosMax, options.bounds.versos);
	const densidad = normalizeRange(filters.densidadMin, filters.densidadMax, options.bounds.densidad);

	return {
		textQuery: filters.textQuery.trim(),
		autores: sanitizeSelectedIds(filters.autores, options.autores),
		generos: sanitizeSelectedIds(filters.generos, options.generos),
		datacionMin: datacion.min,
		datacionMax: datacion.max,
		versosMin: versos.min,
		versosMax: versos.max,
		formas: sanitizeSelectedIds(filters.formas, options.formas),
		metros: sanitizeSelectedIds(filters.metros, options.metros),
		tiposForma: sanitizeSelectedIds(filters.tiposForma, options.tiposForma),
		variaciones: sanitizeSelectedIds(filters.variaciones, options.variaciones),
		subtipos: sanitizeSelectedIds(filters.subtipos, options.subtipos),
		densidadMin: densidad.min,
		densidadMax: densidad.max,
		sortBy: ALL_SORT_IDS.has(filters.sortBy) ? filters.sortBy : 'titulo'
	};
}

export function filterAndSortCatalogObras<T extends CatalogObraForFilters>(
	obras: T[],
	filters: CatalogFilters,
	options: CatalogFilterOptions
): T[] {
	const normalized = normalizeCatalogFilters(filters, options);
	const q = normalized.textQuery.toLowerCase();
	const datacionDefault = options.bounds.datacion;
	const versosDefault = options.bounds.versos;
	const hasDatacionFilter =
		Boolean(datacionDefault) &&
		(normalized.datacionMin !== datacionDefault?.min || normalized.datacionMax !== datacionDefault?.max);
	const hasVersosFilter =
		Boolean(versosDefault) &&
		(normalized.versosMin !== versosDefault?.min || normalized.versosMax !== versosDefault?.max);
	const densidadDefault = options.bounds.densidad;
	const hasDensidadFilter =
		Boolean(densidadDefault) &&
		(normalized.densidadMin !== densidadDefault?.min || normalized.densidadMax !== densidadDefault?.max);

	const rows = obras.filter((obra) => {
		if (q) {
			const hay =
				obra.titulo.toLowerCase().includes(q) ||
				obra.autoria_autores.some((autor) => autor.toLowerCase().includes(q));
			if (!hay) return false;
		}
		if (normalized.autores.length > 0) {
			if (!obra.autoria_autores.some((autor) => normalized.autores.includes(autor))) return false;
		}
		if (normalized.generos.length > 0) {
			if (!obra.genero_term || !normalized.generos.includes(obra.genero_term)) return false;
		}
		if (hasDatacionFilter && datacionDefault) {
			const obraRange = obraDatacionRange(obra);
			if (!obraRange) return false;
			if (!rangesOverlap(obraRange.min, obraRange.max, normalized.datacionMin, normalized.datacionMax)) {
				return false;
			}
		}
		if (hasVersosFilter && versosDefault) {
			if (obra.total_versos === null) return false;
			if (normalized.versosMin !== null && obra.total_versos < normalized.versosMin) return false;
			if (normalized.versosMax !== null && obra.total_versos > normalized.versosMax) return false;
		}
		// Filtros métricos por solapamiento: la obra debe contener AL MENOS uno de los
		// términos seleccionados en cada faceta activa.
		if (normalized.formas.length > 0 && !overlaps(obra.formas_presentes, normalized.formas)) return false;
		if (normalized.metros.length > 0 && !overlaps(obra.metros_presentes, normalized.metros)) return false;
		if (normalized.tiposForma.length > 0 && !overlaps(obra.tipos_forma_presentes, normalized.tiposForma)) {
			return false;
		}
		if (normalized.variaciones.length > 0 && !overlaps(obra.variaciones_presentes, normalized.variaciones)) {
			return false;
		}
		if (normalized.subtipos.length > 0 && !overlaps(obra.subtipos_presentes, normalized.subtipos)) return false;
		if (hasDensidadFilter && densidadDefault) {
			const d = obra.densidad_transiciones ?? null;
			if (d === null) return false;
			if (normalized.densidadMin !== null && d < normalized.densidadMin) return false;
			if (normalized.densidadMax !== null && d > normalized.densidadMax) return false;
		}
		return true;
	});

	return [...rows].sort((a, b) => compareCatalogObras(a, b, normalized.sortBy));
}

export function buildCatalogActiveChips(
	filters: CatalogFilters,
	options: CatalogFilterOptions,
	visibility: SectionVisibilityMap
): CatalogActiveChip[] {
	const defaults = createDefaultCatalogFilters(options);
	const normalized = normalizeCatalogFilters(filters, options);
	const chips: CatalogActiveChip[] = [];

	if (isCatalogBasicFiltersVisible(visibility)) {
		if (normalized.textQuery) {
			chips.push({ id: 'textQuery', label: `Texto: "${normalized.textQuery}"` });
		}
		if (normalized.autores.length > 0) {
			chips.push({ id: 'autores', label: `Autoría: ${shortListLabel(normalized.autores)}` });
		}
		if (normalized.generos.length > 0) {
			chips.push({ id: 'generos', label: `Género: ${shortListLabel(normalized.generos)}` });
		}
	}

	if (isCatalogRangeFiltersVisible(visibility)) {
		if (
			normalized.datacionMin !== defaults.datacionMin ||
			normalized.datacionMax !== defaults.datacionMax
		) {
			chips.push({
				id: 'datacion',
				label: `Datación: ${normalized.datacionMin ?? '...'}-${normalized.datacionMax ?? '...'}`
			});
		}
		if (normalized.versosMin !== defaults.versosMin || normalized.versosMax !== defaults.versosMax) {
			chips.push({
				id: 'versos',
				label: `Versos: ${normalized.versosMin ?? '...'}-${normalized.versosMax ?? '...'}`
			});
		}
	}

	if (isCatalogMetricFiltersVisible(visibility)) {
		// Forma estrófica: formas raíz + subtipos van en un solo chip (un solo selector).
		if (normalized.formas.length > 0 || normalized.subtipos.length > 0) {
			const labelById = new Map(
				[...options.formas, ...options.subtipos].map((option) => [option.id, option.label])
			);
			const labels = [...normalized.formas, ...normalized.subtipos].map((id) => labelById.get(id) ?? id);
			chips.push({ id: 'formas', label: `Forma estrófica: ${shortListLabel(labels)}` });
		}
		if (normalized.metros.length > 0) {
			chips.push({ id: 'metros', label: `Metros: ${labelListFor(normalized.metros, options.metros)}` });
		}
		if (normalized.tiposForma.length > 0) {
			chips.push({
				id: 'tiposForma',
				label: `Tipo: ${labelListFor(normalized.tiposForma, options.tiposForma)}`
			});
		}
		if (normalized.variaciones.length > 0) {
			chips.push({
				id: 'variaciones',
				label: `Variaciones: ${labelListFor(normalized.variaciones, options.variaciones)}`
			});
		}
		if (normalized.densidadMin !== defaults.densidadMin || normalized.densidadMax !== defaults.densidadMax) {
			chips.push({
				id: 'densidad',
				label: `Densidad: ${normalized.densidadMin ?? '...'}-${normalized.densidadMax ?? '...'}`
			});
		}
	}

	return chips;
}

export function removeCatalogChip(
	filters: CatalogFilters,
	chipId: CatalogActiveChipId,
	options: CatalogFilterOptions
): CatalogFilters {
	const defaults = createDefaultCatalogFilters(options);
	if (chipId === 'textQuery') return { ...filters, textQuery: '' };
	if (chipId === 'autores') return { ...filters, autores: [] };
	if (chipId === 'generos') return { ...filters, generos: [] };
	if (chipId === 'datacion') {
		return { ...filters, datacionMin: defaults.datacionMin, datacionMax: defaults.datacionMax };
	}
	if (chipId === 'versos') {
		return { ...filters, versosMin: defaults.versosMin, versosMax: defaults.versosMax };
	}
	// El chip de forma estrófica agrupa formas raíz + subtipos: limpia ambas.
	if (chipId === 'formas') return { ...filters, formas: [], subtipos: [] };
	if (chipId === 'metros') return { ...filters, metros: [] };
	if (chipId === 'tiposForma') return { ...filters, tiposForma: [] };
	if (chipId === 'variaciones') return { ...filters, variaciones: [] };
	if (chipId === 'subtipos') return { ...filters, subtipos: [] };
	return { ...filters, densidadMin: defaults.densidadMin, densidadMax: defaults.densidadMax };
}

export function deriveCatalogBounds(obras: CatalogObraForFilters[]): CatalogFilterOptions['bounds'] {
	const dataciones = obras
		.flatMap((obra) => [obra.fecha_inicio_trad, obra.fecha_fin_trad])
		.filter((value): value is number => Number.isFinite(value));
	const versos = obras
		.map((obra) => obra.total_versos)
		.filter((value): value is number => Number.isFinite(value));
	const densidades = obras
		.map((obra) => obra.densidad_transiciones)
		.filter((value): value is number => Number.isFinite(value ?? NaN));

	return {
		datacion: dataciones.length > 0 ? { min: Math.min(...dataciones), max: Math.max(...dataciones) } : null,
		versos: versos.length > 0 ? { min: Math.min(...versos), max: Math.max(...versos) } : null,
		densidad:
			densidades.length > 0
				? { min: Math.floor(Math.min(...densidades)), max: Math.ceil(Math.max(...densidades)) }
				: null
	};
}

function readListParam(searchParams: URLSearchParams, key: string): string[] {
	return searchParams
		.getAll(key)
		.flatMap((value) => value.split(','))
		.map((value) => value.trim())
		.filter(Boolean);
}

function sanitizeSelectedIds(values: string[], options: CatalogFilterOption[]): string[] {
	const validIds = new Set(options.map((option) => option.id));
	const next: string[] = [];
	for (const value of values) {
		if (!validIds.has(value) || next.includes(value)) continue;
		next.push(value);
	}
	return next;
}

/** ¿La lista de la obra contiene alguno de los términos seleccionados? */
function overlaps(present: string[] | null | undefined, selected: string[]): boolean {
	if (!present || present.length === 0) return false;
	const set = new Set(present);
	return selected.some((value) => set.has(value));
}

/** Etiquetas visibles de los ids seleccionados (resuelve slug → etiqueta vía options). */
function labelListFor(ids: string[], options: CatalogFilterOption[]): string {
	const labelById = new Map(options.map((option) => [option.id, option.label]));
	return shortListLabel(ids.map((id) => labelById.get(id) ?? id));
}

function parseBound(value: string | null, fallback: number | null): number | null {
	if (value === null || value.trim() === '') return fallback;
	const parsed = Number(value);
	return Number.isFinite(parsed) ? Math.round(parsed) : fallback;
}

function normalizeRange(
	min: number | null,
	max: number | null,
	bounds: CatalogRangeBounds | null
): { min: number | null; max: number | null } {
	if (!bounds) return { min: null, max: null };
	const nextMin = clamp(Number.isFinite(min) ? Number(min) : bounds.min, bounds.min, bounds.max);
	const nextMax = clamp(Number.isFinite(max) ? Number(max) : bounds.max, bounds.min, bounds.max);
	if (nextMin <= nextMax) return { min: nextMin, max: nextMax };
	return { min: nextMax, max: nextMin };
}

function clamp(value: number, min: number, max: number): number {
	return Math.min(max, Math.max(min, Math.round(value)));
}

function isCatalogSortId(value: string | null): value is CatalogSortId {
	return value !== null && ALL_SORT_IDS.has(value as CatalogSortId);
}

function obraDatacionRange(obra: CatalogObraForFilters): { min: number; max: number } | null {
	const start = obra.fecha_inicio_trad ?? obra.fecha_fin_trad;
	const end = obra.fecha_fin_trad ?? obra.fecha_inicio_trad;
	if (start === null || end === null) return null;
	return { min: Math.min(start, end), max: Math.max(start, end) };
}

function rangesOverlap(
	itemMin: number,
	itemMax: number,
	filterMin: number | null,
	filterMax: number | null
): boolean {
	if (filterMin !== null && itemMax < filterMin) return false;
	if (filterMax !== null && itemMin > filterMax) return false;
	return true;
}

function compareCatalogObras<T extends CatalogObraForFilters>(
	a: T,
	b: T,
	sortBy: CatalogSortId
): number {
	if (sortBy === 'autor') {
		return (a.autoria_autores[0] ?? '').localeCompare(b.autoria_autores[0] ?? '', 'es');
	}
	if (sortBy === 'fecha') {
		return obraFecha(a) - obraFecha(b);
	}
	if (sortBy === 'versos') {
		return (b.total_versos ?? -1) - (a.total_versos ?? -1);
	}
	if (sortBy === 'updated') {
		return (b.updated_at ?? '').localeCompare(a.updated_at ?? '');
	}
	if (sortBy === 'diversidad') {
		return (b.numero_efectivo_formas ?? -1) - (a.numero_efectivo_formas ?? -1);
	}
	if (sortBy === 'densidad') {
		return (b.densidad_transiciones ?? -1) - (a.densidad_transiciones ?? -1);
	}
	return a.titulo.localeCompare(b.titulo, 'es');
}

function obraFecha(obra: CatalogObraForFilters): number {
	return obra.fecha_inicio_trad ?? obra.fecha_fin_trad ?? Number.POSITIVE_INFINITY;
}

function shortListLabel(values: string[]): string {
	if (values.length <= 2) return values.join(', ');
	return `${values.slice(0, 2).join(', ')} +${values.length - 2}`;
}
