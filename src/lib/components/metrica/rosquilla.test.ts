import { describe, expect, it } from 'vitest';
import { ANGULO_MINIMO, sectoresDeRosquilla, posicionRotuloDeRosquilla } from './rosquilla';

const amplitudes = (valores: number[]) =>
	sectoresDeRosquilla(valores).map((sector) => sector.fin - sector.inicio);

describe('sectoresDeRosquilla', () => {
	it('reparte en proporción cuando todos pasan del mínimo', () => {
		const [a, b] = amplitudes([3, 1]);
		expect(a / b).toBeCloseTo(3);
		expect(a + b).toBeCloseTo(Math.PI * 2);
	});

	it('sube al mínimo lo que no llega, y la vuelta sigue cerrando', () => {
		const partes = amplitudes([3000, 5, 1]);
		expect(partes[1]).toBeCloseTo(ANGULO_MINIMO);
		expect(partes[2]).toBeCloseTo(ANGULO_MINIMO);
		expect(partes.reduce((a, b) => a + b, 0)).toBeCloseTo(Math.PI * 2);
	});

	it('los sectores van seguidos, sin huecos ni solapes', () => {
		const sectores = sectoresDeRosquilla([10, 0, 4, 1]);
		for (let i = 1; i < sectores.length; i += 1) {
			expect(sectores[i].inicio).toBeCloseTo(sectores[i - 1].fin);
		}
		expect(sectores[1].fin - sectores[1].inicio).toBe(0);
	});

	it('conserva el orden de tamaños entre los que no se tocan', () => {
		const partes = amplitudes([50, 30, 20, 0.1]);
		expect(partes[0]).toBeGreaterThan(partes[1]);
		expect(partes[1]).toBeGreaterThan(partes[2]);
	});

	it('sin nada que repartir, todo vacío', () => {
		expect(amplitudes([0, 0])).toEqual([0, 0]);
	});
	it('con mínimo cero conserva incluso las proporciones de los sectores pequeños', () => {
		const sectores = sectoresDeRosquilla([3000, 5, 1], 0);
		expect((sectores[1].fin - sectores[1].inicio) / (Math.PI * 2)).toBeCloseTo(5 / 3006);
		expect((sectores[2].fin - sectores[2].inicio) / (Math.PI * 2)).toBeCloseTo(1 / 3006);
	});
});

describe('números interiores del perfil', () => {
	it('omite el número cuando no cabe en un sector pequeño', () => {
		expect(posicionRotuloDeRosquilla({ inicio: 0, fin: 0.05 }, 280, '12')).toBeNull();
	});
	it('sitúa el número en el centro del anillo y del sector', () => {
		const posicion = posicionRotuloDeRosquilla({ inicio: 0, fin: Math.PI }, 280, '1');
		expect(posicion?.x).toBeCloseTo(140 * 0.59);
		expect(posicion?.y).toBeCloseTo(0);
	});
	it('comprueba el espacio para todas las cifras del identificador', () => {
		const sector = { inicio: 0, fin: 0.24 };
		expect(posicionRotuloDeRosquilla(sector, 280, '1')).not.toBeNull();
		expect(posicionRotuloDeRosquilla(sector, 280, '12')).toBeNull();
	});
});
