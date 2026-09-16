import type { LaboratoryMetric } from './metricas';

const PERCENTAGE_CEILINGS = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1];

export type LaboratoryAxisScale = {
	minimum?: number;
	maximum?: number;
	maximumObserved: number | null;
	expandedPercentage: boolean;
};

export function getLaboratoryAxisScale(
	metric: LaboratoryMetric,
	values: Array<number | null>
): LaboratoryAxisScale {
	const valid = values.filter((value): value is number => value !== null && Number.isFinite(value));
	const maximumObserved = valid.length > 0 ? Math.max(...valid) : null;

	if (metric.unit !== 'porcentaje') {
		return { maximumObserved, expandedPercentage: false };
	}

	const paddedMaximum = Math.max(0, maximumObserved ?? 0) * 1.08;
	const maximum = PERCENTAGE_CEILINGS.find((ceiling) => ceiling >= paddedMaximum) ?? 1;

	return {
		minimum: 0,
		maximum,
		maximumObserved,
		expandedPercentage: maximum < 1
	};
}

export function formatLaboratoryAxisTick(
	value: number,
	metric: LaboratoryMetric,
	scale: LaboratoryAxisScale
): string {
	if (metric.unit !== 'porcentaje') {
		return value.toLocaleString('es', { maximumFractionDigits: 1 });
	}

	const maximumFractionDigits = (scale.maximum ?? 1) <= 0.005 ? 2 : (scale.maximum ?? 1) <= 0.02 ? 1 : 0;
	return `${(value * 100).toLocaleString('es', { maximumFractionDigits })} %`;
}
