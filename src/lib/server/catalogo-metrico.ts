import type {
	MetricCatalogConfiguration,
	MetricCatalogDomainData,
	MetricCatalogFamily,
	MetricCatalogForm,
	MetricCatalogIssue,
	MetricCatalogMigrationRow,
	MetricCatalogOption,
	MetricCatalogPageData,
	MetricCatalogPreviewVersion,
	MetricCatalogSourceTerm,
	MetricCatalogTradition,
	MetricLengthRule
} from '$lib/metrica/catalogo';

type UntypedSupabaseClient = {
	from: (table: string) => any;
};

type QueryError = {
	code?: string;
	message: string;
};

const FORM_SELECT =
	'forma_id,slug,nombre,definicion,nivel_estructural,tipo_registro,seleccionable,grado_especificacion,estado_revision,activo,orden,origen_termino_id,updated_at';
const CONFIGURATION_SELECT =
	'arquitectura_id,forma_id,slug,nombre,descripcion,principal,demarcable,grado,tipo_rima_id,unidad_versos_min,unidad_versos_max,estado_revision,activo,orden,origen_termino_id,updated_at';

function isMissingCatalogError(error: QueryError | null): boolean {
	return error?.code === '42P01' || error?.code === 'PGRST205' || error?.code === 'PGRST204';
}

function throwQueryError(context: string, error: QueryError | null): void {
	if (!error) return;
	throw new Error(`${context}: ${error.message}`);
}

function labelForVocabularyOption(row: {
	termino: string;
	etiqueta: string | null;
	numero_silabas?: number | null;
}): string {
	if (typeof row.numero_silabas === 'number') return `${row.numero_silabas} sílabas`;
	return row.etiqueta?.trim() || row.termino;
}

function emptyDomain(): MetricCatalogDomainData {
	return {
		forms: [],
		configurations: [],
		families: [],
		familyForms: [],
		traditions: [],
		formTraditions: [],
		aliases: [],
		formRelations: [],
		verseModels: [],
		verseSegments: [],
		metricPatterns: [],
		metricPositions: [],
		metricOptions: [],
		rhymePatterns: [],
		rhymePositions: [],
		rhymeLinks: [],
		rhymeRestrictions: [],
		patternCombinations: [],
		sections: [],
		repetitionPatterns: [],
		repetitionPositions: [],
		traits: [],
		traitValues: [],
		configurationTraits: [],
		choiceGroups: [],
		choiceOptions: [],
		sources: [],
		sourceClaims: []
	};
}

function emptyEditorSandbox() {
	return {
		scenarios: [],
		sequences: [],
		units: [],
		choices: [],
		deviations: []
	};
}

