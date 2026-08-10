import { describe, expect, it } from 'vitest';
import { applyProposedUnitAnswers } from './sequence-draft';
import type { MetricUnitDraft } from './editor-model';

function unit(id: string, overrides: Partial<MetricUnitDraft> = {}): MetricUnitDraft {
	return {
		realizacion_prueba_id: id,
		realizacion_padre_id: null,
		seccion_id: '',
		orden: 1,
		v_ini: 1,
		v_fin: 6,
		etiqueta: '',
		observaciones: '',
		...overrides
	} as MetricUnitDraft;
}

const RESPUESTA = { grupo_eleccion_id: 'g1', opcion_eleccion_id: 'o1' };

describe('applyProposedUnitAnswers', () => {
	it('una pregunta sin sección va a la unidad, no a sus partes', () => {
		const units = [
			unit('u1'),
			unit('parte', { realizacion_padre_id: 'u1', seccion_id: 'sec-a' })
		];
		const result = applyProposedUnitAnswers(units, [], [{ grupo_eleccion_id: 'g1' }], [RESPUESTA]);
		expect(result).toHaveLength(1);
		expect(result[0].realizacion_prueba_id).toBe('u1');
	});

	it('una pregunta anclada en una sección va a las realizaciones de esa sección', () => {
		const units = [
			unit('u1'),
			unit('terceto-1', { realizacion_padre_id: 'u1', seccion_id: 'sec-tercetos' }),
			unit('terceto-2', { realizacion_padre_id: 'u1', seccion_id: 'sec-tercetos' }),
			unit('cuarteto', { realizacion_padre_id: 'u1', seccion_id: 'sec-cuartetos' })
		];
		const groups = [{ grupo_eleccion_id: 'g1', seccion_id: 'sec-tercetos' }];
		const result = applyProposedUnitAnswers(units, [], groups, [RESPUESTA]);
		expect(result.map((choice) => choice.realizacion_prueba_id)).toEqual(['terceto-1', 'terceto-2']);
	});

	/**
	 * `seccion_id` dice dónde se responde y `seccion_tratada_id` de qué trata. Los dos grupos
	 * del soneto hablan de una sección que se realiza dos veces —sus cuartetos, sus tercetos—
	 * pero se responden una sola vez, porque su esquema describe las dos realizaciones a la
	 * vez. Confundirlas haría preguntar dos veces lo mismo.
	 */
	it('una pregunta que habla de una sección pero no se ancla en ella se responde una vez', () => {
		const units = [
			unit('soneto'),
			unit('cuarteto-1', { realizacion_padre_id: 'soneto', seccion_id: 'sec-cuartetos' }),
			unit('cuarteto-2', { realizacion_padre_id: 'soneto', seccion_id: 'sec-cuartetos' })
		];
		const groups = [{ grupo_eleccion_id: 'g1', seccion_tratada_id: 'sec-cuartetos' }];
		const result = applyProposedUnitAnswers(units, [], groups, [RESPUESTA]);
		expect(result.map((choice) => choice.realizacion_prueba_id)).toEqual(['soneto']);
	});

	/**
	 * La propuesta rellena huecos, no corrige. Si el editor ya contestó, lo suyo manda: no
	 * tendría sentido que abrir la secuencia otra vez le deshiciera la respuesta.
	 */
	it('no pisa lo que ya está contestado', () => {
		const units = [unit('u1')];
		const previo = [
			{
				realizacion_prueba_id: 'u1',
				grupo_eleccion_id: 'g1',
				opcion_eleccion_id: 'otra',
				valor_texto: null,
				observaciones: null
			}
		];
		const result = applyProposedUnitAnswers(units, previo, [{ grupo_eleccion_id: 'g1' }], [RESPUESTA]);
		expect(result).toHaveLength(1);
		expect(result[0].opcion_eleccion_id).toBe('otra');
	});

	it('una pregunta que no es de esta arquitectura se ignora', () => {
		const result = applyProposedUnitAnswers([unit('u1')], [], [], [RESPUESTA]);
		expect(result).toHaveLength(0);
	});
});
