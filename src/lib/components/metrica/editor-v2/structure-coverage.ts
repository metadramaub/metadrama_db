import type { MetricUnitDraft } from './editor-model';
import {
	structuralAdditionRanges,
	type MetricDeviationRange
} from '$lib/metrica/structural-additions';

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
	units: MetricUnitDraft[],
	deviations: readonly MetricDeviationRange[] = []
): MetricStructureCoverage {
	const declaredVerses = Math.max(0, sequenceEnd - sequenceStart + 1);
	const rootUnits = units.filter((unit) => unit.realizacion_padre_id === null);
	let coveredVerses = rootUnits.reduce(
		(total, unit) => total + Math.max(0, unit.v_fin - unit.v_ini + 1),
		0
	);
	// Las adiciones entre unidades cubren posiciones del pasaje, pero no crean otra estrofa.
	// Una adición interna ya está incluida en el rango de su unidad: no se suma otra vez.
	for (const addition of structuralAdditionRanges(sequenceStart, sequenceEnd, deviations)) {
		let cursor = addition.v_ini;
		for (const unit of [...rootUnits].sort((a, b) => a.v_ini - b.v_ini)) {
			if (unit.v_fin < cursor || unit.v_ini > addition.v_fin) continue;
			coveredVerses += Math.max(0, unit.v_ini - cursor);
			cursor = Math.max(cursor, unit.v_fin + 1);
			if (cursor > addition.v_fin) break;
		}
		coveredVerses += Math.max(0, addition.v_fin - cursor + 1);
	}
	const difference = coveredVerses - declaredVerses;
	return {
		declaredVerses,
		coveredVerses,
		difference,
		state: difference === 0 ? 'complete' : difference < 0 ? 'missing' : 'overflow'
	};
}
