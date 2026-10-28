import { describe, expect, it } from 'vitest';
import { proponerDivision, resumenCuerpo } from './division';

describe('división por el primer verso de la nueva secuencia', () => {
	it('el verso escrito pertenece a la nueva secuencia, sin duplicación ni pérdida', () => {
		expect(proponerDivision(1, 532, 101)).toEqual({
			anterior: { v_ini: 1, v_fin: 100 },
			nueva: { v_ini: 101, v_fin: 532 }
		});
		expect(proponerDivision(101, 532, 201)).toEqual({
			anterior: { v_ini: 101, v_fin: 200 },
			nueva: { v_ini: 201, v_fin: 532 }
		});
	});
	it.each([0, 1, 533, 101.5, NaN])('rechaza el inicio %s antes de crear las partes', (v) => {
		expect(() => proponerDivision(1, 532, v)).toThrow();
	});
	it('permite una parte de un verso pero no divide una secuencia de un verso', () => {
		expect(proponerDivision(10, 11, 11).nueva).toEqual({ v_ini: 11, v_fin: 11 });
		expect(() => proponerDivision(10, 10, 10)).toThrow();
	});
	it('conserva desviaciones y el remate enteros', () => {
		const d = [{ v_ini: 20, v_fin: 22, dimension: 'metro', relacion_norma: 'otra' }];
		expect(() => proponerDivision(1, 30, 21, d)).toThrow(/desviación/);
		expect(() => proponerDivision(1, 30, 30, [], 2)).toThrow(/remate/);
		expect(() => proponerDivision(1, 30, 29, d, 2)).toThrow(/no se separa/);
		expect(proponerDivision(1, 30, 28, d, 2).nueva).toEqual({ v_ini: 28, v_fin: 30 });
	});
	it('explica cuerpo y remate sin alterar el total ni contar dos veces los versos añadidos', () => {
		expect(resumenCuerpo(1418, 1460, 1)).toEqual({
			total: 43,
			cuerpo: 42,
			remate: 1,
			adicionales: 0
		});
		expect(resumenCuerpo(1418, 1460, 0).cuerpo).toBe(43);
		const d = { v_ini: 2666, v_fin: 2666, dimension: 'estructura', relacion_norma: 'sobra' };
		expect(resumenCuerpo(2622, 2754, 0, [d, d])).toEqual({
			total: 133,
			cuerpo: 132,
			remate: 0,
			adicionales: 1
		});
	});
});
