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

/**
 * **«Es otra» y «Otra» eran indistinguibles**, y en rima salían las dos juntas. Una dice que lo que
 * hay es otro valor de la misma clase —otro esquema, otro valor del rasgo— y la otra que es
 * cualquier otra cosa, la que se explica escribiendo. Ahora lo dicen.
 */
const DEVIATION_RELATION_LABELS: Record<MetricDeviationRelation, string> = {
	falta: 'Falta',
	sobra: 'Sobra',
	menor_que_norma: 'Mide menos que la norma',
	mayor_que_norma: 'Mide más que la norma',
	otra: 'Otra cosa, se explica abajo'
};

/**
 * Qué relaciones con la norma tienen sentido en cada dimensión, en el mismo orden que la
 * restricción de la base. Ofrecerlas todas obliga al editor a descartar a mano opciones que no
 * significan nada ahí.
 *
 * La relación lleva siempre el hecho; el valor observado es precisión añadida, no una vía
 * alternativa. Por eso `metro` no ofrece «otra cosa» como manera de decir qué mide: una medida solo
 * puede quedarse corta o pasarse, y cuál es exactamente se dice en el metro observado.
 *
 * **`diferente` —«es otro valor»— se retiró el 7 de septiembre de 2026**, junto con `menor` y
 * `mayor` en repetición. Donde la respuesta se escribe, «es otro valor» ya es una respuesta; donde
 * el repertorio es cerrado, un valor que no está no es una desviación de la obra sino una falta del
 * catálogo, y eso lo decide el IP. Y el estribillo que vuelve con menos versos **es** «se repite
 * solo en parte», que también es una respuesta. La base lo comprueba combinación a combinación.
 */
const DEVIATION_RELATIONS_BY_DIMENSION: Record<
	MetricDeviationDimension,
	MetricDeviationRelation[]
