import { describe, expect, it } from 'vitest';
import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';
import {
	compararFormas,
	laFormaCoincide,
	normalizarBusqueda,
	relevanciaDeForma,
	type OrdenFormas
} from './orden-formas';

function forma(
	nombre: string,
	extra: Partial<PublicFormSummary> = {}
): PublicFormSummary {
	return {
		slug: normalizarBusqueda(nombre).replace(/[^a-z0-9]+/g, '_'),
		nombre,
		definicion: null,
		tipoRegistro: 'forma',
		nivelEstructural: 'estrofa',
		unidadVersos: null,
		arquitecturas: 1,
		tradiciones: [],
		tiposRima: [],
		denominaciones: [],
		...extra
	};
}

const ordenar = (formas: PublicFormSummary[], orden: OrdenFormas, termino = '') =>
	[...formas]
		.filter((f) => laFormaCoincide(f, termino))
		.sort((a, b) => compararFormas(a, b, { orden, termino }))
		.map((f) => f.nombre);

describe('el orden del catálogo de formas', () => {
	const catalogo = [
		forma('Soneto', { unidadVersos: 14, nivelEstructural: 'composicion' }),
		forma('Redondilla', { unidadVersos: 4 }),
		forma('Romance', { unidadVersos: null, nivelEstructural: 'serie' }),
		forma('Pareado', { unidadVersos: 2 }),
		forma('Décima', { unidadVersos: 10 }),
		forma('Silva', { unidadVersos: null, nivelEstructural: 'serie' })
	];

	it('alfabético por defecto, y con las tildes en su sitio', () => {
		expect(ordenar(catalogo, 'alfabetico')).toEqual([
			'Décima',
			'Pareado',
			'Redondilla',
			'Romance',
			'Silva',
			'Soneto'
		]);
	});

	/**
	 * Una serie no tiene número de versos, y tratarla como si midiera cero la pondría delante del
	 * pareado. Van al final, y entre ellas alfabéticas.
	 */
	it('por número de versos, con las series al final', () => {
		expect(ordenar(catalogo, 'versos')).toEqual([
			'Pareado',
			'Redondilla',
			'Décima',
			'Soneto',
			'Romance',
			'Silva'
		]);
	});

	it('por tipo de estructura, de lo más corto a lo más largo', () => {
		expect(ordenar(catalogo, 'nivel')).toEqual([
			'Décima',
			'Pareado',
			'Redondilla',
			'Romance',
			'Silva',
			'Soneto'
		]);
	});
});

describe('el buscador prioriza el nombre', () => {
	/**
	 * El caso que lo motivó: «lira» aparece en el nombre de cinco formas y en la definición de
	 * varias más. Buscarla tiene que dar la lira primero, no la primera por orden alfabético de
	 * todo lo que la mencione.
	 */
	const catalogo = [
		forma('Canción petrarquista', {
			definicion: 'Composición de estancias que combina heptasílabos y endecasílabos, como la lira.'
		}),
		forma('Estancia', { definicion: 'Parte de la canción, emparentada con la lira.' }),
		forma('Lira', { unidadVersos: 5 }),
		forma('Sexteto-lira', { unidadVersos: 6 }),
		forma('Octava real', { denominaciones: ['Lira de ocho'] })
	];

	it('pone el nombre exacto delante de todo', () => {
		expect(ordenar(catalogo, 'alfabetico', 'lira')[0]).toBe('Lira');
	});

	it('después el que empieza igual, después el que lo contiene, y al final la definición', () => {
		expect(ordenar(catalogo, 'alfabetico', 'lira')).toEqual([
			'Lira',
			'Octava real',
			'Sexteto-lira',
			'Canción petrarquista',
			'Estancia'
		]);
	});

	it('encuentra por otro nombre, no solo por el suyo', () => {
		expect(relevanciaDeForma(catalogo[4], 'lira de ocho')).toBe(0);
	});

	it('la relevancia manda sobre el orden elegido', () => {
		// Por versos, la lira (5) iría después del sexteto-lira si el orden mandara; no manda.
		expect(ordenar(catalogo, 'versos', 'lira')[0]).toBe('Lira');
	});

	it('sin término, el orden elegido manda sin estorbos', () => {
		expect(ordenar(catalogo, 'alfabetico')[0]).toBe('Canción petrarquista');
	});

	it('busca sin tildes y sin distinguir caja', () => {
		expect(normalizarBusqueda('Décima')).toBe('decima');
		expect(laFormaCoincide(forma('Décima'), 'decima')).toBe(true);
	});
});
