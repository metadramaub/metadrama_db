/** Solo «estructura / sobra» identifica versos añadidos a la norma. */
export type MetricDeviationRange = {
	v_ini: number;
	v_fin: number;
	dimension: string;
	relacion_norma: string;
};

export type MetricVerseRange = { v_ini: number; v_fin: number };

/** Unión de las adiciones válidas: una misma posición nunca se descuenta dos veces. */
export function structuralAdditionRanges(
	start: number,
	end: number,
	deviations: readonly MetricDeviationRange[] = []
): MetricVerseRange[] {
	const ranges = deviations
		.filter(
			(d) =>
				d.dimension === 'estructura' &&
				d.relacion_norma === 'sobra' &&
				Number.isInteger(d.v_ini) &&
				Number.isInteger(d.v_fin) &&
				d.v_ini >= start &&
				d.v_fin <= end &&
				d.v_fin >= d.v_ini
		)
		.map(({ v_ini, v_fin }) => ({ v_ini, v_fin }))
		.sort((a, b) => a.v_ini - b.v_ini);
	const merged: MetricVerseRange[] = [];
	for (const range of ranges) {
		const last = merged.at(-1);
		if (last && range.v_ini <= last.v_fin + 1) last.v_fin = Math.max(last.v_fin, range.v_fin);
		else merged.push(range);
	}
	return merged;
}

export function structuralAdditionCount(
	start: number,
	end: number,
	deviations: readonly MetricDeviationRange[] = []
): number {
	return structuralAdditionRanges(start, end, deviations).reduce(
		(total, range) => total + range.v_fin - range.v_ini + 1,
		0
	);
}

/** Posiciones de la norma ↔ numeración de la edición, que conserva todos los versos. */
export function metricAdditionCoordinates(ranges: readonly MetricVerseRange[]) {
	return {
		toNorm(verse: number) {
			return (
				verse -
				ranges.reduce(
					(total, range) => total + Math.max(0, Math.min(verse, range.v_fin) - range.v_ini + 1),
					0
				)
			);
		},
		toEdition(verse: number) {
			let result = verse;
			for (const range of ranges) {
				if (result >= range.v_ini) result += range.v_fin - range.v_ini + 1;
			}
			return result;
		}
	};
}
