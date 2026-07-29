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
		configuracion_id: 'configuracion',
		configuracion_nombre: 'Configuración',
		modulo_versos,
		residuo_versos,
		minimo_versos,
		origen: 'numero_versos',
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
		const message = metricLengthError(rule(14, 0, 14), 1, 13, 'Soneto');
		expect(message).toContain('13 versos');
		expect(message).toContain('fuente presenta una laguna');
	});
});