function buildIssues(input: {
	forms: MetricCatalogForm[];
	configurations: MetricCatalogConfiguration[];
	domain: MetricCatalogDomainData;
}): MetricCatalogIssue[] {
	const issues: MetricCatalogIssue[] = [];
	const configurationsByForm = new Map<string, MetricCatalogConfiguration[]>();

	for (const configuration of input.configurations) {
		configurationsByForm.set(configuration.forma_id, [
			...(configurationsByForm.get(configuration.forma_id) ?? []),
			configuration
		]);
	}

	for (const form of input.forms.filter(
		(item) => item.activo && item.grado_especificacion === 'especifica'
	)) {
		const configurations = (configurationsByForm.get(form.forma_id) ?? []).filter(
			(configuration) => configuration.activo
		);
		if (configurations.length === 0) {
			issues.push({
				code: 'forma_sin_configuracion',
				level: 'error',
				entityId: form.forma_id,
				label: form.nombre,
				message: 'No tiene ninguna configuración activa.'
			});
			continue;
		}
	}

	for (const configuration of input.configurations.filter(
		(item) => item.activo && item.demarcable
	)) {
		const hasStructuredModel =
			configuration.patrones_metro > 0 ||
			configuration.esquemas_rima > 0 ||
			configuration.tipo_rima_id !== null ||
			configuration.unidad_versos_min !== null;
		if (!hasStructuredModel) {
			issues.push({
				code: 'configuracion_sin_modelo',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message:
					'Está marcada como demarcable, pero aún no tiene ningún dato estructurado. Puede ser válida si la apertura es intencional.'
			});
		}
	}

	const configurationById = new Map(
		input.configurations.map((configuration) => [configuration.arquitectura_id, configuration])
	);
	const genericScopeConfigurationIds = new Set(
		[
			...input.domain.metricPatterns,
			...input.domain.rhymePatterns,
			...input.domain.repetitionPatterns
		]
			.filter((pattern) => pattern.ambito === 'unidad')
			.map((pattern) => String(pattern.arquitectura_id))
	);
	for (const configurationId of genericScopeConfigurationIds) {
		const configuration = configurationById.get(configurationId);
		if (!configuration) continue;
		issues.push({
			code: 'configuracion_con_ambito_generico',
			level: 'warning',
			entityId: configuration.arquitectura_id,
			label: configuration.nombre,
			message:
				'Conserva al menos un patrón importado con ámbito «unidad genérica». Debe precisarse como estrofa, serie, sección o composición.'
		});
	}
	const metricPositionPatternIds = new Set(
		input.domain.metricPositions.map((row) => String(row.esquema_metrico_id))
	);
	const metricOptionPatternIds = new Set(
		input.domain.metricOptions.map((row) => String(row.esquema_metrico_id))
	);
	const metricPatternsByConfiguration = new Map<
		string,
		MetricCatalogDomainData['metricPatterns']
	>();
	for (const pattern of input.domain.metricPatterns) {
		const configurationId = String(pattern.arquitectura_id);
		metricPatternsByConfiguration.set(configurationId, [
			...(metricPatternsByConfiguration.get(configurationId) ?? []),
			pattern
		]);
	}
	for (const [configurationId, patterns] of metricPatternsByConfiguration) {
		if (patterns.length < 2 || patterns.every((pattern) => String(pattern.nombre ?? '').trim())) {
			continue;
		}
		const configuration = configurationById.get(configurationId);
		if (!configuration) continue;
		issues.push({
			code: 'patron_metrico_sin_nombre',
			level: 'warning',
			entityId: configuration.arquitectura_id,
			label: configuration.nombre,
			message:
				'Tiene varios patrones métricos y alguno carece de nombre breve para distinguirlo en la interfaz.'
		});
	}
	for (const pattern of input.domain.metricPatterns) {
		const patternId = String(pattern.esquema_metrico_id);
		const configuration = configurationById.get(String(pattern.arquitectura_id));
		if (!configuration) continue;
		if (
			(pattern.tipo === 'secuencia_fija' || pattern.tipo === 'secuencia_repetible') &&
			!metricPositionPatternIds.has(patternId)
		) {
			issues.push({
				code: 'patron_metrico_sin_posiciones',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message: 'Tiene un patrón métrico ordenado sin posiciones declaradas.'
			});
		}
		if (pattern.tipo === 'conjunto_permitido' && !metricOptionPatternIds.has(patternId)) {
			issues.push({
				code: 'patron_metrico_sin_opciones',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message: 'Tiene un conjunto de medidas permitidas sin ninguna medida declarada.'
			});
		}
	}

	const rhymePositionPatternIds = new Set(
		input.domain.rhymePositions.map((row) => String(row.esquema_rima_id))
	);
	const rhymeRestrictionPatternIds = new Set(
		input.domain.rhymeRestrictions.map((row) => String(row.esquema_rima_id))
	);
	for (const pattern of input.domain.rhymePatterns) {
		const patternId = String(pattern.esquema_rima_id);
		const configuration = configurationById.get(String(pattern.arquitectura_id));
		if (!configuration) continue;
		if (pattern.comportamiento === 'pendiente_revision') {
			issues.push({
				code: 'patron_rima_comportamiento_pendiente',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message:
					'Tiene un patrón de rima importado cuyo comportamiento todavía no se ha formalizado.'
			});
			continue;
		}
		if (
			(pattern.comportamiento === 'secuencia_fija' ||
				pattern.comportamiento === 'secuencia_repetible') &&
			!rhymePositionPatternIds.has(patternId)
		) {
			issues.push({
				code: 'patron_rima_sin_regla',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message:
					'Tiene una secuencia de rima sin posiciones estructuradas. El esquema textual no basta para compilarla.'
			});
		}
		if (pattern.comportamiento === 'restricciones' && !rhymeRestrictionPatternIds.has(patternId)) {
			issues.push({
				code: 'patron_rima_sin_regla',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message: 'Declara reglas combinatorias, pero no tiene ninguna restricción estructurada.'
			});
		}
	}

	return issues;
}

