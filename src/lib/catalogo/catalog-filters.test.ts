import { describe, expect, it } from 'vitest';
import {
	CATALOG_SORT_OPTIONS,
	buildCatalogActiveChips,
	buildFormaSelectorItems,
	catalogSortOptions,
	createDefaultCatalogFilters,
	deriveCatalogBounds,
	filterAndSortCatalogObras,
	parseCatalogFilters,
	serializeCatalogFilters,
	splitFormaSelection,
	withCatalogVisibilityDefaults,
	type CatalogFilterOptions,
	type CatalogObraForFilters
} from './catalog-filters';
import { CATALOG_SECTION_IDS, type SectionVisibilityMap } from '$lib/secciones-publicas';

const visibilityAll: SectionVisibilityMap = {
	[CATALOG_SECTION_IDS.filtrosBasicos]: true,
	[CATALOG_SECTION_IDS.filtrosDatacionExtension]: true
};

const visibilityWithMetric: SectionVisibilityMap = {
	[CATALOG_SECTION_IDS.filtrosBasicos]: true,
	[CATALOG_SECTION_IDS.filtrosDatacionExtension]: true,
	[CATALOG_SECTION_IDS.filtrosMetrica]: true
};

const visibilityNoRanges: SectionVisibilityMap = {
	[CATALOG_SECTION_IDS.filtrosBasicos]: true,
	[CATALOG_SECTION_IDS.filtrosDatacionExtension]: false
};

const obras: CatalogObraForFilters[] = [
	{
		titulo: 'La dama boba',
		autoria_autores: ['Lope de Vega'],
		genero_term: 'Comedia',
		fecha_inicio_trad: 1613,
		fecha_fin_trad: 1613,
		total_versos: 3184,
		updated_at: '2026-01-02'
	},
	{
		titulo: 'El alcalde de Zalamea',
		autoria_autores: ['Calderón de la Barca'],
		genero_term: 'Drama',
		fecha_inicio_trad: 1642,
		fecha_fin_trad: 1644,
		total_versos: 2790,
		updated_at: '2026-01-01'
	},
	{
		titulo: 'Obra sin datos',
		autoria_autores: [],
		genero_term: null,
		fecha_inicio_trad: null,
		fecha_fin_trad: null,
		total_versos: null,
		updated_at: null
	}
];

function options(overrides: Partial<CatalogFilterOptions> = {}): CatalogFilterOptions {
	return {
		autores: [
			{ id: 'Calderón de la Barca', label: 'Calderón de la Barca' },
			{ id: 'Lope de Vega', label: 'Lope de Vega' }
		],
		generos: [
			{ id: 'Comedia', label: 'Comedia' },
			{ id: 'Drama', label: 'Drama' }
		],
		formas: [],
		metros: [],
		tiposForma: [],
		variaciones: [],
		subtipos: [],
		bounds: deriveCatalogBounds(obras),
		...overrides
	};
}

