import { CATALOG_SECTION_IDS, isSectionVisible, type SectionVisibilityMap } from '$lib/secciones-publicas';

export type CatalogSortId = 'titulo' | 'autor' | 'fecha' | 'versos' | 'updated';

export type CatalogFilterOption = {
	id: string;
	label: string;
};

export type CatalogRangeBounds = {
	min: number;
	max: number;
};

export type CatalogFilterOptions = {
	autores: CatalogFilterOption[];
	generos: CatalogFilterOption[];
	bounds: {
		datacion: CatalogRangeBounds | null;
		versos: CatalogRangeBounds | null;
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
	sortBy: CatalogSortId;
};

export type CatalogActiveChipId =
	| 'textQuery'
	| 'autores'
	| 'generos'
	| 'datacion'
	| 'versos';

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
};

export const CATALOG_SORT_OPTIONS: CatalogFilterOption[] = [
	{ id: 'titulo', label: 'Título' },
	{ id: 'autor', label: 'Autor' },
	{ id: 'fecha', label: 'Fecha' },
	{ id: 'versos', label: 'Nº de versos' },
	{ id: 'updated', label: 'Última modificación' }
];

const SORT_IDS = new Set<CatalogSortId>(
	CATALOG_SORT_OPTIONS.map((option) => option.id as CatalogSortId)
);

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

export function createDefaultCatalogFilters(options: CatalogFilterOptions): CatalogFilters {
	return {
		textQuery: '',
		autores: [],
		generos: [],
		datacionMin: options.bounds.datacion?.min ?? null,
		datacionMax: options.bounds.datacion?.max ?? null,
		versosMin: options.bounds.versos?.min ?? null,
		versosMax: options.bounds.versos?.max ?? null,
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
		filters.sortBy = isCatalogSortId(sortParam) ? sortParam : defaults.sortBy;
	}

	if (isCatalogRangeFiltersVisible(visibility)) {
		filters.datacionMin = parseBound(searchParams.get('fecha_min'), defaults.datacionMin);
		filters.datacionMax = parseBound(searchParams.get('fecha_max'), defaults.datacionMax);
		filters.versosMin = parseBound(searchParams.get('versos_min'), defaults.versosMin);
		filters.versosMax = parseBound(searchParams.get('versos_max'), defaults.versosMax);
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
		if (normalized.sortBy !== defaults.sortBy) params.set('orden', normalized.sortBy);
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

	return params;
}

export function normalizeCatalogFilters(
	filters: CatalogFilters,
	options: CatalogFilterOptions
): CatalogFilters {
	const datacion = normalizeRange(filters.datacionMin, filters.datacionMax, options.bounds.datacion);
	const versos = normalizeRange(filters.versosMin, filters.versosMax, options.bounds.versos);

	return {
		textQuery: filters.textQuery.trim(),
		autores: sanitizeSelectedIds(filters.autores, options.autores),
		generos: sanitizeSelectedIds(filters.generos, options.generos),
		datacionMin: datacion.min,
		datacionMax: datacion.max,
		versosMin: versos.min,
		versosMax: versos.max,
		sortBy: SORT_IDS.has(filters.sortBy) ? filters.sortBy : 'titulo'
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
	return { ...filters, versosMin: defaults.versosMin, versosMax: defaults.versosMax };
}

export function deriveCatalogBounds(obras: CatalogObraForFilters[]): CatalogFilterOptions['bounds'] {
	const dataciones = obras
		.flatMap((obra) => [obra.fecha_inicio_trad, obra.fecha_fin_trad])
		.filter((value): value is number => Number.isFinite(value));
	const versos = obras
		.map((obra) => obra.total_versos)
		.filter((value): value is number => Number.isFinite(value));

	return {
		datacion: dataciones.length > 0 ? { min: Math.min(...dataciones), max: Math.max(...dataciones) } : null,
		versos: versos.length > 0 ? { min: Math.min(...versos), max: Math.max(...versos) } : null
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
	return value !== null && SORT_IDS.has(value as CatalogSortId);
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
	return a.titulo.localeCompare(b.titulo, 'es');
}

function obraFecha(obra: CatalogObraForFilters): number {
	return obra.fecha_inicio_trad ?? obra.fecha_fin_trad ?? Number.POSITIVE_INFINITY;
}

function shortListLabel(values: string[]): string {
	if (values.length <= 2) return values.join(', ');
	return `${values.slice(0, 2).join(', ')} +${values.length - 2}`;
}
