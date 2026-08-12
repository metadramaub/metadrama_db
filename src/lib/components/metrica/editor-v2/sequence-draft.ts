import type {
	MetricCatalogConfiguration,
	MetricCatalogDomainRow,
	MetricCatalogForEditor,
	MetricCatalogForm
} from '$lib/metrica/catalogo';
import { seRespondeDentroDeLaUnidad } from '$lib/metrica/alcance';
import {
	ensureRequiredMetricUnits,
	metricUnitPlan,
	reflowMetricUnits,
	syncChoiceMaterializedSections,
	syncRepeatedMetricUnits,
	type MetricChoiceDraft,
	type MetricUnitDraft,
	type MetricUnitPlan
} from './editor-model';

/**
 * Operaciones sobre el borrador de una secuencia que solo dependen del catálogo, no de
 * dónde se esté editando. Estaban dentro del componente del laboratorio; aquí son
 * funciones puras, reutilizables por cualquier contenedor y comprobables por separado.
 */

export type MetricDeviationDimension =
	| 'metro'
	| 'rima'
	| 'estructura'
	| 'repeticion'
	| 'rasgo';

export type MetricDeviationRelation =
	| 'diferente'
	| 'falta'
	| 'sobra'
	| 'menor_que_norma'
	| 'mayor_que_norma'
	| 'otra';

export const METRIC_DEVIATION_DIMENSIONS: { value: MetricDeviationDimension; label: string }[] = [
	{ value: 'metro', label: 'Metro' },
	{ value: 'rima', label: 'Rima' },
	{ value: 'estructura', label: 'Estructura' },
	{ value: 'repeticion', label: 'Repetición' },
	{ value: 'rasgo', label: 'Rasgo' }
];

const DEVIATION_RELATION_LABELS: Record<MetricDeviationRelation, string> = {
	diferente: 'Es otra',
	falta: 'Falta',
	sobra: 'Sobra',
	menor_que_norma: 'Menor que la norma',
	mayor_que_norma: 'Mayor que la norma',
	otra: 'Otra'
};

/**
 * Qué relaciones con la norma tienen sentido en cada dimensión, en el mismo orden que la
 * restricción de la base. Ofrecerlas todas obliga al editor a descartar a mano opciones
 * que no significan nada ahí: una rima no es «menor que la norma» y un rasgo no se rompe.
 *
 * La relación lleva siempre el hecho; el valor observado es precisión añadida, no una vía
 * alternativa. Por eso `metro` no ofrece «es otra»: una medida solo puede sobrar o faltar,
 * y cuál es exactamente se dice en el metro observado.
 */
const DEVIATION_RELATIONS_BY_DIMENSION: Record<
	MetricDeviationDimension,
	MetricDeviationRelation[]
