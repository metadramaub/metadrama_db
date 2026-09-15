import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';

export type LaboratoryMeasurementKind =
	| 'recuento'
	| 'indice'
	| 'media'
	| 'proporcion_versos'
	| 'evento'
	| 'presencia_secuencia'
	| 'categoria_secuencia';

export type LaboratoryMetricReading = {
	value: number | null;
	numerator?: number;
	denominator?: number;
};

export type LaboratoryMetric = {
	id: string;
	group: 'Obra' | 'Repertorio' | 'Articulación' | 'Enunciación' | 'Fenómenos';
	label: string;
	description: string;
	measurement: LaboratoryMeasurementKind;
	unit: 'numero' | 'porcentaje' | 'versos' | 'por_cien_versos';
	denominator: string;
	fractionUnit?: string;
	caution?: string;
	read: (work: CorpusComparisonWork) => LaboratoryMetricReading;
};

export type LaboratoryMetricHelp = {
	unitLabel: string;
	explanation: string;
};

const metric = (
	id: keyof CorpusComparisonWork['metricas'],
	definition: Omit<LaboratoryMetric, 'id' | 'read'>
): LaboratoryMetric => ({
	id,
	...definition,
	read: (work) => ({ value: work.metricas[id] })
});

const phenomenon = (
	id: string,
	definition: Omit<LaboratoryMetric, 'id' | 'read'>
): LaboratoryMetric => ({
	id: `fenomeno:${id}`,
	...definition,
	read: (work) => {
		const value = work.fenomenos[id];
		return {
			value: value?.proporcion ?? null,
			numerator: value?.si,
			denominator: value?.total_respondidas
		};
	}
});

const enunciation = (
	id: string,
	definition: Omit<LaboratoryMetric, 'id' | 'read'>
): LaboratoryMetric => ({
	id: `enunciacion:${id}`,
	fractionUnit: 'vv.',
	...definition,
	read: (work) => {
		const value = work.enunciacion[id];
		return {
			value: value?.proporcion_versos ?? 0,
			numerator: value?.versos ?? 0,
			denominator: work.metricas.total_versos
		};
	}
});

const PRESENCE_CAUTION =
	'Presencia anotada por secuencia: no cuantifica los casos ni los versos afectados dentro de ella.';

