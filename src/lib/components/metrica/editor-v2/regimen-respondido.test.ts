import { describe, expect, it } from 'vitest';
import { preguntaAplica, tiposDeRimaAfirmados } from './regimen-respondido';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

const ASONANTE = 't-aso';
const CONSONANTE = 't-con';

const groups = [
	{ grupo_eleccion_id: 'g-rima', dimension: 'rima' },
	{ grupo_eleccion_id: 'g-vocales', dimension: 'rasgo', solo_si_tipo_rima_id: ASONANTE },
	{ grupo_eleccion_id: 'g-final', dimension: 'rasgo' }
] as unknown as MetricCatalogDomainRow[];

const options = [
	{ opcion_eleccion_id: 'o-consonante', grupo_eleccion_id: 'g-rima', esquema_rima_id: 'e-con' },
	{ opcion_eleccion_id: 'o-asonante', grupo_eleccion_id: 'g-rima', esquema_rima_id: 'e-aso' },
	{ opcion_eleccion_id: 'o-vocal', grupo_eleccion_id: 'g-vocales', valor_rasgo_id: 'v-ae' }
] as unknown as MetricCatalogDomainRow[];

const rhymePatterns = [
	{ esquema_rima_id: 'e-con', tipo_rima_id: CONSONANTE },
	{ esquema_rima_id: 'e-aso', tipo_rima_id: ASONANTE }
] as unknown as MetricCatalogDomainRow[];

const rhymeTypes = [
	{ id: CONSONANTE, slug: 'consonante' },
	{ id: ASONANTE, slug: 'asonante' }
];

const eleccion = (grupo: string, opcion: string | null, texto: string | null = null) => ({
	grupo_eleccion_id: grupo,
	opcion_eleccion_id: opcion,
	valor_texto: texto
});

const afirmados = (elecciones: ReturnType<typeof eleccion>[]) =>
	tiposDeRimaAfirmados({ elecciones, groups, options, rhymePatterns, rhymeTypes });

const vocales = groups[1];
const finalAcentual = groups[2];

describe('los tipos de rima que afirma lo respondido', () => {
	it('sin responder la rima, no se afirma ninguno', () => {
		expect([...afirmados([])]).toEqual([]);
	});

	it('una disposición del catálogo lleva el suyo', () => {
		expect([...afirmados([eleccion('g-rima', 'o-asonante')])]).toEqual([ASONANTE]);
	});

	it('una tirada con unidades de los dos regímenes afirma los dos', () => {
		expect(
			[...afirmados([eleccion('g-rima', 'o-consonante'), eleccion('g-rima', 'o-asonante')])].sort()
		).toEqual([ASONANTE, CONSONANTE].sort());
	});

	it('un esquema escrito a mano guarda el término detrás del punto medio', () => {
		expect([...afirmados([eleccion('g-rima', null, 'abab · asonante')])]).toEqual([ASONANTE]);
	});

	/** «asonante» es subcadena de «consonante»: buscarlo suelto daría asonante todo lo consonante. */
	it('un esquema escrito consonante no cuenta como asonante', () => {
		expect([...afirmados([eleccion('g-rima', null, 'abab · consonante')])]).toEqual([CONSONANTE]);
	});

	it('un esquema escrito sin régimen no afirma ninguno', () => {
		expect([...afirmados([eleccion('g-rima', null, 'abab')])]).toEqual([]);
	});

	it('no lee las respuestas que no son de rima', () => {
		expect([...afirmados([eleccion('g-vocales', 'o-vocal')])]).toEqual([]);
	});
});

describe('cuándo aplica una pregunta condicionada', () => {
	it('una pregunta sin condición aplica siempre', () => {
		expect(preguntaAplica(finalAcentual, afirmados([]))).toBe(true);
		expect(
			preguntaAplica(finalAcentual, afirmados([eleccion('g-rima', 'o-consonante')]))
		).toBe(true);
	});

	it('las vocales aplican en cuanto algo asuena', () => {
		expect(preguntaAplica(vocales, afirmados([eleccion('g-rima', 'o-asonante')]))).toBe(true);
		expect(
			preguntaAplica(
				vocales,
				afirmados([eleccion('g-rima', 'o-asonante'), eleccion('g-rima', 'o-consonante')])
			)
		).toBe(true);
	});

	it('con la rima consonante no existen', () => {
		expect(preguntaAplica(vocales, afirmados([eleccion('g-rima', 'o-consonante')]))).toBe(false);
	});

	it('no saber no es saber que sí: sin rima respondida, tampoco', () => {
		expect(preguntaAplica(vocales, afirmados([]))).toBe(false);
	});
});
