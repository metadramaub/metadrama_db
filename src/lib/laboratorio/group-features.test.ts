import { describe, expect, it } from 'vitest';
import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';
import { buildFormGroupComparisons, buildTransitionGroupComparisons } from './group-features';

function work(
	id: string,
	forms: CorpusComparisonWork['perfil_formas'],
	transitions: CorpusComparisonWork['transiciones'] = []
): CorpusComparisonWork {
	return {
		obra_id: id,
		slug: id,
		titulo: `Obra ${id}`,
		perfil_formas: forms,
		transiciones: transitions
	} as CorpusComparisonWork;
}

describe('comparación de formas por grupos', () => {
	it('separa difusión y peso condicionado a las obras que usan la forma', () => {
		const groupA = [
			work('a1', {
				romance: {
					tipo_forma: 'estrofica',
					versos: 50,
					secuencias: 2,
					proporcion_versos: 0.5,
					longitud_media_secuencia: 25
				}
			}),
			work('a2', {})
		];
		const groupB = [
			work('b1', {
				romance: {
					tipo_forma: 'estrofica',
					versos: 20,
					secuencias: 1,
					proporcion_versos: 0.2,
					longitud_media_secuencia: 20
				}
			})
		];

		const romance = buildFormGroupComparisons(groupA, groupB).find((row) => row.id === 'romance');
		expect(romance?.groupA.diffusion).toBe(0.5);
		expect(romance?.groupA.typical).toBe(0.5);
		expect(romance?.groupA.valueWorks).toBe(1);
		expect(romance?.groupB.diffusion).toBe(1);
		expect(romance?.groupB.typical).toBe(0.2);
	});
});

describe('comparación de transiciones por grupos', () => {
	it('usa una obra una vez en difusión y la mediana de apariciones donde existe', () => {
		const groupA = [
			work('a1', {}, [
				{ de: 'decima', a: 'romance', veces: 1 },
				{ de: 'decima', a: 'romance', veces: 2 }
			]),
			work('a2', {}, [{ de: 'decima', a: 'romance', veces: 5 }])
		];
		const groupB = [work('b1', {})];

		const transition = buildTransitionGroupComparisons(groupA, groupB)[0];
		expect(transition.groupA.presentWorks).toBe(2);
		expect(transition.groupA.diffusion).toBe(1);
		expect(transition.groupA.typical).toBe(4);
		expect(transition.groupB.diffusion).toBe(0);
		expect(transition.groupB.typical).toBeNull();
	});
});