export const LABORATORY_METRICS: LaboratoryMetric[] = [
	metric('total_versos', {
		group: 'Obra',
		label: 'Versos',
		description: 'Extensión total de la obra.',
		measurement: 'recuento',
		unit: 'versos',
		denominator: 'Obra completa'
	}),
	metric('total_secuencias', {
		group: 'Obra',
		label: 'Secuencias métricas',
		description: 'Número de secuencias métricas delimitadas en la obra.',
		measurement: 'recuento',
		unit: 'numero',
		denominator: 'Obra completa'
	}),
	metric('n_jornadas', {
		group: 'Obra',
		label: 'Jornadas',
		description: 'Número de jornadas con estructura registrada.',
		measurement: 'recuento',
		unit: 'numero',
		denominator: 'Obra completa'
	}),
	metric('n_formas_distintas', {
		group: 'Repertorio',
		label: 'Formas distintas',
		description: 'Número de formas métricas diferentes presentes.',
		measurement: 'recuento',
		unit: 'numero',
		denominator: 'Formas anotadas de la obra'
	}),
	metric('numero_efectivo_formas', {
		group: 'Repertorio',
		label: 'Diversidad efectiva',
		description: 'Diversidad del repertorio teniendo en cuenta el peso de cada forma.',
		measurement: 'indice',
		unit: 'numero',
		denominator: 'Versos con forma anotada'
	}),
	metric('densidad_transiciones', {
		group: 'Repertorio',
		label: 'Densidad de secuencias',
		description: 'Cuántas secuencias métricas hay por cada cien versos.',
		measurement: 'evento',
		unit: 'por_cien_versos',
		denominator: '100 versos de la obra'
	}),
	metric('longitud_media_secuencia', {
		group: 'Repertorio',
		label: 'Longitud media de secuencia',
		description: 'Promedio de versos de las secuencias métricas.',
		measurement: 'media',
		unit: 'versos',
		denominator: 'Secuencias métricas de la obra'
	}),
	metric('proporcion_italiana', {
		group: 'Repertorio',
		label: 'Tradición italiana',
		description: 'Peso de las formas italianas dentro de la versificación anotada.',
		measurement: 'proporcion_versos',
		unit: 'porcentaje',
		denominator: 'Versos con tradición identificada'
	}),
	metric('proporcion_sin_forma', {
		group: 'Repertorio',
		label: 'Sin forma anotada',
		description: 'Parte de la obra cuya forma todavía no está determinada.',
		measurement: 'proporcion_versos',
		unit: 'porcentaje',
		denominator: 'Versos de la obra'
	}),
	{
		id: 'cambios_cuadro_total',
		group: 'Articulación',
		label: 'Cambios de cuadro',
		description: 'Número de comienzos de cuadro posteriores al primero.',
		measurement: 'evento',
		unit: 'numero',
		denominator: 'Cuadros con cobertura',
		read: (work) => ({ value: work.articulacion.cambios_cuadro_total })
	},
	{
		id: 'proporcion_cambios_cuadro_con_cambio_secuencia',
		group: 'Articulación',
		label: 'Cuadros alineados con secuencia',
		description: 'Cambios de cuadro que coinciden con el comienzo de una nueva secuencia métrica.',
		measurement: 'evento',
		unit: 'porcentaje',
		denominator: 'Cambios de cuadro con cobertura',
		fractionUnit: 'cambios',
		read: (work) => ({
			value: work.articulacion.proporcion_cambios_cuadro_con_cambio_secuencia,
			numerator: work.articulacion.cambios_cuadro_con_cambio_secuencia,
			denominator:
				work.articulacion.cambios_cuadro_total - work.articulacion.cambios_cuadro_sin_cobertura
		})
	},
	enunciation('cantado', {
		group: 'Enunciación',
		label: 'Canto',
		description: 'Extensión de los pasajes cantados anotados por rango.',
		measurement: 'proporcion_versos',
		unit: 'porcentaje',
		denominator: 'Versos de la obra'
	}),
	enunciation('prosa', {
		group: 'Enunciación',
		label: 'Prosa',
		description: 'Extensión de los pasajes en prosa anotados por rango.',
		measurement: 'proporcion_versos',
		unit: 'porcentaje',
		denominator: 'Versos de la obra'
	}),
	enunciation('evocacion_metrica', {
		group: 'Enunciación',
		label: 'Evocación métrica',
		description: 'Extensión de los pasajes de evocación métrica anotados por rango.',
		measurement: 'proporcion_versos',
		unit: 'porcentaje',
		denominator: 'Versos de la obra'
	}),
	phenomenon('versos_partidos', {
		group: 'Fenómenos',
		label: 'Secuencias con versos partidos',
		description: 'Secuencias donde se ha señalado al menos un verso partido entre intervenciones.',
		measurement: 'presencia_secuencia',
		unit: 'porcentaje',
		denominator: 'Secuencias respondidas',
		fractionUnit: 'secuencias',
		caution: PRESENCE_CAUTION
	}),
	phenomenon('cambios_espacio', {
		group: 'Fenómenos',
		label: 'Inicios con cambio de espacio',
		description: 'Inicios de secuencia que coinciden con un cambio evidente de espacio escénico.',
		measurement: 'evento',
		unit: 'porcentaje',
		denominator: 'Inicios de secuencia respondidos',
		fractionUnit: 'inicios'
	}),
	phenomenon('eventos_sobrenaturales', {
		group: 'Fenómenos',
		label: 'Secuencias con evento sobrenatural',
		description: 'Secuencias donde se ha señalado al menos un acontecimiento sobrenatural.',
		measurement: 'presencia_secuencia',
		unit: 'porcentaje',
		denominator: 'Secuencias respondidas',
		fractionUnit: 'secuencias',
		caution: PRESENCE_CAUTION
	}),
	phenomenon('intervencion_femenina', {
		group: 'Fenómenos',
		label: 'Intervención de personajes femeninos',
		description: 'Secuencias con intervención exclusiva o compartida de personajes femeninos.',
		measurement: 'categoria_secuencia',
		unit: 'porcentaje',
		denominator: 'Secuencias respondidas',
		fractionUnit: 'secuencias'
	}),
	phenomenon('intervencion_donaire', {
		group: 'Fenómenos',
		label: 'Intervención de figuras de donaire',
		description: 'Secuencias con intervención exclusiva o compartida de figuras de donaire.',
		measurement: 'categoria_secuencia',
		unit: 'porcentaje',
		denominator: 'Secuencias respondidas',
		fractionUnit: 'secuencias'
	}),
	phenomenon('intervencion_sobrenaturales', {
		group: 'Fenómenos',
		label: 'Intervención de personajes sobrenaturales',
		description: 'Secuencias con intervención exclusiva o compartida de personajes sobrenaturales.',
		measurement: 'categoria_secuencia',
		unit: 'porcentaje',
		denominator: 'Secuencias respondidas',
		fractionUnit: 'secuencias'
	})
];

