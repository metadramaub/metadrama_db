import { describe, expect, it } from 'vitest';
import { bandaDeCuadros, vieneDeAntes, type CuadroRango } from './banda-de-cuadros';

/** Tres cuadros: el segundo abre en el 100 y el tercero en el 220. */
const CUADROS: CuadroRango[] = [
	{ numero: 1, v_ini: 1, v_fin: 99 },
	{ numero: 2, v_ini: 100, v_fin: 219 },
	{ numero: 3, v_ini: 220, v_fin: 400 }
];

describe('bandaDeCuadros', () => {
	it('una fila dentro de un cuadro es un solo tramo entero', () => {
		expect(bandaDeCuadros(120, 160, CUADROS)).toEqual([
			{ numero: 2, desde: 0, alto: 1, abre: false, verso: 100 }
		]);
	});

	it('una fila que arranca donde arranca el cuadro lo declara abierto', () => {
		const banda = bandaDeCuadros(100, 140, CUADROS);
		expect(banda).toHaveLength(1);
		expect(banda[0]).toMatchObject({ numero: 2, abre: true });
	});

	it('**parte la fila en la proporción del corte**, que es lo único que hay que medir', () => {
		// La fila va del 80 al 119: 40 versos. El cuadro 2 abre en el 100, o sea a la mitad.
		const banda = bandaDeCuadros(80, 119, CUADROS);
		expect(banda).toEqual([
			{ numero: 1, desde: 0, alto: 0.5, abre: false, verso: 1 },
			{ numero: 2, desde: 0.5, alto: 0.5, abre: true, verso: 100 }
		]);
	});

	it('aguanta dos cortes dentro de la misma fila', () => {
		// Del 90 al 289: 200 versos. El 2 abre en el 100 y el 3 en el 220.
		const banda = bandaDeCuadros(90, 289, CUADROS);
		expect(banda.map((t) => [t.numero, t.desde, t.alto])).toEqual([
			[1, 0, 0.05],
			[2, 0.05, 0.6],
			[3, 0.65, 0.35]
		]);
	});

	it('los altos suman la fila entera', () => {
		for (const [ini, fin] of [
			[1, 400],
			[80, 119],
			[90, 289],
			[221, 300]
		]) {
			const suma = bandaDeCuadros(ini, fin, CUADROS).reduce((t, x) => t + x.alto, 0);
			expect(suma).toBeCloseTo(1, 10);
		}
	});

	it('un pasaje fuera de todo cuadro da un tramo sin número', () => {
		expect(bandaDeCuadros(500, 520, CUADROS)).toEqual([
			{ numero: null, desde: 0, alto: 1, abre: false, verso: null }
		]);
	});

	it('sin cuadros no hay banda que dibujar, pero tampoco error', () => {
		expect(bandaDeCuadros(1, 10, [])).toEqual([
			{ numero: null, desde: 0, alto: 1, abre: false, verso: null }
		]);
	});

	it('un rango vacío no devuelve nada', () => {
		expect(bandaDeCuadros(10, 9, CUADROS)).toEqual([]);
	});
});

describe('vieneDeAntes', () => {
	it('distingue el cuadro que sigue del que abre, para no repetir el número', () => {
		expect(vieneDeAntes(bandaDeCuadros(120, 160, CUADROS))).toBe(true);
		expect(vieneDeAntes(bandaDeCuadros(100, 140, CUADROS))).toBe(false);
	});
});