describe('catalog-filters', () => {
	it('deriva bounds compactos desde las obras visibles', () => {
		expect(deriveCatalogBounds(obras)).toEqual({
			datacion: { min: 1613, max: 1644 },
			versos: { min: 2790, max: 3184 },
			densidad: null
		});
	});

	it('filtra por texto, autoría, género, datación y versos', () => {
		const opts = options();
		const filters = {
			...createDefaultCatalogFilters(opts),
			textQuery: 'dama',
			autores: ['Lope de Vega'],
			generos: ['Comedia'],
			datacionMin: 1600,
			datacionMax: 1620,
			versosMin: 3000,
			versosMax: 3200
		};

		expect(filterAndSortCatalogObras(obras, filters, opts).map((obra) => obra.titulo)).toEqual([
			'La dama boba'
		]);
	});

	it('ordena por los criterios públicos actuales', () => {
		const opts = options();
		const byVerses = filterAndSortCatalogObras(
			obras,
			{ ...createDefaultCatalogFilters(opts), sortBy: 'versos' },
			opts
		);
		expect(byVerses[0].titulo).toBe('La dama boba');
		expect(CATALOG_SORT_OPTIONS.map((option) => option.id)).toEqual([
			'titulo',
			'autor',
			'fecha',
			'versos',
			'updated'
		]);
	});

	it('serializa y parsea la URL sin aceptar opciones inexistentes', () => {
		const opts = options();
		const params = new URLSearchParams(
			'q=dama&autor=Lope+de+Vega&autor=Inventado&genero=Comedia&fecha_min=1600&versos_max=3200&orden=updated'
		);

		const parsed = parseCatalogFilters(params, opts, visibilityAll);
		expect(parsed.autores).toEqual(['Lope de Vega']);
		expect(parsed.generos).toEqual(['Comedia']);
		expect(parsed.sortBy).toBe('updated');

		const serialized = serializeCatalogFilters(parsed, opts, visibilityAll);
		expect(serialized.get('q')).toBe('dama');
		expect(serialized.getAll('autor')).toEqual(['Lope de Vega']);
		expect(serialized.get('orden')).toBe('updated');
	});

	it('ignora filtros de rangos cuando su grupo no es visible', () => {
		const opts = options();
		const parsed = parseCatalogFilters(
			new URLSearchParams('fecha_min=1600&fecha_max=1620&versos_min=3000'),
			opts,
			visibilityNoRanges
		);

		expect(parsed.datacionMin).toBe(opts.bounds.datacion?.min);
		expect(parsed.datacionMax).toBe(opts.bounds.datacion?.max);
		expect(parsed.versosMin).toBe(opts.bounds.versos?.min);
	});

	it('usa defaults de catálogo si las filas nuevas aún no existen', () => {
		const visibility = withCatalogVisibilityDefaults({});
		expect(visibility[CATALOG_SECTION_IDS.filtrosBasicos]).toBe(true);
		expect(visibility[CATALOG_SECTION_IDS.filtrosDatacionExtension]).toBe(true);
		expect(visibility[CATALOG_SECTION_IDS.filtrosMetrica]).toBe(false);

		const explicit = withCatalogVisibilityDefaults({
			[CATALOG_SECTION_IDS.filtrosBasicos]: false
		});
		expect(explicit[CATALOG_SECTION_IDS.filtrosBasicos]).toBe(false);
	});

	it('expone los órdenes métricos solo si el grupo métrico es visible', () => {
		expect(catalogSortOptions(visibilityAll).map((o) => o.id)).toEqual([
			'titulo',
			'autor',
			'fecha',
			'versos',
			'updated'
		]);
		expect(catalogSortOptions(visibilityWithMetric).map((o) => o.id)).toEqual([
			'titulo',
			'autor',
			'fecha',
			'versos',
			'updated',
			'diversidad',
			'densidad'
		]);
	});

	it('rechaza un orden métrico en la URL si el grupo métrico no es visible', () => {
		const opts = options();
		const off = parseCatalogFilters(new URLSearchParams('orden=diversidad'), opts, visibilityAll);
		expect(off.sortBy).toBe('titulo');

		const on = parseCatalogFilters(
			new URLSearchParams('orden=diversidad'),
			opts,
			visibilityWithMetric
		);
		expect(on.sortBy).toBe('diversidad');
	});

	it('ordena por diversidad y densidad métricas', () => {
		const opts = options();
		const metricObras: CatalogObraForFilters[] = [
			{
				titulo: 'Baja diversidad',
				autoria_autores: [],
				genero_term: null,
				fecha_inicio_trad: null,
				fecha_fin_trad: null,
				total_versos: 1000,
				updated_at: null,
				numero_efectivo_formas: 1.2,
				densidad_transiciones: 5
			},
			{
				titulo: 'Alta diversidad',
				autoria_autores: [],
				genero_term: null,
				fecha_inicio_trad: null,
				fecha_fin_trad: null,
				total_versos: 1000,
				updated_at: null,
				numero_efectivo_formas: 6.4,
				densidad_transiciones: 2
			}
		];

		const byDiversidad = filterAndSortCatalogObras(
			metricObras,
			{ ...createDefaultCatalogFilters(opts), sortBy: 'diversidad' },
			opts
		);
		expect(byDiversidad[0].titulo).toBe('Alta diversidad');

		const byDensidad = filterAndSortCatalogObras(
			metricObras,
			{ ...createDefaultCatalogFilters(opts), sortBy: 'densidad' },
			opts
		);
		expect(byDensidad[0].titulo).toBe('Baja diversidad');
	});

	it('filtra por formas presentes (contiene alguna) cuando el grupo métrico es visible', () => {
		const metricObras: CatalogObraForFilters[] = [
			{
				titulo: 'Con romance',
				autoria_autores: [],
				genero_term: null,
				fecha_inicio_trad: null,
				fecha_fin_trad: null,
				total_versos: 1000,
				updated_at: null,
				formas_presentes: ['romance', 'redondilla']
			},
			{
				titulo: 'Sin romance',
				autoria_autores: [],
				genero_term: null,
				fecha_inicio_trad: null,
				fecha_fin_trad: null,
				total_versos: 1000,
				updated_at: null,
				formas_presentes: ['silva', 'soneto']
			}
		];
		const opts = options({ formas: [{ id: 'romance', label: 'Romance' }] });
		const filters = { ...createDefaultCatalogFilters(opts), formas: ['romance'] };

		expect(filterAndSortCatalogObras(metricObras, filters, opts).map((o) => o.titulo)).toEqual([
			'Con romance'
		]);
	});

	it('ignora un filtro métrico de la URL si el grupo métrico no es visible', () => {
		const opts = options({ formas: [{ id: 'romance', label: 'Romance' }] });
		const parsed = parseCatalogFilters(new URLSearchParams('forma=romance'), opts, visibilityAll);
		expect(parsed.formas).toEqual([]);

		const parsedMetric = parseCatalogFilters(
			new URLSearchParams('forma=romance'),
			opts,
			visibilityWithMetric
		);
		expect(parsedMetric.formas).toEqual(['romance']);
	});

	it('arma el selector de forma con subtipos anidados bajo su raíz', () => {
		const opts = options({
			formas: [
				{ id: 'quintilla', label: 'Quintilla' },
				{ id: 'romance', label: 'Romance' }
			],
			subtipos: [
				{ id: 'quintilla_1_ababa', label: 'Quintilla ababa', parentId: 'quintilla' },
				{ id: 'huerfano', label: 'Huérfano', parentId: 'inexistente' }
			]
		});
		const items = buildFormaSelectorItems(opts);

		expect(items.find((i) => i.id === 'quintilla')?.parentId).toBeNull();
		expect(items.find((i) => i.id === 'quintilla_1_ababa')?.parentId).toBe('quintilla');
		// Subtipo cuyo padre no está presente cae a la raíz (no se queda huérfano/oculto).
		expect(items.find((i) => i.id === 'huerfano')?.parentId).toBeNull();
	});

	it('divide la selección combinada en formas y subtipos reales', () => {
		const opts = options({
			formas: [{ id: 'quintilla', label: 'Quintilla' }],
			subtipos: [{ id: 'quintilla_1_ababa', label: 'Quintilla ababa', parentId: 'quintilla' }]
		});
		expect(splitFormaSelection(['quintilla', 'quintilla_1_ababa'], opts)).toEqual({
			formas: ['quintilla'],
			subtipos: ['quintilla_1_ababa']
		});
	});

	it('construye chips solo de grupos visibles', () => {
		const opts = options();
		const filters = {
			...createDefaultCatalogFilters(opts),
			textQuery: 'dama',
			datacionMin: 1600
		};

		expect(buildCatalogActiveChips(filters, opts, visibilityNoRanges).map((chip) => chip.id)).toEqual([
			'textQuery'
		]);
	});
});