> = {
	metro: ['menor_que_norma', 'mayor_que_norma', 'otra'],
	rima: ['diferente', 'otra'],
	estructura: ['falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'diferente', 'otra'],
	repeticion: ['falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'diferente', 'otra'],
	rasgo: ['falta', 'sobra', 'diferente', 'otra']
};

export function metricDeviationRelations(
	dimension: MetricDeviationDimension
): { value: MetricDeviationRelation; label: string }[] {
	return DEVIATION_RELATIONS_BY_DIMENSION[dimension].map((value) => ({
		value,
		label: DEVIATION_RELATION_LABELS[value]
	}));
}

/** La relación que se elige sola cuando la actual deja de aplicar al cambiar de dimensión. */
export function defaultRelationFor(
	dimension: MetricDeviationDimension,
	current: MetricDeviationRelation
): MetricDeviationRelation {
	const allowed = DEVIATION_RELATIONS_BY_DIMENSION[dimension];
	return allowed.includes(current) ? current : allowed[0];
}

export type MetricDeviationDraft = {
	realizacion_prueba_id: string | null;
	v_ini: number;
	v_fin: number;
	dimension: MetricDeviationDimension;
	relacion_norma: MetricDeviationRelation;
	metro_observado_id: string | null;
	esquema_rima_observado_id: string | null;
	seccion_observada_id: string | null;
	repeticion_observada_id: string | null;
	valor_rasgo_observado_id: string | null;
	observaciones: string;
};

export type MetricSequenceDraft = {
	secuencia_prueba_id: string | null;
	/**
	 * De dónde cuelga la prueba: un escenario ficticio o una secuencia real que se anota en
	 * sombra. Siempre uno de los dos, nunca los dos ni ninguno.
	 */
	escenario_id: string | null;
	secuencia_id: string | null;
	orden: number;
	v_ini: number;
	v_fin: number;
	forma_id: string;
	arquitectura_id: string;
	observaciones: string;
	unidades: MetricUnitDraft[];
	elecciones: MetricChoiceDraft[];
	desviaciones: MetricDeviationDraft[];
};

/** Lo que el formulario devuelve a su contenedor en cada cambio. */
export type MetricSequenceEditorState = {
	/** El borrador vivo, para que el contenedor pueda guardarlo. */
	draft: MetricSequenceDraft;
	summary: string;
	/** Preguntas obligatorias respondidas y totales. */
	answered: number;
	total: number;
	/** Por qué no se puede guardar; nulo cuando está listo. */
	error: string | null;
};

export type MetricCatalogParts = {
	sections: MetricCatalogDomainRow[];
	groups: MetricCatalogDomainRow[];
	options: MetricCatalogDomainRow[];
};

/** Secciones, preguntas y respuestas que el catálogo declara para una arquitectura. */
export function catalogParts(
	catalog: MetricCatalogForEditor,
	configurationId: string
): MetricCatalogParts {
	const sections = catalog.domain.sections.filter(
		(row: MetricCatalogDomainRow) => row.arquitectura_id === configurationId
	);
	const groups = catalog.domain.choiceGroups.filter(
		(row: MetricCatalogDomainRow) => row.arquitectura_id === configurationId && row.activo
	);
	const groupIds = new Set(
		groups.map((group: MetricCatalogDomainRow) => String(group.grupo_eleccion_id))
	);
	const options = catalog.domain.choiceOptions.filter(
		(row: MetricCatalogDomainRow) => row.activo && groupIds.has(String(row.grupo_eleccion_id))
	);
	return { sections, groups, options };
}

export function unitPlanFor(
	catalog: MetricCatalogForEditor,
	configurationId: string,
	sections: MetricCatalogDomainRow[]
): MetricUnitPlan | null {
	const configuration =
		catalog.configurations.find(
			(row: MetricCatalogConfiguration) => row.arquitectura_id === configurationId
		) ?? null;
	const form = configuration
		? (catalog.forms.find((row: MetricCatalogForm) => row.forma_id === configuration.forma_id) ??
			null)
		: null;
	return metricUnitPlan(configuration, sections, form?.nivel_estructural);
}

/** Materializa las secciones que una respuesta por unidad hace aparecer. */
export function applyMaterializedSections(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	groups: MetricCatalogDomainRow[],
	options: MetricCatalogDomainRow[],
	choices: MetricChoiceDraft[],
	sequenceStart: number
): MetricUnitDraft[] {
	let next = units;
	for (const group of groups.filter((row: MetricCatalogDomainRow) => seRespondeDentroDeLaUnidad(row.alcance))) {
		const groupId = String(group.grupo_eleccion_id);
		const groupOptions = options.filter(
			(option: MetricCatalogDomainRow) => String(option.grupo_eleccion_id) === groupId
		);
		if (!groupOptions.some((option) => option.materializa_seccion_id)) continue;
		for (const unit of [...next]) {
			const applies = group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null;
			if (!applies) continue;
			const selected = choices
				.filter(
					(choice: MetricChoiceDraft) =>
						choice.grupo_eleccion_id === groupId &&
						choice.realizacion_prueba_id === unit.realizacion_prueba_id &&
						Boolean(choice.opcion_eleccion_id)
				)
				.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
			next = syncChoiceMaterializedSections(
				next,
				sections,
				unit.realizacion_prueba_id,
				groupOptions,
				selected,
				sequenceStart,
				choices,
				options
			);
		}
	}
	return next;
}

/**
 * Deja las realizaciones coherentes con lo que declara la arquitectura. Con una unidad de
 * extensión fija el rango dice cuántas hay; con una variable, las decide el editor. En ambos
 * casos el rango sigue siendo una declaración editorial independiente y nunca se reescribe
 * desde las unidades.
 */
export function normalizeStructuredUnits(
	catalog: MetricCatalogForEditor,
	units: MetricUnitDraft[],
	choices: MetricChoiceDraft[],
	configurationId: string,
	sequenceStart: number,
	sequenceEnd: number
): MetricUnitDraft[] {
	const { sections, groups, options } = catalogParts(catalog, configurationId);
	const plan = unitPlanFor(catalog, configurationId, sections);
	if (!plan) return units;

	let next: MetricUnitDraft[];
	if (plan.countFromRange) {
		const synchronized = syncRepeatedMetricUnits(
			units,
			sections,
			plan.extent,
			sequenceStart,
			sequenceEnd,
			choices,
			options
		);
		if (synchronized.compatible) {
			next = synchronized.units;
		} else if (units.length > 0) {
			next = reflowMetricUnits(units, sections, sequenceStart, choices, options);
		} else {
			next = syncRepeatedMetricUnits(
				units,
				sections,
				plan.extent,
				sequenceStart,
				sequenceStart + (plan.extent?.minimum ?? 1) - 1,
				choices,
				options
			).units;
		}
	} else {
		next = ensureRequiredMetricUnits(units, sections, plan.extent, sequenceStart, choices, options);
	}

	next = applyMaterializedSections(next, sections, groups, options, choices, sequenceStart);
	return reflowMetricUnits(next, sections, sequenceStart, choices, options);
}

/** Una respuesta deducida del término legado que hay que colgar de las unidades. */
export type MetricProposedUnitAnswer = {
	grupo_eleccion_id: string;
	opcion_eleccion_id: string;
};

/**
 * Cuelga de sus unidades las respuestas que llegan ya deducidas del término legado.
 *
 * No pueden venir dentro del borrador porque cuando se construye las unidades no existen: las
 * materializa el editor al conocer la arquitectura. Una pregunta sin sección va a la unidad
 * entera —la realización que no cuelga de ninguna otra—; una anclada en una sección, a las
 * realizaciones de esa sección. Es el mismo criterio que aplica la función de guardado.
 *
 * Lo ya respondido no se toca: la propuesta solo rellena huecos.
 */
export function applyProposedUnitAnswers(
	units: MetricUnitDraft[],
	choices: MetricChoiceDraft[],
	groups: MetricCatalogDomainRow[],
	answers: MetricProposedUnitAnswer[]
): MetricChoiceDraft[] {
	const next = [...choices];
	for (const answer of answers) {
		const group = groups.find(
			(candidate) => String(candidate.grupo_eleccion_id) === answer.grupo_eleccion_id
		);
		if (!group) continue;
		const targets = units.filter((unit) =>
			group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null
		);
		for (const unit of targets) {
			const answered = next.some(
				(choice) =>
					choice.grupo_eleccion_id === answer.grupo_eleccion_id &&
					choice.realizacion_prueba_id === unit.realizacion_prueba_id
			);
			if (answered) continue;
			next.push({
				realizacion_prueba_id: unit.realizacion_prueba_id,
				grupo_eleccion_id: answer.grupo_eleccion_id,
				opcion_eleccion_id: answer.opcion_eleccion_id,
				valor_texto: null,
				observaciones: null
			});
		}
	}
	return next;
}

/** Las filas guardadas de una prueba, tal como las devuelve la base. */
export type MetricSavedSequenceRows = {
	units: MetricCatalogDomainRow[];
	choices: MetricCatalogDomainRow[];
	deviations: MetricCatalogDomainRow[];
};

/**
 * Reconstruye el borrador de una prueba ya guardada. Lo usan por igual el laboratorio de
 * escenarios y la anotación en sombra: una prueba se lee igual venga de donde venga.
 */
export function draftFromRows(
	sequence: MetricCatalogDomainRow,
	rows: MetricSavedSequenceRows
): MetricSequenceDraft {
	const sequenceId = String(sequence.secuencia_prueba_id);
	const belongs = (row: MetricCatalogDomainRow) =>
		String(row.secuencia_prueba_id) === sequenceId;
	const text = (value: unknown): string => String(value ?? '');
	const id = (value: unknown): string | null => (value ? String(value) : null);

	return {
		secuencia_prueba_id: sequenceId,
		escenario_id: id(sequence.escenario_id),
		secuencia_id: id(sequence.secuencia_id),
		orden: Number(sequence.orden),
		v_ini: Number(sequence.v_ini),
		v_fin: Number(sequence.v_fin),
		forma_id: String(sequence.forma_id),
		arquitectura_id: text(sequence.arquitectura_id),
		observaciones: text(sequence.observaciones),
		unidades: rows.units.filter(belongs).map((unit) => ({
			realizacion_prueba_id: String(unit.realizacion_prueba_id),
			realizacion_padre_id: id(unit.realizacion_padre_id),
			seccion_id: String(unit.seccion_id),
			orden: Number(unit.orden),
			v_ini: Number(unit.v_ini),
			v_fin: Number(unit.v_fin),
			etiqueta: text(unit.etiqueta),
			observaciones: text(unit.observaciones)
		})),
		elecciones: rows.choices.filter(belongs).map((choice) => ({
			realizacion_prueba_id: id(choice.realizacion_prueba_id),
			grupo_eleccion_id: String(choice.grupo_eleccion_id),
			opcion_eleccion_id: id(choice.opcion_eleccion_id),
			valor_texto: choice.valor_texto ? String(choice.valor_texto) : null,
			observaciones: choice.observaciones ? String(choice.observaciones) : null
		})),
		desviaciones: rows.deviations.filter(belongs).map((deviation) => ({
			realizacion_prueba_id: id(deviation.realizacion_prueba_id),
			v_ini: Number(deviation.v_ini),
			v_fin: Number(deviation.v_fin),
			dimension: deviation.dimension as MetricDeviationDimension,
			relacion_norma: deviation.relacion_norma as MetricDeviationRelation,
			metro_observado_id: id(deviation.metro_observado_id),
			esquema_rima_observado_id: id(deviation.esquema_rima_observado_id),
			seccion_observada_id: id(deviation.seccion_observada_id),
			repeticion_observada_id: id(deviation.repeticion_observada_id),
			valor_rasgo_observado_id: id(deviation.valor_rasgo_observado_id),
			observaciones: text(deviation.observaciones)
		}))
	};
}

export function emptyDeviation(vIni: number, vFin: number): MetricDeviationDraft {
	const dimension: MetricDeviationDimension = 'metro';
	return {
		realizacion_prueba_id: null,
		v_ini: vIni,
		v_fin: vFin,
		dimension,
		// Se toma del mapa para que no pueda quedar una combinación que la base rechaza.
		relacion_norma: DEVIATION_RELATIONS_BY_DIMENSION[dimension][0],
		metro_observado_id: null,
		esquema_rima_observado_id: null,
		seccion_observada_id: null,
		repeticion_observada_id: null,
		valor_rasgo_observado_id: null,
		observaciones: ''
	};
}
