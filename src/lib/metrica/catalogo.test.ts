import { describe, expect, it } from 'vitest';
import { metricStructuralLevelLabel, nombresRepetidos } from './catalogo';

describe('metricStructuralLevelLabel', () => {
	it('nombra cada nivel con lo que el catálogo enseña', () => {
		expect(metricStructuralLevelLabel('verso')).toBe('Verso');
		expect(metricStructuralLevelLabel('estrofa')).toBe('Estrofa');
		expect(metricStructuralLevelLabel('serie')).toBe('Serie no estrófica');
		expect(metricStructuralLevelLabel('composicion')).toBe('Composición de estructura fija');
	});
});

describe('nombresRepetidos', () => {
	it('no señala nada cuando cada forma tiene su nombre', () => {
		expect(nombresRepetidos([{ nombre: 'Redondilla' }, { nombre: 'Quintilla' }]).size).toBe(0);
	});

	it('señala el nombre que llevan dos formas, como las dos sextinas', () => {
		const repetidos = nombresRepetidos([
			{ nombre: 'Sextina' },
			{ nombre: 'Sexteto' },
			{ nombre: 'Sextina' }
		]);
		expect([...repetidos]).toEqual(['Sextina']);
	});

	// Distingue por nombre exacto: «Sextina real» es otra estrofa y no entra en el reparto.
	it('no confunde un nombre con otro que lo contiene', () => {
		expect(nombresRepetidos([{ nombre: 'Sextina' }, { nombre: 'Sextina real' }]).size).toBe(0);
	});
});
