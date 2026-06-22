import { describe, expect, it } from 'vitest';
import { distanciaComposicional, distanciaSecuencial } from './distancias';

describe('distancias metricas provisionales', () => {
	it('devuelve 0 para perfiles composicionales identicos', () => {
		expect(distanciaComposicional({ romance: 80, redondilla: 20 }, { romance: 80, redondilla: 20 })).toBe(0);
	});

	it('devuelve una distancia composicional cercana a 1 cuando no hay formas comunes', () => {
		expect(distanciaComposicional({ romance: 100 }, { redondilla: 100 })).toBeCloseTo(1, 8);
	});

	it('captura duraciones invertidas en secuencias con las mismas formas', () => {
		const a = [
			{ i: 1, f: 800, s: 'romance', t: null },
			{ i: 801, f: 840, s: 'redondilla', t: null }
		];
		const b = [
			{ i: 1, f: 40, s: 'romance', t: null },
			{ i: 41, f: 840, s: 'redondilla', t: null }
		];

		expect(distanciaSecuencial(a, b, 25)).toBeGreaterThan(0.5);
	});
});
