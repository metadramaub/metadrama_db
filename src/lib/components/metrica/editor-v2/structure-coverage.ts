import type { MetricUnitDraft } from './editor-model';

export type MetricStructureCoverage = {
	declaredVerses: number;
	coveredVerses: number;
	difference: number;
	state: 'complete' | 'missing' | 'overflow';
};

/**
 * Compara el rango editorial con las unidades raíz que lo reparten. Las secciones hijas no
 * se suman: ya están contenidas en su unidad y contarlas duplicaría versos en sonetos,
 * canciones o villancicos.
 */
export function metricStructureCoverage(
	sequenceStart: number,
	sequenceEnd: number,
	units: MetricUnitDraft[]
): MetricStructureCoverage {
	const declaredVerses = Math.max(0, sequenceEnd - sequenceStart + 1);
	const rootUnits = units.filter((unit) => unit.realizacion_padre_id === null);
	const coveredVerses = rootUnits.reduce(
		(total, unit) => total + Math.max(0, unit.v_fin - unit.v_ini + 1),
		0
	);
	const difference = coveredVerses - declaredVerses;
	return {
		declaredVerses,
		coveredVerses,
		difference,
		state: difference === 0 ? 'complete' : difference < 0 ? 'missing' : 'overflow'
	};
}
