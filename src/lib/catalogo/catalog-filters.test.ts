import { describe, expect, it } from 'vitest';
import {
	CATALOG_SORT_OPTIONS,
	buildCatalogActiveChips,
	createDefaultCatalogFilters,
	deriveCatalogBounds,
	filterAndSortCatalogObras,
	parseCatalogFilters,
	serializeCatalogFilters,
	withCatalogVisibilityDefaults,
	type CatalogFilterOptions,
	type CatalogObraForFilters
} from './catalog-filters';
import { CATALOG_SECTION_IDS, type SectionVisibilityMap } from '$lib/secciones-publicas';

const visibilityAll: SectionVisibilityMap = {
	[CATALOG_SECTION_IDS.filtrosBasicos]: true,
	[CATALOG_SECTION_IDS.filtrosDatacionExtension]: true
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

function options(): CatalogFilterOptions {
	return {
		autores: [
			{ id: 'Calderón de la Barca', label: 'Calderón de la Barca' },
			{ id: 'Lope de Vega', label: 'Lope de Vega' }
		],
		generos: [
			{ id: 'Comedia', label: 'Comedia' },
			{ id: 'Drama', label: 'Drama' }
		],
		bounds: deriveCatalogBounds(obras)
	};
}

describe('catalog-filters', () => {
	it('deriva bounds compactos desde las obras visibles', () => {
		expect(deriveCatalogBounds(obras)).toEqual({
			datacion: { min: 1613, max: 1644 },
			versos: { min: 2790, max: 3184 }
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
