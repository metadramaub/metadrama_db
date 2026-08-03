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
		const rima = metricDeviationRelations('rima').map((option) => option.value);
		expect(rima).toContain('diferente');
		// Una rima no tiene tamaño: no es mayor ni menor que la norma.
		expect(rima).not.toContain('menor_que_norma');
		expect(rima).not.toContain('mayor_que_norma');

		const rasgo = metricDeviationRelations('rasgo').map((option) => option.value);
		// Un rasgo está o no está; no tiene tamaño.
		expect(rasgo).toContain('falta');
		expect(rasgo).toContain('sobra');
		expect(rasgo).not.toContain('menor_que_norma');
	});

	it('el metro solo puede sobrar o faltar, nunca «ser otro»', () => {
		const metro = metricDeviationRelations('metro').map((option) => option.value);
		expect(metro).toEqual(['menor_que_norma', 'mayor_que_norma', 'otra']);
		// Cuál es exactamente se dice en el metro observado, no en la relación.
		expect(metro).not.toContain('diferente');
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
		// «Falta» vale en estructura, pero no en metro.
		const siguiente = defaultRelationFor('metro', 'falta');
		expect(siguiente).not.toBe('falta');
		expect(metricDeviationRelations('metro').map((option) => option.value)).toContain(siguiente);
	});

	it('la desviación nueva nace con una relación que la base acepta', () => {
		const deviation = emptyDeviation(10, 14);
		const permitidas = metricDeviationRelations(deviation.dimension).map((option) => option.value);
		expect(permitidas).toContain(deviation.relacion_norma);
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
