import { describe, expect, it } from 'vitest';
import {
	arePositionalOptions,
	haveAlternativesByPosition,
	isPartialPositionalSelection,
	shortPositionOptionLabel
} from './positional-options';

const alternatives = [
	{ posicion_unidad: 1, nombre: 'Verso 1 · Tetrasílabo', metro_silabas: 4 },
	{ posicion_unidad: 1, nombre: 'Verso 1 · Pentasílabo', metro_silabas: 5 },
	{ posicion_unidad: 2, nombre: 'Verso 2 · Tetrasílabo', metro_silabas: 4 },
	{ posicion_unidad: 2, nombre: 'Verso 2 · Pentasílabo', metro_silabas: 5 }
];

describe('opciones métricas por posición', () => {
	it('distingue las alternativas posicionales de una lista ordinaria', () => {
		expect(arePositionalOptions(alternatives)).toBe(true);
		expect(haveAlternativesByPosition(alternatives)).toBe(true);
		expect(arePositionalOptions([{ nombre: 'Octosílabo' }])).toBe(false);
	});

	it('trata los quebrados como posiciones parciales, no como medida de todos los versos', () => {
		expect(
			isPartialPositionalSelection(
				{ define_norma: false, selecciones_min: 1, selecciones_max: 12 },
				alternatives
			)
		).toBe(true);
		expect(
			isPartialPositionalSelection(
				{ define_norma: true, selecciones_min: 5, selecciones_max: 20 },
				alternatives
			)
		).toBe(false);
		expect(
			isPartialPositionalSelection(
				{ define_norma: false, selecciones_min: 2, selecciones_max: 2 },
				alternatives
			)
		).toBe(false);
	});

	it('muestra la medida en sílabas sin repetir el nombre del verso', () => {
		expect(shortPositionOptionLabel(alternatives[0], 1)).toBe('4');
		expect(
			shortPositionOptionLabel({ nombre: 'Verso 3 · Decasílabo' }, 3)
		).toBe('Decasílabo');
	});
});
