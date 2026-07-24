import { describe, expect, it } from 'vitest';
import {
	analyzeSequenceRangeConsistency,
	analyzeStructureRangeConsistency,
	collectRangeConsistencyIds,
	stateAllowsRangeEditing,
	stateRequiresCompletedReview
} from './range-consistency';

describe('range consistency', () => {
	it('detects inclusive overlaps but accepts consecutive ranges', () => {
		const issues = analyzeSequenceRangeConsistency([
			{ secuencia_id: 'a', v_ini: 1, v_fin: 10 },
			{ secuencia_id: 'b', v_ini: 10, v_fin: 20 },
			{ secuencia_id: 'c', v_ini: 21, v_fin: 30 }
		]);

		expect(issues).toHaveLength(1);
		expect(issues[0]).toMatchObject({ scope: 'secuencias', leftId: 'a', rightId: 'b' });
	});

	it('checks cuadros only within their jornada', () => {
		const issues = analyzeStructureRangeConsistency(
			[
				{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 100 },
				{ jornada_id: 'j2', jornada_num: 2, v_ini: 101, v_fin: 200 }
			],
			[
				{ cuadro_id: 'c1', cuadro_num: 1, jornada_id: 'j1', v_ini: 1, v_fin: 60 },
				{ cuadro_id: 'c2', cuadro_num: 2, jornada_id: 'j1', v_ini: 60, v_fin: 100 },
				{ cuadro_id: 'c3', cuadro_num: 1, jornada_id: 'j2', v_ini: 101, v_fin: 140 }
			]
		);

		expect(issues).toHaveLength(1);
		expect(issues[0]).toMatchObject({ scope: 'cuadros', leftId: 'c1', rightId: 'c2' });
		expect(collectRangeConsistencyIds(issues)).toEqual(new Set(['c1', 'c2']));
	});

	it('detects cuadros left outside their jornada after editing it', () => {
		const issues = analyzeStructureRangeConsistency(
			[{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 50 }],
			[{ cuadro_id: 'c1', cuadro_num: 1, jornada_id: 'j1', v_ini: 1, v_fin: 60 }]
		);

		expect(issues).toHaveLength(1);
		expect(issues[0]).toMatchObject({
			kind: 'out_of_bounds',
			leftId: 'j1',
			rightId: 'c1'
		});
	});

	it('reports every overlapping pair in nested ranges', () => {
		const issues = analyzeSequenceRangeConsistency([
			{ secuencia_id: 'a', v_ini: 1, v_fin: 30 },
			{ secuencia_id: 'b', v_ini: 5, v_fin: 10 },
			{ secuencia_id: 'c', v_ini: 8, v_fin: 20 }
		]);

		expect(issues).toHaveLength(3);
	});

	it('requires consistency only for editorial exit states', () => {
		expect(stateRequiresCompletedReview('borrador')).toBe(false);
		expect(stateRequiresCompletedReview('vista_previa')).toBe(true);
		expect(stateRequiresCompletedReview('listo_para_publicar')).toBe(true);
		expect(stateRequiresCompletedReview('Publicado')).toBe(true);
	});

	it('allows range editing only in draft state', () => {
		expect(stateAllowsRangeEditing('Borrador')).toBe(true);
		expect(stateAllowsRangeEditing('vista_previa')).toBe(false);
		expect(stateAllowsRangeEditing('publicado')).toBe(false);
	});

	it('does not treat gaps between sequences as errors', () => {
		expect(
			analyzeSequenceRangeConsistency([
				{ secuencia_id: 'a', v_ini: 1, v_fin: 10 },
				{ secuencia_id: 'b', v_ini: 12, v_fin: 20 }
			])
		).toEqual([]);
	});
});
