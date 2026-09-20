/**
 * Lo que el aplicador lee de la prosa de una persona, y lo que hace con los versos.
 *
 * Se prueba justo esto y no el plan entero: **es donde se puede mentir sin que nadie lo note**. Una
 * renumeración mal leída desplaza la obra completa, y una excepción mal entendida escribe en la
 * estrofa de al lado; lo demás —repartir estrofas, colocar respuestas— falla ruidosamente.
 */

import { describe, expect, it } from 'vitest';
import {
	confirma,
	corregirLaObra,
	leerExcepciones,
	leerLaguna,
	leerRango,
	leerSilabas,
	metroDeSilabas
} from './aplicador.mjs';

describe('leerRango', () => {
	it('lee el rango como se escribe en el informe y como se escribe a mano', () => {
		expect(leerRango('1234–1250')).toEqual({ v_ini: 1234, v_fin: 1250 });
		expect(leerRango('vv. 1234-1250')).toEqual({ v_ini: 1234, v_fin: 1250 });
		expect(leerRango('del 1234 al 1250')).toEqual({ v_ini: 1234, v_fin: 1250 });
	});

	it('no lee lo que no es un rango', () => {
		expect(leerRango('creo que está mal')).toBeNull();
		expect(leerRango('1250–1234')).toBeNull();
		expect(leerRango('')).toBeNull();
	});
});

describe('leerLaguna', () => {
	it('lee el verso y cuántos faltan cuando la frase los nombra', () => {
		expect(leerLaguna('Falta un trozo: en el verso 762 faltan 2 versos')).toEqual({
			desde: 762,
			faltan: 2
		});
		expect(leerLaguna('v. 500, laguna de 4')).toEqual({ desde: 500, faltan: 4 });
	});

	it('no adivina: sin las dos cifras no se renumera nada', () => {
		expect(leerLaguna('hay una laguna por ahí')).toBeNull();
		expect(leerLaguna('faltan dos versos en el verso 762')).toBeNull();
		expect(leerLaguna('en el verso 762')).toBeNull();
		expect(leerLaguna('')).toBeNull();
	});
});

describe('leerExcepciones', () => {
	it('lee las estrofas que se apartan de la respuesta general', () => {
		const { excepciones, ilegibles } = leerExcepciones(
			'191–194: Cruzada · abab; 203–206: Cruzada · abab'
		);
		expect(excepciones).toEqual([
			{ v_ini: 191, v_fin: 194, respuesta: 'Cruzada · abab' },
			{ v_ini: 203, v_fin: 206, respuesta: 'Cruzada · abab' }
		]);
		expect(ilegibles).toEqual([]);
	});

	it('devuelve lo que no entiende en vez de descartarlo en silencio', () => {
		const { excepciones, ilegibles } = leerExcepciones('la tercera es distinta; 203–206: abab');
		expect(excepciones).toHaveLength(1);
		expect(ilegibles).toEqual(['la tercera es distinta']);
	});
});

describe('leerSilabas y metroDeSilabas', () => {
	const metros = [
		{ metro_id: 'oct', nombre: 'Octosílabo', silabas: 8 },
		{ metro_id: 'dod', nombre: 'Dodecasílabo', silabas: 12 },
		{ metro_id: 'dod6', nombre: 'Dodecasílabo compuesto 6 + 6', silabas: 12 }
	];

	it('lee la cifra que el editor da, y solo si es una medida posible', () => {
		expect(leerSilabas('11')).toBe(11);
		expect(leerSilabas('11 sílabas')).toBe(11);
		expect(leerSilabas('once')).toBeNull();
		expect(leerSilabas('')).toBeNull();
	});

	it('se queda con el metro simple y no elige cuando no puede', () => {
		expect(metroDeSilabas(metros, 8).metro_id).toBe('oct');
		expect(metroDeSilabas(metros, 12).metro_id).toBe('dod');
		expect(metroDeSilabas(metros, 9)).toBeNull();
	});
});

describe('confirma', () => {
	it('solo da por confirmado un sí claro', () => {
		expect(confirma({ respuesta: 'Es correcto' })).toBe(true);
		expect(confirma({ respuesta: 'No es así (lo corrijo al lado)' })).toBe(false);
		expect(confirma({ respuesta: 'creo que sí' })).toBeNull();
		expect(confirma(undefined)).toBeNull();
	});
});

describe('corregirLaObra', () => {
	const obra = {
		secuencias: [
			{
				secuencia_id: 'a',
				v_ini: 1,
				v_fin: 100,
				n_versos: 100,
				subtipos: [{ v_ini: 1, v_fin: 5 }],
				caracterizaciones: [],
				respuestas: [{ unidad_v_ini: 1, unidad_v_fin: 5 }]
			},
			{
				secuencia_id: 'b',
				v_ini: 101,
				v_fin: 148,
				n_versos: 48,
				subtipos: [{ v_ini: 101, v_fin: 105 }],
				caracterizaciones: [{ v_ini: 103, v_fin: 103 }],
				respuestas: [{ unidad_v_ini: 101, unidad_v_fin: 105 }]
			},
			{ secuencia_id: 'c', v_ini: 149, v_fin: 200, n_versos: 52 }
		],
		fundibles: []
	};

	it('la laguna crece por el final y lo que viene después se desplaza entero', () => {
		const corregida = corregirLaObra(obra, [
			{ tipo: 'renumerar', secuencia_id: 'b', desde: 103, faltan: 2 }
		]);
		const [a, b, c] = corregida.secuencias;
		expect([a.v_ini, a.v_fin]).toEqual([1, 100]);
		expect([b.v_ini, b.v_fin, b.n_versos]).toEqual([101, 150, 50]);
		expect(b.subtipos[0]).toMatchObject({ v_ini: 101, v_fin: 107 });
		expect([c.v_ini, c.v_fin]).toEqual([151, 202]);
	});

	it('la segunda laguna se cuenta ya con lo que añadió la primera', () => {
		const correcciones = [
			{ tipo: 'renumerar', secuencia_id: 'c', desde: 160, faltan: 1 },
			{ tipo: 'renumerar', secuencia_id: 'b', desde: 103, faltan: 2 }
		];
		const corregida = corregirLaObra(obra, correcciones);
		// El editor localiza la segunda en la numeración que ve hoy, la 160, y cuando le llega el
		// turno esa numeración ya lleva dos versos más.
		expect(correcciones[0].desde_efectivo).toBe(162);
		expect(correcciones[1].desde_efectivo).toBe(103);
		expect(corregida.secuencias[2].v_fin).toBe(203);
	});

	it('un rango corregido manda sobre el desplazamiento', () => {
		const corregida = corregirLaObra(obra, [
			{ tipo: 'rango', secuencia_id: 'c', v_ini: 149, v_fin: 199 }
		]);
		expect(corregida.secuencias[2]).toMatchObject({ v_ini: 149, v_fin: 199, n_versos: 51 });
	});

	it('sin correcciones devuelve la obra tal cual', () => {
		expect(corregirLaObra(obra, [])).toBe(obra);
	});
});
