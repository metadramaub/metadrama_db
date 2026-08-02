import type {
	MetricCatalogConfiguration,
	MetricCatalogDomainRow,
	MetricCatalogForEditor,
	MetricCatalogForm
} from '$lib/metrica/catalogo';
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
	| 'rasgo'
	| 'combinacion';

export type MetricDeviationRelation =
	| 'diferente'
	| 'menor_que_norma'
	| 'mayor_que_norma'
	| 'falta_elemento_esperado'
	| 'aparece_elemento_no_esperado'
	| 'ruptura'
	| 'omision'
	| 'adicion'
	| 'sustitucion'
	| 'otra';

export const METRIC_DEVIATION_DIMENSIONS: { value: MetricDeviationDimension; label: string }[] = [
	{ value: 'metro', label: 'Metro' },
	{ value: 'rima', label: 'Rima' },
	{ value: 'estructura', label: 'Estructura' },
	{ value: 'repeticion', label: 'Repetición' },
	{ value: 'rasgo', label: 'Rasgo' },
	{ value: 'combinacion', label: 'Variedad' }
];

const DEVIATION_RELATION_LABELS: Record<MetricDeviationRelation, string> = {
	diferente: 'Diferente',
	menor_que_norma: 'Menor que la norma',
	mayor_que_norma: 'Mayor que la norma',
	falta_elemento_esperado: 'Falta un elemento esperado',
	aparece_elemento_no_esperado: 'Aparece un elemento no esperado',
	ruptura: 'Ruptura',
	omision: 'Omisión',
	adicion: 'Adición',
	sustitucion: 'Sustitución',
	otra: 'Otra'
};

/**
 * Qué relaciones con la norma tienen sentido en cada dimensión. Ofrecerlas todas obliga
 * al editor a descartar a mano opciones que no significan nada ahí: una rima no es «menor
 * que la norma» y un rasgo no se «rompe».
 *
 * Es una lectura del vocabulario, no una regla sobre formas concretas, así que vive junto
 * al tipo y no en el componente. Si el IP la afina, su sitio natural es el catálogo, como
 * el resto de lo que el editor pregunta.
 */
const DEVIATION_RELATIONS_BY_DIMENSION: Record<
	MetricDeviationDimension,
	MetricDeviationRelation[]
> = {
	// Una medida es distinta, más corta, más larga o sustituida por otra.
	metro: ['diferente', 'menor_que_norma', 'mayor_que_norma', 'sustitucion', 'otra'],
	// Una rima se rompe, difiere o se sustituye; no es mayor ni menor.
	rima: ['diferente', 'ruptura', 'sustitucion', 'otra'],
	// La estructura admite todo el repertorio de faltas, adiciones y desajustes de tamaño.
	estructura: [
		'diferente',
		'menor_que_norma',
		'mayor_que_norma',
		'falta_elemento_esperado',
		'aparece_elemento_no_esperado',
		'omision',
		'adicion',
		'otra'
	],
	// Una repetición falta, sobra, cambia de tamaño o se rompe.
	repeticion: [
		'diferente',
		'menor_que_norma',
		'mayor_que_norma',
		'falta_elemento_esperado',
		'aparece_elemento_no_esperado',
		'ruptura',
		'otra'
	],
	// Un rasgo está o no está; no tiene tamaño ni se rompe.
	rasgo: ['falta_elemento_esperado', 'aparece_elemento_no_esperado', 'diferente', 'otra'],
	// Una variedad se realiza de otra manera o se sustituye por otra.
	combinacion: ['diferente', 'sustitucion', 'otra']
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
	escenario_id: string;
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
	for (const group of groups.filter((row: MetricCatalogDomainRow) => row.alcance === 'unidad')) {
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
 * extensión fija el rango dice cuántas hay; con una variable, las decide el editor y el
 * rango se calcula desde ellas.
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

export function emptyDeviation(vIni: number, vFin: number): MetricDeviationDraft {
	return {
		realizacion_prueba_id: null,
		v_ini: vIni,
		v_fin: vFin,
		dimension: 'metro',
		relacion_norma: 'diferente',
		metro_observado_id: null,
		esquema_rima_observado_id: null,
		seccion_observada_id: null,
		repeticion_observada_id: null,
		valor_rasgo_observado_id: null,
		observaciones: ''
	};
}
