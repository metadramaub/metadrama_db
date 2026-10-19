import { describe, expect, it } from 'vitest';
import { formasDeFilas, rotulosDeFila } from './diagrama-exportacion';
import type { FilaDeBarras } from './MetricBarcodeFigura.svelte';

const fila: FilaDeBarras = {
	etiqueta: 'Jornada 2', desde: 1001, hasta: 2000,
	segmentos: [
		{ id: 'a', forma: 'Romance', v_ini: 950, v_fin: 1100, label: '' },
		{ id: 'b', forma: 'Silva', v_ini: 1101, v_fin: 1102, label: '' },
		{ id: 'c', forma: 'Romance', v_ini: 1103, v_fin: 2000, label: '' },
		{ id: 'd', forma: 'Soneto', v_ini: 2001, v_fin: 2014, label: '' }
	]
};

describe('leyenda del diagrama exportado', () => {
	it('incluye solo formas visibles por primera aparición y reutiliza su número', () => {
		expect(formasDeFilas([{ ...fila, segmentos: [...fila.segmentos].reverse() }])).toEqual([
			{ clave: 'Romance', forma: 'Romance', numero: 1 },
			{ clave: 'Silva', forma: 'Silva', numero: 2 }
		]);
	});
	it('mantiene la numeración entre varias jornadas de una misma imagen', () => {
		const tercera = { ...fila, desde: 2001, hasta: 2100 };
		expect(formasDeFilas([fila, tercera]).map((f) => f.forma)).toEqual(['Romance', 'Silva', 'Soneto']);
	});
});

describe('rótulos en blanco y negro', () => {
	it('conserva el centro exacto de cada tramo y recorta el que cruza el inicio', () => {
		const { items } = rotulosDeFila(fila, 1000, false);
		expect(items).toHaveLength(3);
		expect(items[0].origen).toBe(50);
		expect(items[1].origen).toBe(101);
	});
	it.each([false, true])('separa las etiquetas de pasajes próximos y las mantiene dentro del ancho (%s)', (numeros) => {
		const densa = { ...fila, segmentos: Array.from({ length: 90 }, (_, i) => ({
			id: String(i), forma: 'Endecasílabo encadenado', label: '', v_ini: 1100 + i, v_fin: 1100 + i
		})) };
		const { items, alto } = rotulosDeFila(densa, 834, numeros);
		for (const item of items) {
			expect(item.x).toBeGreaterThanOrEqual(0);
			expect(item.x).toBeLessThan(834);
			expect(item.y).toBeLessThan(alto);
		}
		for (const y of new Set(items.map((item) => item.y))) {
			const nivel = items.filter((item) => item.y === y);
			for (let i = 1; i < nivel.length; i++) expect(nivel[i].x - nivel[i - 1].x).toBeGreaterThanOrEqual(20);
		}
	});
});
