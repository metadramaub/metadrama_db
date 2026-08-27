import { describe, expect, it } from 'vitest';
import type { MetricUnitDraft } from './editor-model';
import { metricStructureCoverage } from './structure-coverage';

function unit(
	id: string,
	start: number,
	end: number,
	parent: string | null = null
): MetricUnitDraft {
	return {
		realizacion_id: id,
		realizacion_padre_id: parent,
		seccion_id: null,
		orden: 1,
		v_ini: start,
		v_fin: end,
		etiqueta: '',
		observaciones: ''
	};
}

describe('metricStructureCoverage', () => {
	it('detecta una cobertura completa de varias estrofas fijas', () => {
		expect(
			metricStructureCoverage(116, 140, [
				unit('q1', 116, 120),
				unit('q2', 121, 125),
				unit('q3', 126, 130),
				unit('q4', 131, 135),
				unit('q5', 136, 140)
			])
		).toEqual({ declaredVerses: 25, coveredVerses: 25, difference: 0, state: 'complete' });
	});

	it('avisa de versos sin distribuir sin mover el final declarado', () => {
		expect(metricStructureCoverage(116, 130, [unit('c1', 116, 120), unit('c2', 121, 125)]))
			.toMatchObject({ declaredVerses: 15, coveredVerses: 10, difference: -5, state: 'missing' });
	});

	it('avisa cuando las unidades rebasan el rango y no suma sus secciones hijas', () => {
		expect(
			metricStructureCoverage(116, 124, [
				unit('root', 116, 125),
				unit('part', 116, 120, 'root')
			])
		).toMatchObject({ declaredVerses: 9, coveredVerses: 10, difference: 1, state: 'overflow' });
	});
});
