import { describe, expect, it } from 'vitest';
import { resolveSequenceStructures } from './sequence-structure';

const jornadas = [
	{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 100 },
	{ jornada_id: 'j2', jornada_num: 2, v_ini: 101, v_fin: 200 }
];

const cuadros = [
	{ cuadro_id: 'c1', cuadro_num: 1, jornada_id: 'j1', v_ini: 1, v_fin: 50 },
	{ cuadro_id: 'c2', cuadro_num: 2, jornada_id: 'j1', v_ini: 51, v_fin: 100 },
	{ cuadro_id: 'c3', cuadro_num: 1, jornada_id: 'j2', v_ini: 101, v_fin: 150 },
	{ cuadro_id: 'c4', cuadro_num: 2, jornada_id: 'j2', v_ini: 151, v_fin: 200 }
];

describe('sequence-structure', () => {
	it('resuelve jornada y cuadro para una secuencia simple', () => {
		const resolved = resolveSequenceStructures({
			secuencias: [{ secuencia_id: 's1', v_ini: 10, v_fin: 20 }],
			jornadas,
			cuadros
		});

		expect(resolved[0]?.jornada.label).toBe('Jornada 1');
		expect(resolved[0]?.startingCuadro.label).toBe('Cuadro 1');
		expect(resolved[0]?.endingCuadro.label).toBe('Cuadro 1');
		expect(resolved[0]?.spansMultipleCuadros).toBe(false);
	});

	it('detecta tramos cuando una secuencia cruza cuadros', () => {
		const resolved = resolveSequenceStructures({
			secuencias: [{ secuencia_id: 's1', v_ini: 40, v_fin: 80 }],
			jornadas,
			cuadros
		});

		expect(resolved[0]?.startingCuadro.label).toBe('Cuadro 1');
		expect(resolved[0]?.endingCuadro.label).toBe('Cuadro 2');
		expect(resolved[0]?.spansMultipleCuadros).toBe(true);
		expect(resolved[0]?.tramos.map((tramo) => tramo.label)).toEqual([
			'Cuadro 1 · vv. 40-50',
			'Cuadro 2 · vv. 51-80'
		]);
	});

	it('ordena por versos y conserva el indice visual', () => {
		const resolved = resolveSequenceStructures({
			secuencias: [
				{ secuencia_id: 's2', v_ini: 120, v_fin: 130 },
				{ secuencia_id: 's1', v_ini: 10, v_fin: 20 }
			],
			jornadas,
			cuadros
		});

		expect(resolved.map((item) => item.sequence.secuencia_id)).toEqual(['s1', 's2']);
		expect(resolved.map((item) => item.index)).toEqual([1, 2]);
	});

	it('genera fallbacks si no encuentra jornada o cuadro', () => {
		const resolved = resolveSequenceStructures({
			secuencias: [
				{ secuencia_id: 's1', v_ini: 10, v_fin: 20 },
				{ secuencia_id: 's2', v_ini: 210, v_fin: 220 }
			],
			jornadas,
			cuadros: cuadros.filter((cuadro) => cuadro.cuadro_id !== 'c1')
		});

		expect(resolved[0]?.startingCuadro.label).toBe('Sin cuadro');
		expect(resolved[1]?.jornada.label).toBe('Sin jornada');
		expect(resolved[1]?.startingCuadro.label).toBe('Sin cuadro');
	});
});
