export const METRIC_CATALOG_REVIEW_STATES = [
	'borrador',
	'revisada',
	'aprobada',
	'retirada'
] as const;

export const METRIC_STRUCTURAL_LEVELS = ['verso', 'estrofa', 'serie', 'composicion'] as const;

export const METRIC_ENTRY_TYPES = ['forma', 'sin_forma'] as const;

/** Cuánto acota la norma de una forma. Nulo en los tramos sin forma. */
export const METRIC_SPECIFICATION_DEGREES = ['general', 'especifica'] as const;

/**
 * Cuánto ha fijado la norma o la crítica una realización. No mide permiso: en este modelo
 * todo es posible aunque no tenga nombre. Una arquitectura nunca es `definitoria`, porque
 * una realización no define su forma.
 */
export const METRIC_MODALITIES = ['definitoria', 'preferente', 'admitida', 'excepcional'] as const;

export const METRIC_ARCHITECTURE_MODALITIES = ['preferente', 'admitida', 'excepcional'] as const;

/** Qué forma tiene la secuencia declarada por un esquema, métrico o de rima. */
export const METRIC_SEQUENCE_TYPES = [
	'ciclo',
	'secuencia',
	'conjunto',
	'restricciones',
	'abierta'
] as const;

/** Si un esquema describe la unidad entera o una parte suya. */
export const METRIC_SCHEME_SCOPES = ['unidad', 'seccion'] as const;

export const METRIC_CHOICE_DIMENSIONS = [
	'metro',
	'rima',
	'combinacion',
	'estructura',
	'repeticion',
	'rasgo'
] as const;

export const METRIC_CHOICE_SCOPES = ['secuencia', 'unidad'] as const;

export type MetricCatalogReviewState = (typeof METRIC_CATALOG_REVIEW_STATES)[number];
export type MetricStructuralLevel = (typeof METRIC_STRUCTURAL_LEVELS)[number];
export type MetricEntryType = (typeof METRIC_ENTRY_TYPES)[number];
export type MetricSpecificationDegree = (typeof METRIC_SPECIFICATION_DEGREES)[number];
export type MetricModality = (typeof METRIC_MODALITIES)[number];
export type MetricArchitectureModality = (typeof METRIC_ARCHITECTURE_MODALITIES)[number];
export type MetricSequenceType = (typeof METRIC_SEQUENCE_TYPES)[number];
export type MetricSchemeScope = (typeof METRIC_SCHEME_SCOPES)[number];
export type MetricChoiceDimension = (typeof METRIC_CHOICE_DIMENSIONS)[number];
export type MetricChoiceScope = (typeof METRIC_CHOICE_SCOPES)[number];

export type MetricCatalogForm = {
	forma_id: string;
	slug: string;
	nombre: string;
	definicion: string | null;
	nivel_estructural: MetricStructuralLevel;
	tipo_registro: MetricEntryType;
	seleccionable: boolean;
	estado_revision: MetricCatalogReviewState;
	activo: boolean;
	orden: number | null;
	origen_termino_id: string | null;
	updated_at: string;
};

export type MetricCatalogConfiguration = {
	arquitectura_id: string;
	forma_id: string;
	slug: string;
	nombre: string;
	descripcion: string | null;
	principal: boolean;
	demarcable: boolean;
	modalidad: MetricArchitectureModality;
	tipo_rima_id: string | null;
	unidad_versos_min: number | null;
	unidad_versos_max: number | null;
	estado_revision: MetricCatalogReviewState;
	activo: boolean;
	orden: number | null;
	origen_termino_id: string | null;
	updated_at: string;
	patrones_metro: number;
	esquemas_rima: number;
};

export type MetricLengthRule = {
	arquitectura_id: string;
	arquitectura_nombre: string;
	modulo_versos: number;
	residuo_versos: number;
	minimo_versos: number;
	origen:
		| 'unidad'
		| 'secciones_fijas'
		| 'secciones_repetibles'
		| 'ciclo_rima'
		| 'ciclo_metrico';
	explicacion: string;
};

