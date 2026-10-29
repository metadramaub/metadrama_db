import { describe, expect, it } from 'vitest';
import { corpusCompatible, type ReadableCorpus } from './corpus-compat';

describe('compatibilidad del corpus durante el cambio de prosa', () => {
	it('conserva las medidas válidas de V2 y omite su extensión ficticia de prosa', () => {
		const canto = { versos: 6, proporcion_versos: 0.06, formas: ['romance'] };
		const anterior = {
			schema_version: 2,
			obras: [{ obra_id: 'obra', enunciacion: { cantado: canto, prosa: { versos: 2 } } }],
			enunciacion: { prosa: { proporcion_versos: { mediana: 0.02 } } }
		} as unknown as ReadableCorpus;
		const actual = corpusCompatible(anterior);
		expect(actual?.obras[0].enunciacion).toEqual({ cantado: canto });
		expect(actual?.enunciacion).not.toHaveProperty('prosa');
		expect(anterior.enunciacion).toHaveProperty('prosa');
	});

	it('sirve V3 conservando presencia y referencias entre versos', () => {
		const actual = {
			schema_version: 3,
			obras: [
				{
					enunciacion: {
						prosa: {
							presente: true,
							localizaciones: [{ v_anterior: 56, v_posterior: 57 }],
							formas: ['romance']
						}
					}
				}
			],
			enunciacion: {
				prosa: { obras_con_anotacion: 1, obras_analizables: 2, proporcion_obras: 0.5 }
			}
		} as unknown as ReadableCorpus;
		expect(corpusCompatible(actual)).toBe(actual);
	});
});
