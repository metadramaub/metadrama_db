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
	minimo_versos: number,
	desplazamientos: number[] = [0]
): MetricLengthRule {
	return {
		arquitectura_id: 'configuracion',
		arquitectura_nombre: 'Configuración',
		modulo_versos,
		residuo_versos,
		minimo_versos,
		origen: 'unidad',
		explicacion: `unidades de ${modulo_versos} versos`,
		desplazamientos
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

	it('admite un resto estructural obligatorio', () => {
		const conCierreFijo = rule(3, 1, 4);
		expect(isMetricLengthCompatible(conCierreFijo, 1, 10)).toBe(true);
		expect(isMetricLengthCompatible(conCierreFijo, 1, 9)).toBe(false);
	});

	/**
	 * El caso que motivó los desplazamientos. El serventesio del terceto encadenado dejó de ser
	 * obligatorio el 19 de agosto de 2026, de modo que la cadena mide `3n` **o** `3n+4`, y un solo
	 * par de módulo y residuo solo puede expresar una de las dos. Antes del arreglo la regla decía
	 * `3n` y el editor rechazaba con un 422 toda cadena terminada en serventesio.
	 */
	it('admite un cierre opcional, que son dos congruencias y no una', () => {
		const tercetoEncadenado = rule(3, 0, 3, [0, 4]);
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 66)).toBe(true); // 22 tercetos
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 67)).toBe(true); // 21 y serventesio
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 7)).toBe(true); // uno y serventesio
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 3)).toBe(true); // uno suelto
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 68)).toBe(false); // ni una cosa ni otra
		// Y el mínimo se cuenta sobre el ciclo, no sobre el total: un serventesio suelto, sin
		// ninguna cadena delante, no es la forma.
		expect(isMetricLengthCompatible(tercetoEncadenado, 1, 4)).toBe(false);
	});

	it('trata una regla sin desplazamientos como si trajera solo el cero', () => {
		const sinDeclarar = { ...rule(4, 0, 4), desplazamientos: [] as number[] };
		expect(isMetricLengthCompatible(sinDeclarar, 1, 8)).toBe(true);
		expect(isMetricLengthCompatible(sinDeclarar, 1, 9)).toBe(false);
	});

	it('explica cómo resolver una incompatibilidad sin permitir ignorarla', () => {
		const message = metricLengthError(rule(4, 0, 4), 116, 124, 'Simple', 'Seguidilla');
		expect(message).toContain('«Seguidilla · Simple» exige');
		expect(message).toContain('9 versos');
		expect(message).toContain('fuente presenta una laguna');
	});
});

describe('la unidad que declara su propia arquitectura', () => {
	/**
	 * B5. Una tirada de décimas con una aumentada intercalada mide `10n + 2`, y la décima declara
	 * módulo 10. La congruencia es una guarda para cuando el editor **deriva** cuántas unidades hay
	 * dividiendo el rango; con una excepción deja de derivarlas, y gobierna la cobertura.
	 *
	 * Antes de esto, cinco décimas y una aumentada —62 versos— devolvían un 422 y no se podían
	 * guardar. El catálogo sostiene que no es un error: lo dicen su descripción y Morley y Bruerton.
	 */
	it('no exige la congruencia cuando hay una arquitectura intercalada', () => {
		const decima = rule(10, 0, 10);
		expect(isMetricLengthCompatible(decima, 1, 62)).toBe(false);
		expect(isMetricLengthCompatible(decima, 1, 62, true)).toBe(true);
		expect(metricLengthError(decima, 1, 62, 'Espinela', 'Décima', true)).toBeNull();
	});

	it('sigue exigiéndola cuando todas las unidades son de la secuencia', () => {
		const decima = rule(10, 0, 10);
		expect(isMetricLengthCompatible(decima, 1, 60)).toBe(true);
		expect(isMetricLengthCompatible(decima, 1, 62)).toBe(false);
		expect(metricLengthError(decima, 1, 62, 'Espinela', 'Décima')).toContain('62 versos');
	});
});
