import { describe, expect, it } from 'vitest';
import { getLaboratoryAxisScale } from './chart-scale';
import type { LaboratoryMetric } from './metricas';

const percentageMetric = {
	id: 'test_percentage',
	group: 'Enunciación',
	label: 'Porcentaje de prueba',
	description: '',
	measurement: 'proporcion_versos',
	unit: 'porcentaje',
	denominator: 'Total de prueba',
	read: () => ({ value: null })
} satisfies LaboratoryMetric;

describe('getLaboratoryAxisScale', () => {
	it('amplía una distribución inferior al uno por ciento hasta un techo redondo', () => {
		expect(getLaboratoryAxisScale(percentageMetric, [0.002, 0.006, 0.008])).toMatchObject({
			minimum: 0,
			maximum: 0.01,
			maximumObserved: 0.008,
			expandedPercentage: true
		});
	});

	it('mantiene el dominio completo cuando los datos requieren acercarse al cien por ciento', () => {
		expect(getLaboratoryAxisScale(percentageMetric, [0.12, 0.62])).toMatchObject({
			minimum: 0,
			maximum: 1,
			expandedPercentage: false
		});
	});
});
