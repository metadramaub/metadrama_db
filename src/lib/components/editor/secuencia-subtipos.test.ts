import { describe, expect, it } from 'vitest';
import { suggestNextSubtipoRange } from './secuencia-subtipos';

describe('suggestNextSubtipoRange', () => {
	it('sugiere los primeros cinco versos cuando no hay subtipos previos', () => {
		expect(suggestNextSubtipoRange({ v_ini: 100, v_fin: 119 }, [])).toEqual({
			available: true,
			v_ini: 100,
			v_fin: 104
		});
	});

	it('continua en el verso siguiente al subtipo anterior', () => {
		expect(suggestNextSubtipoRange({ v_ini: 100, v_fin: 119 }, [{ v_ini: 100, v_fin: 104 }])).toEqual({
			available: true,
			v_ini: 105,
			v_fin: 109
		});
	});

	it('usa el mayor v_fin aunque los subtipos lleguen desordenados', () => {
		const subtipos = [
			{ v_ini: 110, v_fin: 114 },
			{ v_ini: 100, v_fin: 104 },
			{ v_ini: 105, v_fin: 109 }
		];

		expect(suggestNextSubtipoRange({ v_ini: 100, v_fin: 119 }, subtipos)).toEqual({
			available: true,
			v_ini: 115,
			v_fin: 119
		});
	});

	it('marca que no quedan versos disponibles cuando el ultimo subtipo llega al final', () => {
		expect(suggestNextSubtipoRange({ v_ini: 100, v_fin: 119 }, [{ v_ini: 115, v_fin: 119 }])).toEqual({
			available: false,
			v_ini: 120,
			v_fin: 119
		});
	});

	it('limita el verso final sugerido al fin de la secuencia', () => {
		expect(suggestNextSubtipoRange({ v_ini: 100, v_fin: 112 }, [{ v_ini: 100, v_fin: 109 }])).toEqual({
			available: true,
			v_ini: 110,
			v_fin: 112
		});
	});
});
