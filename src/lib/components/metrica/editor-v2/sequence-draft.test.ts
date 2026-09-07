import { describe, expect, it } from 'vitest';
import {
	defaultRelationFor,
	emptyDeviation,
	metricDeviationRelations,
	METRIC_DEVIATION_DIMENSIONS
} from './sequence-draft';

describe('vocabulario de las desviaciones', () => {
	it('no ofrece la dimensión retirada', () => {
		const dimensiones = METRIC_DEVIATION_DIMENSIONS.map((d) => d.value);
		expect(dimensiones).toEqual(['metro', 'rima', 'estructura', 'repeticion', 'rasgo']);
	});

	it('ofrece solo las relaciones que significan algo en cada dimensión', () => {
		// Una rima no tiene tamaño, y «es otro esquema» ya es una respuesta: solo queda «otra».
		expect(metricDeviationRelations('rima').map((option) => option.value)).toEqual(['otra']);

		const rasgo = metricDeviationRelations('rasgo').map((option) => option.value);
		// Un rasgo está o no está; no tiene tamaño.
		expect(rasgo).toContain('falta');
		expect(rasgo).toContain('sobra');
		expect(rasgo).not.toContain('menor_que_norma');
	});

	it('el metro solo puede quedarse corto o pasarse', () => {
		const metro = metricDeviationRelations('metro').map((option) => option.value);
		expect(metro).toEqual(['menor_que_norma', 'mayor_que_norma', 'otra']);
	});

	/**
	 * **Lo que se retiró el 7 de septiembre de 2026, y que no vuelva.**
	 *
	 * `diferente` describía un valor que el catálogo no tiene, y eso no es una desviación de la obra
	 * sino una falta del catálogo. Y el estribillo que vuelve con menos versos es «se repite solo en
	 * parte», que es una respuesta. La base rechaza las dos cosas; esto vigila que el formulario no
	 * las ofrezca.
	 */
	it('no ofrece las relaciones retiradas', () => {
		for (const dimension of METRIC_DEVIATION_DIMENSIONS) {
			const values = metricDeviationRelations(dimension.value).map((option) => option.value);
			expect(values).not.toContain('diferente');
		}
		const repeticion = metricDeviationRelations('repeticion').map((option) => option.value);
		expect(repeticion).toEqual(['falta', 'sobra', 'otra']);
	});

	it('deja «Otra» disponible en todas, para lo que no encaje', () => {
		for (const dimension of METRIC_DEVIATION_DIMENSIONS) {
			const values = metricDeviationRelations(dimension.value).map((option) => option.value);
			expect(values).toContain('otra');
		}
	});

	it('conserva la relación al cambiar de dimensión si sigue aplicando', () => {
		expect(defaultRelationFor('estructura', 'sobra')).toBe('sobra');
	});

	it('vacía la relación que deja de aplicar, en vez de elegir otra por el editor', () => {
		// «Falta» vale en estructura, pero no en metro; y cambiar de dimensión no dice nada sobre la
		// relación, así que se queda sin elegir en lugar de saltar a la primera de la lista.
		expect(defaultRelationFor('metro', 'falta')).toBe('');
	});

	it('la desviación nueva no afirma nada: ni dimensión ni relación', () => {
		const deviation = emptyDeviation(10, 14);
		expect(deviation.dimension).toBe('');
		expect(deviation.relacion_norma).toBe('');
		// Y sin dimensión no hay relaciones que ofrecer: primero se dice de qué habla.
		expect(metricDeviationRelations(deviation.dimension)).toEqual([]);
	});

	it('nace acotada al primer verso, no a la secuencia entera', () => {
		const deviation = emptyDeviation(10, 14);
		expect([deviation.v_ini, deviation.v_fin]).toEqual([10, 10]);
	});

	it('la desviación nueva nace sin valor observado', () => {
		const deviation = emptyDeviation(10, 14);
		expect(deviation.metro_observado_id).toBeNull();
		expect(deviation.esquema_rima_observado_id).toBeNull();
		expect(deviation.seccion_observada_id).toBeNull();
		expect(deviation.repeticion_observada_id).toBeNull();
		expect(deviation.valor_rasgo_observado_id).toBeNull();
	});
});