export async function loadMetricCatalog(
	supabase: App.Locals['supabase']
): Promise<MetricCatalogPageData> {
	const db = supabase as unknown as UntypedSupabaseClient;
	const stateResponse = await db
		.from('catalogo_metrico_estado')
		.select('revision,modelo_version')
		.eq('id', true)
		.maybeSingle();

	if (stateResponse.error && !isMissingCatalogError(stateResponse.error)) {
		throwQueryError('No se pudo leer la revisión del catálogo métrico', stateResponse.error);
	}

	if (
		isMissingCatalogError(stateResponse.error) ||
		Number(stateResponse.data?.modelo_version ?? 0) < 45
	) {
		return {
			migrationPending: true,
			migrationMessage:
				'Falta aplicar una o más migraciones del nuevo catálogo métrico a esta base de datos.',
			revision: null,
			forms: [],
			configurations: [],
			lengthRules: [],
			families: [],
			traditions: [],
			migrationRows: [],
			previewVersions: [],
			domain: emptyDomain(),
			editorSandbox: emptyEditorSandbox(),
			options: { rhymeTypes: [], metres: [] },
			issues: [],
			stats: {
				forms: 0,
				approvedForms: 0,
				configurations: 0,
				pendingTerms: 0,
				priorityPendingTerms: 0,
				unresolvedTerms: 0
			}
		};
	}

	const [
		formsResponse,
		configurationsResponse,
		familiesResponse,
		familyFormsResponse,
		traditionsResponse,
		formTraditionsResponse,
		migrationResponse,
		destinationsResponse,
		sourceTermsResponse,
		metrePatternsResponse,
		rhymePatternsResponse,
		lengthRulesResponse,
		optionsResponse,
		previewVersionsResponse
	] = await Promise.all([
		db.from('formas_metricas').select(FORM_SELECT).order('nombre', { ascending: true }),
		db
			.from('arquitecturas_forma')
			.select(CONFIGURATION_SELECT)
			.order('principal', { ascending: false })
			.order('orden', { ascending: true })
			.order('nombre', { ascending: true }),
		db
			.from('familias_metricas')
			.select('familia_id,slug,nombre,descripcion,estado_revision,activo')
			.order('nombre', { ascending: true }),
		db.from('familias_formas').select('familia_id,forma_id'),
		db
			.from('tradiciones_metricas')
			.select('tradicion_id,slug,nombre,descripcion,estado_revision,activo')
			.order('nombre', { ascending: true }),
		db.from('formas_tradiciones').select('tradicion_id,forma_id'),
		db
			.from('migracion_terminos_metricos')
			.select(
				'termino_id,clasificacion_propuesta,clasificacion_decidida,propuesta,certeza,requiere_revision,estado_revision,notas_ip,revisado_en'
			),
		db
			.from('migracion_termino_destinos')
			.select(
				'destino_id,termino_id,tipo_operacion,forma_id,familia_id,arquitectura_id,variedad_id,esquema_metrico_id,esquema_rima_id,rasgo_id,valor_rasgo_id,alias_id'
			),
		db
			.from('vocabularios')
			.select('termino_id,termino,etiqueta,definicion,termino_padre_id')
			.eq('categoria', 'estrofa_tipo'),
		db.from('esquemas_metricos').select('esquema_metrico_id,arquitectura_id'),
		db.from('esquemas_rima').select('esquema_rima_id,arquitectura_id'),
		db
			.from('arquitecturas_reglas_longitud')
			.select(
				'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion'
			),
		db
			.from('vocabularios')
			.select('termino_id,categoria,termino,etiqueta,numero_silabas')
			.in('categoria', ['tipo_rima', 'metro'])
			.eq('activo', true),
		db
			.from('demarcador_versiones')
			.select(
				'version_id,numero,estado,catalogo_revision,fuente_actualizada_en,total_familias,total_familias_variantes,total_variantes_demarcables,generado_en'
			)
			.eq('fuente_tipo', 'catalogo_metrico')
			.order('generado_en', { ascending: false })
			.limit(10)
	]);

	const domainResponses = await Promise.all([
		db.from('familias_metricas').select('*').order('nombre'),
		db.from('familias_formas').select('*'),
		db.from('tradiciones_metricas').select('*').order('nombre'),
		db.from('formas_tradiciones').select('*'),
		db.from('denominaciones_metricas').select('*').order('nombre'),
		db.from('forma_relaciones').select('*'),
		db.from('metros').select('*').order('silabas'),
		db.from('metro_segmentos').select('*').order('posicion'),
		db.from('esquemas_metricos').select('*'),
		db.from('esquema_metrico_posiciones').select('*').order('posicion'),
		db.from('esquema_metrico_opciones').select('*').order('orden'),
		db.from('esquemas_rima').select('*'),
		db.from('esquema_rima_posiciones').select('*').order('posicion'),
		db.from('esquema_rima_enlaces').select('*'),
		db.from('esquema_rima_restricciones').select('*'),
		db.from('variedades_arquitectura').select('*').order('orden'),
		db.from('estructuras_secciones').select('*').order('orden'),
		db.from('repeticiones_metricas').select('*'),
		db.from('repeticion_posiciones').select('*').order('posicion'),
		db.from('rasgos_metricos').select('*').order('nombre'),
		db.from('rasgo_valores').select('*').order('orden'),
		db.from('arquitectura_rasgos').select('*'),
		db.from('grupos_eleccion_metrica').select('*').order('orden'),
		db.from('opciones_eleccion_metrica').select('*').order('orden'),
		db.from('fuentes_metricas').select('*').order('titulo'),
		db.from('afirmaciones_fuentes_metricas').select('*')
	]);
	for (const response of domainResponses) {
		throwQueryError('No se pudo cargar una sección del catálogo métrico', response.error);
	}
	const [
		familiesDomain,
		familyFormsDomain,
		traditionsDomain,
		formTraditionsDomain,
		aliasesDomain,
		formRelationsDomain,
		verseModelsDomain,
		verseSegmentsDomain,
		metricPatternsDomain,
		metricPositionsDomain,
		metricOptionsDomain,
		rhymePatternsDomain,
		rhymePositionsDomain,
		rhymeLinksDomain,
		rhymeRestrictionsDomain,
		patternCombinationsDomain,
		sectionsDomain,
		repetitionPatternsDomain,
		repetitionPositionsDomain,
		traitsDomain,
		traitValuesDomain,
		configurationTraitsDomain,
		choiceGroupsDomain,
		choiceOptionsDomain,
		sourcesDomain,
		sourceClaimsDomain
	] = domainResponses;
	const domain: MetricCatalogDomainData = {
		forms: formsResponse.data ?? [],
		configurations: configurationsResponse.data ?? [],
		families: familiesDomain.data ?? [],
		familyForms: familyFormsDomain.data ?? [],
		traditions: traditionsDomain.data ?? [],
		formTraditions: formTraditionsDomain.data ?? [],
		aliases: (aliasesDomain.data ?? []).map((row: any) => {
			const targetField = [
				'forma_id',
				'arquitectura_id',
				'esquema_metrico_id',
				'esquema_rima_id',
				'seccion_id',
				'repeticion_id'
			].find((field) => row[field]);
			return {
				...row,
				destino: targetField ? `${targetField}:${row[targetField]}` : null
			};
		}),
		formRelations: formRelationsDomain.data ?? [],
		verseModels: verseModelsDomain.data ?? [],
		verseSegments: verseSegmentsDomain.data ?? [],
		metricPatterns: metricPatternsDomain.data ?? [],
		metricPositions: (metricPositionsDomain.data ?? []).map((row: any) => ({
			...row,
			medida: row.metro_id ? `metro:${row.metro_id}` : null
		})),
		metricOptions: metricOptionsDomain.data ?? [],
		rhymePatterns: rhymePatternsDomain.data ?? [],
		rhymePositions: rhymePositionsDomain.data ?? [],
		rhymeLinks: rhymeLinksDomain.data ?? [],
		rhymeRestrictions: rhymeRestrictionsDomain.data ?? [],
		patternCombinations: patternCombinationsDomain.data ?? [],
		sections: sectionsDomain.data ?? [],
		repetitionPatterns: repetitionPatternsDomain.data ?? [],
		repetitionPositions: repetitionPositionsDomain.data ?? [],
		traits: traitsDomain.data ?? [],
		traitValues: traitValuesDomain.data ?? [],
		configurationTraits: configurationTraitsDomain.data ?? [],
		choiceGroups: choiceGroupsDomain.data ?? [],
		choiceOptions: (choiceOptionsDomain.data ?? []).map((row: any) => {
			const targetField = [
				'metro_id',
				'esquema_metrico_id',
				'esquema_rima_id',
				'variedad_id',
				'seccion_id',
				'repeticion_id',
				'rasgo_id',
				'valor_rasgo_id'
			].find((field) => row[field]);
			return {
				...row,
				objetivo: targetField ? `${targetField}:${row[targetField]}` : null
			};
		}),
		sources: sourcesDomain.data ?? [],
		sourceClaims: (sourceClaimsDomain.data ?? []).map((row: any) => {
			const targetField = [
				'forma_id',
				'familia_id',
				'tradicion_id',
				'arquitectura_id',
				'esquema_metrico_id',
				'esquema_rima_id',
				'rasgo_id'
			].find((field) => row[field]);
			return {
				...row,
				destino: targetField ? `${targetField}:${row[targetField]}` : null
			};
		})
	};

	throwQueryError('No se pudieron cargar las formas métricas', formsResponse.error);
	throwQueryError('No se pudieron cargar las configuraciones', configurationsResponse.error);
	throwQueryError('No se pudieron cargar las familias métricas', familiesResponse.error);
	throwQueryError('No se pudieron cargar las relaciones de familias', familyFormsResponse.error);
	throwQueryError('No se pudieron cargar las tradiciones métricas', traditionsResponse.error);
	throwQueryError(
		'No se pudieron cargar las relaciones de tradiciones',
		formTraditionsResponse.error
	);
	throwQueryError('No se pudo cargar la revisión inicial', migrationResponse.error);
	throwQueryError(
		'No se pudieron cargar los destinos de la importación',
		destinationsResponse.error
	);
	throwQueryError('No se pudieron cargar los términos de origen', sourceTermsResponse.error);
	throwQueryError('No se pudieron cargar los patrones métricos', metrePatternsResponse.error);
	throwQueryError('No se pudieron cargar los patrones de rima', rhymePatternsResponse.error);
	throwQueryError('No se pudieron derivar las reglas de longitud', lengthRulesResponse.error);
	throwQueryError('No se pudieron cargar las opciones métricas', optionsResponse.error);
	throwQueryError(
		'No se pudieron cargar las pruebas del demarcador',
		previewVersionsResponse.error
	);

	const forms = (formsResponse.data ?? []) as MetricCatalogForm[];
	const rawConfigurations = (configurationsResponse.data ?? []) as Array<
		Omit<MetricCatalogConfiguration, 'patrones_metro' | 'esquemas_rima'>
	>;
	const metrePatternCounts = new Map<string, number>();
	for (const row of metrePatternsResponse.data ?? []) {
		metrePatternCounts.set(
			row.arquitectura_id,
			(metrePatternCounts.get(row.arquitectura_id) ?? 0) + 1
		);
	}
	const rhymePatternCounts = new Map<string, number>();
	for (const row of rhymePatternsResponse.data ?? []) {
		rhymePatternCounts.set(
			row.arquitectura_id,
			(rhymePatternCounts.get(row.arquitectura_id) ?? 0) + 1
		);
	}
	const configurations: MetricCatalogConfiguration[] = rawConfigurations.map((row) => ({
		...row,
		patrones_metro: metrePatternCounts.get(row.arquitectura_id) ?? 0,
		esquemas_rima: rhymePatternCounts.get(row.arquitectura_id) ?? 0
	}));

	const familyFormCounts = new Map<string, number>();
	for (const row of familyFormsResponse.data ?? []) {
		familyFormCounts.set(row.familia_id, (familyFormCounts.get(row.familia_id) ?? 0) + 1);
	}
	const families: MetricCatalogFamily[] = (familiesResponse.data ?? []).map((row: any) => ({
		...row,
		formas: familyFormCounts.get(row.familia_id) ?? 0
	}));

	const traditionFormCounts = new Map<string, number>();
	for (const row of formTraditionsResponse.data ?? []) {
		traditionFormCounts.set(row.tradicion_id, (traditionFormCounts.get(row.tradicion_id) ?? 0) + 1);
	}
	const traditions: MetricCatalogTradition[] = (traditionsResponse.data ?? []).map((row: any) => ({
		...row,
		formas: traditionFormCounts.get(row.tradicion_id) ?? 0
	}));

	const sourceTerms = new Map<string, MetricCatalogSourceTerm>(
		((sourceTermsResponse.data ?? []) as MetricCatalogSourceTerm[]).map((row) => [
			row.termino_id,
			row
		])
	);
	const destinationsByTerm = new Map<string, MetricCatalogMigrationRow['destinos']>();
	for (const row of destinationsResponse.data ?? []) {
		destinationsByTerm.set(row.termino_id, [
			...(destinationsByTerm.get(row.termino_id) ?? []),
			row
		]);
	}
	const migrationRows: MetricCatalogMigrationRow[] = (migrationResponse.data ?? [])
		.map((row: Omit<MetricCatalogMigrationRow, 'fuente' | 'destinos'>) => ({
			...row,
			fuente: sourceTerms.get(row.termino_id) ?? {
				termino_id: row.termino_id,
				termino: row.termino_id,
				etiqueta: null,
				definicion: null,
				termino_padre_id: null
			},
			destinos: destinationsByTerm.get(row.termino_id) ?? []
		}))
		.sort((a: MetricCatalogMigrationRow, b: MetricCatalogMigrationRow) =>
			(a.fuente.etiqueta?.trim() || a.fuente.termino).localeCompare(
				b.fuente.etiqueta?.trim() || b.fuente.termino,
				'es'
			)
		);

	const optionsRows = optionsResponse.data ?? [];
	const toOptions = (category: string): MetricCatalogOption[] =>
		optionsRows
			.filter((row: any) => row.categoria === category)
			.map((row: any) => ({
				id: row.termino_id,
				slug: row.termino,
				label: labelForVocabularyOption(row)
			}))
			.sort((a: MetricCatalogOption, b: MetricCatalogOption) =>
				a.label.localeCompare(b.label, 'es', { numeric: true })
			);

	const issues = buildIssues({ forms, configurations, domain });
	const editorSandboxResponses = await Promise.all([
		db.from('escenarios_editor_metrico').select('*').order('updated_at', { ascending: false }),
		db.from('secuencias_editor_metrico').select('*').order('orden'),
		db.from('realizaciones_editor_metrico').select('*').order('orden'),
		db.from('elecciones_editor_metrico').select('*'),
		db.from('desviaciones_editor_metrico').select('*').order('v_ini')
	]);
	for (const response of editorSandboxResponses) {
		throwQueryError('No se pudo cargar el editor métrico de prueba', response.error);
	}
	const [
		editorScenariosResponse,
		editorSequencesResponse,
		editorUnitsResponse,
		editorChoicesResponse,
		editorDeviationsResponse
	] = editorSandboxResponses;
	const pendingTerms = migrationRows.filter((row) => row.estado_revision === 'pendiente');
	const unresolvedTerms = migrationRows.filter(
		(row) => row.destinos.length === 0 && row.clasificacion_propuesta !== 'D'
	);

	return {
		migrationPending: false,
		migrationMessage: null,
		revision: stateResponse.data?.revision ?? 1,
		forms,
		configurations,
		lengthRules: (lengthRulesResponse.data ?? []) as MetricLengthRule[],
		families,
		traditions,
		migrationRows,
		previewVersions: (previewVersionsResponse.data ?? []) as MetricCatalogPreviewVersion[],
		domain,
		editorSandbox: {
			scenarios: editorScenariosResponse.data ?? [],
			sequences: editorSequencesResponse.data ?? [],
			units: editorUnitsResponse.data ?? [],
			choices: editorChoicesResponse.data ?? [],
			deviations: editorDeviationsResponse.data ?? []
		},
		options: {
			rhymeTypes: toOptions('tipo_rima'),
			// Los metros son ya entidades del dominio, no términos del vocabulario genérico.
			metres: (verseModelsDomain.data ?? []).map((row: any) => ({
				id: String(row.metro_id),
				label: `${row.nombre} · ${row.silabas} sílabas${row.tipo === 'compuesto' ? ' (compuesto)' : ''}`
			}))
		},
		issues,
		stats: {
			forms: forms.filter((form) => form.activo).length,
			approvedForms: forms.filter((form) => form.activo && form.estado_revision === 'aprobada')
				.length,
			configurations: configurations.filter((configuration) => configuration.activo).length,
			pendingTerms: pendingTerms.length,
			priorityPendingTerms: pendingTerms.filter((row) => row.requiere_revision).length,
			unresolvedTerms: unresolvedTerms.length
		}
	};
}