export type MetricCatalogTradition = {
	tradicion_id: string;
	slug: string;
	nombre: string;
	descripcion: string | null;
	estado_revision: MetricCatalogReviewState;
	activo: boolean;
	formas: number;
};

export type MetricCatalogSourceTerm = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	definicion: string | null;
	termino_padre_id: string | null;
};

export type MetricCatalogOption = {
	id: string;
	slug: string;
	label: string;
};

export type MetricCatalogIssue = {
	code:
		| 'forma_sin_configuracion'
		| 'forma_sin_principal'
		| 'configuracion_sin_modelo'
		| 'patron_metrico_sin_posiciones'
		| 'patron_metrico_sin_opciones'
		| 'patron_metrico_sin_nombre'
		| 'patron_rima_sin_regla';
	level: 'error' | 'warning' | 'info';
	entityId: string;
	label: string;
	message: string;
};

export const METRIC_CATALOG_RESOURCES = [
	'traditions',
	'formTraditions',
	'aliases',
	'formRelations',
	'verseModels',
	'verseSegments',
	'metricPatterns',
	'metricPositions',
	'metricOptions',
	'rhymePatterns',
	'rhymePositions',
	'rhymeLinks',
	'rhymeRestrictions',
	'patternCombinations',
	'sections',
	'repetitionPatterns',
	'repetitionPositions',
	'traits',
	'traitValues',
	'configurationTraits',
	'choiceGroups',
	'choiceOptions',
	'sources',
	'sourceClaims'
] as const;

export type MetricCatalogResource = (typeof METRIC_CATALOG_RESOURCES)[number];
export type MetricCatalogDomainRow = Record<string, unknown>;
export type MetricCatalogDomainData = Record<MetricCatalogResource, MetricCatalogDomainRow[]> & {
	forms: MetricCatalogDomainRow[];
	configurations: MetricCatalogDomainRow[];
};

/**
 * Lo único que el editor de secuencias necesita saber del catálogo para generar sus
 * preguntas. Es deliberadamente más estrecho que `MetricCatalogPageData`: el editor no
 * conoce escenarios de prueba, ni estadísticas, ni versiones del demarcador, así que el
 * mismo componente sirve en el laboratorio y, cuando se apruebe, en el editor de obras.
 */
export type MetricCatalogForEditor = {
	forms: MetricCatalogForm[];
	configurations: MetricCatalogConfiguration[];
	lengthRules: MetricLengthRule[];
	domain: MetricCatalogDomainData;
};

export type MetricEditorSandboxData = {
	scenarios: MetricCatalogDomainRow[];
	sequences: MetricCatalogDomainRow[];
	units: MetricCatalogDomainRow[];
	choices: MetricCatalogDomainRow[];
	deviations: MetricCatalogDomainRow[];
};

export type MetricCatalogPageData = {
	migrationPending: boolean;
	migrationMessage: string | null;
	revision: number | null;
	forms: MetricCatalogForm[];
	configurations: MetricCatalogConfiguration[];
	lengthRules: MetricLengthRule[];
	traditions: MetricCatalogTradition[];
	domain: MetricCatalogDomainData;
	editorSandbox: MetricEditorSandboxData;
	options: {
		rhymeTypes: MetricCatalogOption[];
		metres: MetricCatalogOption[];
	};
	issues: MetricCatalogIssue[];
	stats: {
		forms: number;
		approvedForms: number;
		configurations: number;
	};
};

export function metricReviewStateLabel(state: MetricCatalogReviewState): string {
	if (state === 'borrador') return 'Borrador';
	if (state === 'revisada') return 'Revisada';
	if (state === 'aprobada') return 'Aprobada';
	return 'Retirada';
}

export function metricStructuralLevelLabel(level: MetricStructuralLevel): string {
	if (level === 'verso') return 'Verso';
	if (level === 'estrofa') return 'Estrofa';
	if (level === 'serie') return 'Serie no estrófica';
	return 'Composición de estructura fija';
}
