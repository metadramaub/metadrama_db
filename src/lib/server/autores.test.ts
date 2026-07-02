import { describe, expect, it } from 'vitest';
import {
	buildAuthorSearchValues,
	findSimilarAuthors,
	matchesAuthorSearch,
	normalizeAuthorSearchTerm,
	normalizeAuthorSortName,
	normalizeAuthorVariants
} from './autores';

describe('autores helpers', () => {
	it('preserves capitalization and accents in author sort names', () => {
		expect(normalizeAuthorSortName('  Vélez de Guevara, Luis  ')).toBe(
			'Vélez de Guevara, Luis'
		);
	});

	it('normalizes only search terms for accent-insensitive matching', () => {
		expect(normalizeAuthorSearchTerm('  Vélez   de Guevara, Luis  ')).toBe(
			'velez de guevara, luis'
		);
	});

	it('deduplicates variants by search key while preserving the first visible spelling', () => {
		expect(normalizeAuthorVariants(['Guillén de Castro', 'guillen de castro', 'Guillem de Castro'])).toEqual([
			'Guillén de Castro',
			'Guillem de Castro'
		]);
	});

	it('builds search values with direct and inverted name orders', () => {
		const values = buildAuthorSearchValues({
			nombre_completo: 'Lope de Vega',
			nombre_normalizado: 'Vega Carpio, Lope de',
			variantes_nombre: ['Fénix de los Ingenios'],
			bnedatos_id: null,
			viaf_id: '89773778',
			wikidata_id: 'Q165257'
		});

		expect(values).toContain('Vega Carpio, Lope de');
		expect(values).toContain('Lope de Vega Carpio');
		expect(values).toContain('Fénix de los Ingenios');
		expect(values).toContain('89773778');
	});

	it('matches authors by normalized name, generated direct order, variants and external ids', () => {
		const author = {
			nombre_completo: 'Luis Vélez de Guevara',
			nombre_normalizado: 'Vélez de Guevara, Luis',
			variantes_nombre: ['Luis Vélez'],
			bnedatos_id: null,
			viaf_id: '100184949',
			wikidata_id: 'Q724892'
		};

		expect(matchesAuthorSearch(author, 'velez de guevara')).toBe(true);
		expect(matchesAuthorSearch(author, 'Luis Vélez')).toBe(true);
		expect(matchesAuthorSearch(author, 'luis velez de guevara')).toBe(true);
		expect(matchesAuthorSearch(author, 'Q724892')).toBe(true);
		expect(matchesAuthorSearch(author, 'Cervantes')).toBe(false);
	});

	it('finds similar authors ignoring accents', () => {
		const similar = findSimilarAuthors(
			{
				nombre_completo: 'Luis Velez de Guevara',
				nombre_normalizado: 'Velez de Guevara, Luis',
				variantes_nombre: null
			},
			[
				{
					autor_id: 'author-1',
					nombre_completo: 'Luis Vélez de Guevara',
					nombre_normalizado: 'Vélez de Guevara, Luis',
					variantes_nombre: null
				}
			]
		);

		expect(similar).toHaveLength(1);
		expect(similar[0].autor_id).toBe('author-1');
		expect(similar[0].reason).toBe('exact');
	});

	it('finds similar authors across direct and inverted order', () => {
		const similar = findSimilarAuthors(
			{
				nombre_completo: 'Lope de Vega Carpio',
				nombre_normalizado: 'Vega Carpio, Lope de',
				variantes_nombre: null
			},
			[
				{
					autor_id: 'author-1',
					nombre_completo: 'Lope de Vega',
					nombre_normalizado: 'Vega Carpio, Lope de',
					variantes_nombre: null
				}
			]
		);

		expect(similar).toHaveLength(1);
		expect(similar[0].autor_id).toBe('author-1');
	});

	it('does not find similarity for clearly different author names', () => {
		const similar = findSimilarAuthors(
			{
				nombre_completo: 'Miguel de Cervantes',
				nombre_normalizado: 'Cervantes Saavedra, Miguel de',
				variantes_nombre: null
			},
			[
				{
					autor_id: 'author-1',
					nombre_completo: 'Luis Vélez de Guevara',
					nombre_normalizado: 'Vélez de Guevara, Luis',
					variantes_nombre: null
				}
			]
		);

		expect(similar).toEqual([]);
	});
});
