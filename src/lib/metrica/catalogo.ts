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

export const METRIC_ARCHITECTURE_GRADES = [
	'fija',
	'canonica',
	'admitida',
	'rara',
	'irregular_documentada'
] as const;

export const METRIC_CHOICE_DIMENSIONS = [
	'metro',
	'rima',
	'combinacion',
	'estructura',
	'repeticion',
	'rasgo'
] as const;

export const METRIC_CHOICE_SCOPES = ['secuencia', 'unidad'] as const;

export const METRIC_MIGRATION_CLASSIFICATIONS = [
	'F',
	'G',
	'C',
	'P',
	'R',
	'A',
	'E',
	'D',
	'?'
] as const;

export type MetricCatalogReviewState = (typeof METRIC_CATALOG_REVIEW_STATES)[number];
export type MetricStructuralLevel = (typeof METRIC_STRUCTURAL_LEVELS)[number];
export type MetricEntryType = (typeof METRIC_ENTRY_TYPES)[number];
export type MetricSpecificationDegree = (typeof METRIC_SPECIFICATION_DEGREES)[number];
export type MetricArchitectureGrade = (typeof METRIC_ARCHITECTURE_GRADES)[number];
export type MetricMigrationClassification = (typeof METRIC_MIGRATION_CLASSIFICATIONS)[number];
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
	grado_especificacion: MetricSpecificationDegree | null;
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
	grado: MetricArchitectureGrade;
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

export type MetricCatalogMigrationRow = {
	termino_id: string;
	clasificacion_propuesta: MetricMigrationClassification;
	clasificacion_decidida: MetricMigrationClassification | null;
	propuesta: string;
	certeza: 'alta' | 'media' | 'baja';
	requiere_revision: boolean;
	estado_revision: 'pendiente' | 'revisada';
	notas_ip: string | null;
	revisado_en: string | null;
	fuente: MetricCatalogSourceTerm;
	destinos: Array<{
		destino_id: string;
		tipo_operacion: string;
		forma_id: string | null;
		arquitectura_id: string | null;
		variedad_id: string | null;
		esquema_metrico_id: string | null;
		esquema_rima_id: string | null;
		rasgo_id: string | null;
		valor_rasgo_id: string | null;
		alias_id: string | null;
	}>;
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
		| 'patron_rima_sin_regla'
		| 'patron_rima_comportamiento_pendiente'
		| 'termino_sin_destino'
		| 'revision_prioritaria'
		| 'configuracion_con_ambito_generico';
	level: 'error' | 'warning' | 'info';
	entityId: string;
	label: string;
	message: string;
};

export type MetricCatalogPreviewVersion = {
	version_id: string;
	numero: number;
	estado: string;
	catalogo_revision: number | null;
	fuente_actualizada_en: string | null;
	total_familias: number;
	total_familias_variantes: number;
	total_variantes_demarcables: number;
	generado_en: string;
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
	migrationRows: MetricCatalogMigrationRow[];
	previewVersions: MetricCatalogPreviewVersion[];
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
		pendingTerms: number;
		priorityPendingTerms: number;
		unresolvedTerms: number;
	};
};

export const METRIC_MIGRATION_CLASSIFICATION_LABELS: Record<MetricMigrationClassification, string> =
	{
		F: 'Forma',
		// La clasificación es la que se propuso al importar el vocabulario heredado; se
		// etiqueta con el vocabulario de hoy, y la familia ya no existe como destino.
		G: 'Familia (retirada)',
		C: 'Arquitectura',
		P: 'Esquema',
		R: 'Rasgo o valor',
		A: 'Alias o fusión',
		E: 'Residual editorial',
		D: 'Derivado o retirado',
		'?': 'Decisión abierta'
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