export const LABORATORY_METRIC_GROUPS = [
	'Obra',
	'Repertorio',
	'Articulación',
	'Enunciación',
	'Fenómenos'
] as const;

export function formatLaboratoryValue(value: number | null, metric: LaboratoryMetric): string {
	if (value === null || !Number.isFinite(value)) return '—';
	if (metric.unit === 'porcentaje') {
		return `${(value * 100).toLocaleString('es', { maximumFractionDigits: 2 })} %`;
	}
	if (metric.unit === 'por_cien_versos') {
		return `${value.toLocaleString('es', { maximumFractionDigits: 2 })} /100 vv.`;
	}
	if (metric.unit === 'versos') {
		return `${value.toLocaleString('es', { maximumFractionDigits: 2 })} vv.`;
	}
	return value.toLocaleString('es', { maximumFractionDigits: 2 });
}

export function getLaboratoryMetricHelp(metric: LaboratoryMetric): LaboratoryMetricHelp {
	if (metric.measurement === 'proporcion_versos') {
		return {
			unitLabel: 'Porcentaje de versos',
			explanation:
				'El numerador y el denominador son versos. El porcentaje permite comparar obras de distinta extensión.'
		};
	}
	if (metric.measurement === 'presencia_secuencia') {
		return {
			unitLabel: 'Porcentaje de secuencias',
			explanation:
				'Cada secuencia respondida cuenta una vez, con independencia de su longitud. El porcentaje no representa versos de la obra.'
		};
	}
	if (metric.measurement === 'categoria_secuencia') {
		return {
			unitLabel: 'Porcentaje de secuencias',
			explanation:
				'Cada secuencia respondida cuenta una vez si la intervención es exclusiva o compartida. El porcentaje expresa presencia por secuencia, no versos ni cantidad de parlamento.'
		};
	}
	if (metric.measurement === 'indice') {
		return {
			unitLabel: 'Índice: número efectivo',
			explanation:
				'Es un índice de diversidad expresado como número equivalente de formas; puede tener decimales y no es un recuento literal.'
		};
	}
	if (metric.measurement === 'media') {
		return {
			unitLabel: metric.unit === 'versos' ? 'Media de versos' : 'Media',
			explanation:
				'Es un promedio calculado dentro de cada obra. Puede tener decimales aunque las unidades originales sean enteras.'
		};
	}
	if (metric.measurement === 'evento') {
		if (metric.unit === 'porcentaje') {
			return {
				unitLabel: 'Porcentaje de casos',
				explanation:
					'Compara los casos que cumplen la condición con los casos cubiertos indicados en la base de cálculo; no usa versos salvo que la base lo diga.'
			};
		}
		if (metric.unit === 'por_cien_versos') {
			return {
				unitLabel: 'Casos por 100 versos',
				explanation:
					'Es una tasa: normaliza el recuento por la extensión de la obra para poder comparar textos de distinta longitud.'
			};
		}
		return {
			unitLabel: 'Recuento de casos',
			explanation:
				'Es un recuento absoluto y se expresa como número entero. Puede crecer simplemente porque una obra contenga más unidades observables.'
		};
	}
	return {
		unitLabel: metric.unit === 'versos' ? 'Recuento de versos' : 'Recuento absoluto',
		explanation:
			'Es un recuento directo y se expresa como número entero. No está normalizado por la extensión de la obra.'
	};
}

export function formatLaboratoryFraction(
	reading: LaboratoryMetricReading,
	metric: LaboratoryMetric
): string | null {
	if (reading.numerator === undefined || reading.denominator === undefined) return null;
	const numerator = reading.numerator.toLocaleString('es');
	const denominator = reading.denominator.toLocaleString('es');
	return `${numerator} de ${denominator}${metric.fractionUnit ? ` ${metric.fractionUnit}` : ''}`;
}

export function quantile(sorted: number[], proportion: number): number | null {
	if (sorted.length === 0) return null;
	if (sorted.length === 1) return sorted[0];
	const position = (sorted.length - 1) * proportion;
	const lower = Math.floor(position);
	const upper = Math.ceil(position);
	if (lower === upper) return sorted[lower];
	return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
}

export function summarizeLaboratoryValues(values: Array<number | null>) {
	const sorted = values
		.filter((value): value is number => value !== null && Number.isFinite(value))
		.sort((a, b) => a - b);
	return {
		n: sorted.length,
		missing: values.length - sorted.length,
		minimum: sorted[0] ?? null,
		q1: quantile(sorted, 0.25),
		median: quantile(sorted, 0.5),
		q3: quantile(sorted, 0.75),
		maximum: sorted.at(-1) ?? null
	};
}
