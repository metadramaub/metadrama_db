import { describe, expect, it } from 'vitest';
import {
	defaultRelationFor,
	emptyDeviation,
	metricDeviationRelations,
	METRIC_DEVIATION_DIMENSIONS
} from './sequence-draft';

describe('relaciones con la norma por dimensión', () => {
	it('ofrece solo las que significan algo en cada dimensión', () => {
		const rima = metricDeviationRelations('rima').map((option) => option.value);
		expect(rima).toContain('ruptura');
		// Una rima no tiene tamaño: no es mayor ni menor que la norma.
		expect(rima).not.toContain('menor_que_norma');
		expect(rima).not.toContain('mayor_que_norma');

		const rasgo = metricDeviationRelations('rasgo').map((option) => option.value);
		// Un rasgo está o no está; no se rompe ni se sustituye.
		expect(rasgo).toContain('falta_elemento_esperado');
		expect(rasgo).not.toContain('ruptura');

		const metro = metricDeviationRelations('metro').map((option) => option.value);
		expect(metro).toContain('menor_que_norma');
		expect(metro).not.toContain('ruptura');
	});

	it('deja «Otra» disponible en todas, para lo que no encaje', () => {
		for (const dimension of METRIC_DEVIATION_DIMENSIONS) {
			const values = metricDeviationRelations(dimension.value).map((option) => option.value);
			expect(values).toContain('otra');
			expect(values.length).toBeGreaterThan(1);
		}
	});

	it('conserva la relación al cambiar de dimensión si sigue aplicando', () => {
		expect(defaultRelationFor('estructura', 'diferente')).toBe('diferente');
	});

	it('sustituye la relación que deja de aplicar en la dimensión nueva', () => {
		// «Ruptura» vale en rima, pero no en metro.
		const siguiente = defaultRelationFor('metro', 'ruptura');
		expect(siguiente).not.toBe('ruptura');
		expect(metricDeviationRelations('metro').map((option) => option.value)).toContain(siguiente);
	});

	it('la desviación nueva nace con una relación válida para su dimensión', () => {
		const deviation = emptyDeviation(10, 14);
		const permitidas = metricDeviationRelations(deviation.dimension).map((option) => option.value);
		expect(permitidas).toContain(deviation.relacion_norma);
	});
});
