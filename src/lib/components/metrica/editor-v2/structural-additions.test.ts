import { describe, expect, it } from 'vitest';
import type { MetricCatalogForEditor } from '$lib/metrica/catalogo';
import { normalizeStructuredUnits } from './sequence-draft';
import { metricStructureCoverage } from './structure-coverage';
import { normativeMetricLength } from '$lib/metrica/metric-length';

const catalog = {
	forms: [{ forma_id: 'redondilla', nivel_estructural: 'estrofa' }],
	configurations: [
		{
			arquitectura_id: 'octosilaba',
			forma_id: 'redondilla',
			unidad_versos_min: 4,
			unidad_versos_max: 4
		}
	],
	domain: { sections: [], choiceGroups: [], choiceOptions: [] }
} as unknown as MetricCatalogForEditor;
const addition = (start: number, end = start) => ({
	v_ini: start,
	v_fin: end,
	dimension: 'estructura',
	relacion_norma: 'sobra'
});

describe('reparto de unidades con adiciones estructurales', () => {
	it('mantiene la posición de una laguna dentro de su estrofa', () => {
		const deviations = [{ ...addition(3), relacion_norma: 'falta' }];
		const units = normalizeStructuredUnits(catalog, [], [], 'octosilaba', 1, 8, deviations);
		expect(units.map(({ v_ini, v_fin }) => [v_ini, v_fin])).toEqual([
			[1, 4],
			[5, 8]
		]);
		expect(metricStructureCoverage(1, 8, units, deviations).state).toBe('complete');
	});
	it('sitúa 11 y 22 redondillas a ambos lados del verso 2666 y cubre los 133 versos', () => {
		const deviations = [addition(2666)];
		const units = normalizeStructuredUnits(catalog, [], [], 'octosilaba', 2622, 2754, deviations);
		expect(units).toHaveLength(33);
		expect(units[10]).toMatchObject({ v_ini: 2662, v_fin: 2665 });
		expect(units[11]).toMatchObject({ v_ini: 2667, v_fin: 2670 });
		expect(units.at(-1)?.v_fin).toBe(2754);
		expect(metricStructureCoverage(2622, 2754, units, deviations).state).toBe('complete');
		expect(
			normalizeStructuredUnits(catalog, units, [], 'octosilaba', 2622, 2754, deviations)
		).toEqual(units);
	});
	it.each([1, 3, 5, 9])('conserva una adición en v. %s sin inventar otra unidad', (position) => {
		const deviations = [addition(position)];
		const units = normalizeStructuredUnits(catalog, [], [], 'octosilaba', 1, 9, deviations);
		expect(units).toHaveLength(2);
		for (const unit of units)
			expect(normativeMetricLength(unit.v_ini, unit.v_fin, deviations)).toBe(4);
		expect(metricStructureCoverage(1, 9, units, deviations)).toMatchObject({
			state: 'complete',
			coveredVerses: 9
		});
		expect(normalizeStructuredUnits(catalog, units, [], 'octosilaba', 1, 9, deviations)).toEqual(
			units
		);
	});
	it('conserva identificadores y notas al añadir, desplazar o retirar la desviación', () => {
		const original = normalizeStructuredUnits(catalog, [], [], 'octosilaba', 1, 8);
		original[0].observaciones = 'Revisada';
		const first = normalizeStructuredUnits(catalog, original, [], 'octosilaba', 1, 9, [
			addition(3)
		]);
		const moved = normalizeStructuredUnits(catalog, first, [], 'octosilaba', 1, 9, [addition(5)]);
		const removed = normalizeStructuredUnits(catalog, moved, [], 'octosilaba', 1, 8);
		expect(removed).toEqual(original);
	});
	it('no cuenta dos veces una adición dentro de una estrofa, ni tapa otros huecos', () => {
		const deviations = [addition(3)];
		const units = normalizeStructuredUnits(catalog, [], [], 'octosilaba', 1, 9, deviations);
		expect(metricStructureCoverage(1, 9, units.slice(0, 1), deviations)).toMatchObject({
			state: 'missing',
			coveredVerses: 5,
			difference: -4
		});
	});
});