> = {
	metro: ['menor_que_norma', 'mayor_que_norma', 'otra'],
	rima: ['otra'],
	estructura: ['falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'otra'],
	repeticion: ['falta', 'sobra', 'otra'],
	rasgo: ['falta', 'sobra', 'otra']
};

/** Sin dimensión no hay relaciones que ofrecer: primero se dice de qué habla la desviación. */
export function metricDeviationRelations(
	dimension: MetricDeviationDimension | ''
): { value: MetricDeviationRelation; label: string }[] {
	if (!dimension) return [];
	return DEVIATION_RELATIONS_BY_DIMENSION[dimension].map((value) => ({
		value,
		label: DEVIATION_RELATION_LABELS[value]
	}));
}

/**
 * La relación que queda al cambiar de dimensión.
 *
 * **Se conserva la elegida si sigue valiendo, y si no se vacía**, en vez de saltar a la primera de
 * la lista: cambiar de dimensión no es decir nada sobre la relación, y elegirla por el editor es lo
 * que hacía que una desviación recién creada ya afirmase algo.
 */
export function defaultRelationFor(
	dimension: MetricDeviationDimension | '',
	current: MetricDeviationRelation | ''
): MetricDeviationRelation | '' {
	if (!dimension) return '';
	const allowed = DEVIATION_RELATIONS_BY_DIMENSION[dimension];
	return current && allowed.includes(current) ? current : '';
}

export type MetricDeviationDraft = {
	realizacion_id: string | null;
	v_ini: number;
	v_fin: number;
	/** Vacío mientras el editor no haya dicho de qué habla la desviación. */
	dimension: MetricDeviationDimension | '';
	relacion_norma: MetricDeviationRelation | '';
	metro_observado_id: string | null;
	esquema_rima_observado_id: string | null;
	seccion_observada_id: string | null;
	repeticion_observada_id: string | null;
	valor_rasgo_observado_id: string | null;
	observaciones: string;
};

export type MetricSequenceDraft = {
	anotacion_id: string | null;
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
	/** Por qué no se puede guardar; nulo cuando está listo. Se dice al intentar guardar. */
	error: string | null;
	/**
	 * Y de esos motivos, **solo el del rango**: que el número de versos no cabe en la forma, o que
	 * la estructura no cubre lo declarado.
	 *
	 * Va aparte porque es el único que se enseña mientras se anota. Los demás —una pregunta sin
	 * responder— son cosas que el editor **está haciendo**, y avisarle de que le faltan en cuanto
	 * abre la secuencia es apremiarle por no haber terminado todavía; además sería desigual, porque
	 * de lo que falta en caracterizaciones o en la sinopsis no se dice nada. El rango es distinto:
	 * no es algo por terminar sino algo que está mal, y cuanto antes se vea, menos trabajo se hace
	 * encima de un rango equivocado.
	 */
	errorDeRango: string | null;
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
,
	/** Las unidades ya materializadas: una con arquitectura propia apaga la derivación. */
	units: MetricUnitDraft[] = []
): MetricUnitPlan | null {
	const configuration =
		catalog.configurations.find(
			(row: MetricCatalogConfiguration) => row.arquitectura_id === configurationId
		) ?? null;
	const form = configuration
		? (catalog.forms.find((row: MetricCatalogForm) => row.forma_id === configuration.forma_id) ??
			null)
		: null;
	return metricUnitPlan(configuration, sections, form?.nivel_estructural, units);
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
						choice.realizacion_id === unit.realizacion_id &&
						Boolean(choice.opcion_eleccion_id)
				)
				.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
			next = syncChoiceMaterializedSections(
				next,
				sections,
				unit.realizacion_id,
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
/**
 * Las secciones de las arquitecturas **intercalables** de la misma forma.
 *
 * Se calculan aquí, junto a las de la secuencia, porque es el único sitio que ve el catálogo
 * entero y la arquitectura elegida. Sale vacío en todas las formas menos la décima, que es la
 * única que hoy declara una intercalable.
 */
export function seccionesIntercalables(
	catalog: MetricCatalogForEditor,
	configurationId: string
): MetricCatalogDomainRow[] {
	const propia = catalog.configurations.find(
		(configuration) => String(configuration.arquitectura_id) === configurationId
	);
	if (!propia) return [];
	const intercalables = new Set(
		catalog.configurations
			.filter(
				(configuration) =>
					configuration.forma_id === propia.forma_id &&
					configuration.activo &&
					configuration.intercalable &&
					String(configuration.arquitectura_id) !== configurationId
			)
			.map((configuration) => String(configuration.arquitectura_id))
	);
	if (intercalables.size === 0) return [];
	return catalog.domain.sections.filter((section) =>
		intercalables.has(String(section.arquitectura_id ?? ''))
	);
}

export function normalizeStructuredUnits(
	catalog: MetricCatalogForEditor,
	units: MetricUnitDraft[],
	choices: MetricChoiceDraft[],
	configurationId: string,
	sequenceStart: number,
	sequenceEnd: number
): MetricUnitDraft[] {
	const { sections, groups, options } = catalogParts(catalog, configurationId);
	const intercaladas = seccionesIntercalables(catalog, configurationId);
	// Las unidades que ya hay deciden si el rango sigue mandando: una excepción intercalada apaga
	// la derivación, y sin pasárselas el editor la borraría en el primer recálculo.
	const plan = unitPlanFor(catalog, configurationId, sections, units);
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
		next = ensureRequiredMetricUnits(
			units,
			sections,
			plan.extent,
			sequenceStart,
			choices,
			options,
			intercaladas
		);
	}

	next = applyMaterializedSections(next, sections, groups, options, choices, sequenceStart);
	return reflowMetricUnits(next, sections, sequenceStart, choices, options, intercaladas);
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
					choice.realizacion_id === unit.realizacion_id
			);
			if (answered) continue;
			next.push({
				realizacion_id: unit.realizacion_id,
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
	const sequenceId = String(sequence.anotacion_id);
	const belongs = (row: MetricCatalogDomainRow) =>
		String(row.anotacion_id) === sequenceId;
	const text = (value: unknown): string => String(value ?? '');
	const id = (value: unknown): string | null => (value ? String(value) : null);

	return {
		anotacion_id: sequenceId,
		escenario_id: id(sequence.escenario_id),
		secuencia_id: id(sequence.secuencia_id),
		orden: Number(sequence.orden),
		v_ini: Number(sequence.v_ini),
		v_fin: Number(sequence.v_fin),
		forma_id: String(sequence.forma_id),
		arquitectura_id: text(sequence.arquitectura_id),
		observaciones: text(sequence.observaciones),
		unidades: rows.units.filter(belongs).map((unit) => ({
			realizacion_id: String(unit.realizacion_id),
			realizacion_padre_id: id(unit.realizacion_padre_id),
			// **`id`, no `String`.** La realización de la unidad no realiza ninguna sección, y
			// `String(null)` daba la cadena «null»: con ella `isMetricUnit` no reconocía ni una
			// sola unidad, así que al reabrir una secuencia el editor no la leía, la reconstruía
			// desde el rango —y una tirada que el rango no divide se quedaba sin rejilla—.
			seccion_id: id(unit.seccion_id),
			// Y la arquitectura que declare, si declara alguna: sin esto la excepción intercalada
			// se guardaba pero no se volvía a leer.
			arquitectura_id: id(unit.arquitectura_id),
			orden: Number(unit.orden),
			v_ini: Number(unit.v_ini),
			v_fin: Number(unit.v_fin),
			etiqueta: text(unit.etiqueta),
			observaciones: text(unit.observaciones)
		})),
		elecciones: rows.choices.filter(belongs).map((choice) => ({
			realizacion_id: id(choice.realizacion_id),
			grupo_eleccion_id: String(choice.grupo_eleccion_id),
			opcion_eleccion_id: id(choice.opcion_eleccion_id),
			valor_texto: choice.valor_texto ? String(choice.valor_texto) : null,
			observaciones: choice.observaciones ? String(choice.observaciones) : null
		})),
		desviaciones: rows.deviations.filter(belongs).map((deviation) => ({
			realizacion_id: id(deviation.realizacion_id),
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

/**
 * Una desviación recién abierta **no afirma nada**.
 *
 * Nacía con «Metro · Menor que la norma» puesto, que es una afirmación que el editor no ha hecho:
 * bastaba con pulsar el botón y guardar para dejar escrito en la base que el metro de ese pasaje es
 * menor que el de la norma. Ahora empieza en blanco y no se puede guardar hasta que diga qué pasa.
 *
 * El rango tampoco se presupone. Venía relleno con la secuencia entera —1 a 25 en una quintilla de
 * cinco unidades— y una desviación de todo el pasaje es una contradicción: si todo se aparta, la
 * forma elegida es otra. Empieza en el primer verso y se acota a mano.
 */
export function emptyDeviation(vIni: number, _vFin: number): MetricDeviationDraft {
	return {
		realizacion_id: null,
		v_ini: vIni,
		v_fin: vIni,
		dimension: '',
		relacion_norma: '',
		metro_observado_id: null,
		esquema_rima_observado_id: null,
		seccion_observada_id: null,
		repeticion_observada_id: null,
		valor_rasgo_observado_id: null,
		observaciones: ''
	};
}
