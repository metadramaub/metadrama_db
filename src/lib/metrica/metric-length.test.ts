import { describe, expect, it } from 'vitest';
import type { MetricLengthRule } from '$lib/metrica/catalogo';
import {
	inclusiveMetricLength,
	isMetricLengthCompatible,
	metricLengthError
} from './metric-length';

function rule(
	modulo_versos: number,
	residuo_versos: number,
	minimo_versos: number
): MetricLengthRule {
	return {
		arquitectura_id: 'configuracion',
		arquitectura_nombre: 'Configuración',
		modulo_versos,
		residuo_versos,
		minimo_versos,
		origen: 'unidad',
		explicacion: `unidades de ${modulo_versos} versos`
	};
}

describe('metric length validation', () => {
	it('calcula rangos inclusivos', () => {
		expect(inclusiveMetricLength(1, 5)).toBe(5);
		expect(inclusiveMetricLength(12, 11)).toBe(0);
	});

	it('valida formas repetidas de tamaño fijo', () => {
		const quintilla = rule(5, 0, 5);
		expect(isMetricLengthCompatible(quintilla, 1, 45)).toBe(true);
		expect(isMetricLengthCompatible(quintilla, 1, 48)).toBe(false);
	});

	it('valida ciclos pares del romance', () => {
		const romance = rule(2, 0, 2);
		expect(isMetricLengthCompatible(romance, 10, 19)).toBe(true);
		expect(isMetricLengthCompatible(romance, 10, 20)).toBe(false);
	});

	it('admite un resto estructural, como el cierre del terceto encadenado', () => {
		const tercetoEncadenado = rule(3, 1, 4);
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 10)).toBe(true);
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 9)).toBe(false);
	});

	it('explica cómo resolver una incompatibilidad sin permitir ignorarla', () => {
		const message = metricLengthError(rule(4, 0, 4), 116, 124, 'Simple', 'Seguidilla');
		expect(message).toContain('«Seguidilla · Simple» exige');
		expect(message).toContain('9 versos');
		expect(message).toContain('fuente presenta una laguna');
	});
});
