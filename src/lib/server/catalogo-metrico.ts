import type {
	MetricCatalogConfiguration,
	MetricCatalogDomainData,
	MetricCatalogForm,
	MetricCatalogIssue,
	MetricCatalogOption,
	MetricCatalogPageData,
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
	'forma_id,slug,nombre,definicion,nivel_estructural,tipo_registro,activo,origen_termino_id,updated_at';
const CONFIGURATION_SELECT =
	'arquitectura_id,forma_id,slug,nombre,descripcion,principal,demarcable,modalidad,tipo_rima_id,unidad_versos_min,unidad_versos_max,intercalable,activo,orden,origen_termino_id,updated_at';

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

export function buildIssues(input: {
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

	// Toda forma con norma declara al menos una arquitectura. Los tramos sin forma quedan
	// fuera porque no tienen norma por diseño: «Verso aislado» y «Versificación irregular».
	for (const form of input.forms.filter(
		(item) => item.activo && item.tipo_registro !== 'sin_forma'
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
				message: 'No tiene ninguna arquitectura activa.'
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
				'Tiene varios esquemas métricos y alguno carece de nombre breve para distinguirlo en la interfaz.'
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
				message: 'Tiene un esquema métrico ordenado sin posiciones declaradas.'
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
	const rhymeDensityTraitIds = new Set(
		input.domain.traits
			.filter((row) => String(row.slug) === 'densidad_de_rima')
			.map((row) => String(row.rasgo_id))
	);
	const configurationsDeclaringRhymeDensity = new Set(
		input.domain.configurationTraits
			.filter((row) => rhymeDensityTraitIds.has(String(row.rasgo_id)))
			.map((row) => String(row.arquitectura_id))
	);
	const configurationsWithConcreteRhyme = new Set(
		input.domain.rhymePatterns
			.filter((row) => row.tipo_secuencia !== 'abierta')
			.map((row) => String(row.arquitectura_id))
	);
	for (const pattern of input.domain.rhymePatterns) {
		const patternId = String(pattern.esquema_rima_id);
		const configuration = configurationById.get(String(pattern.arquitectura_id));
		if (!configuration) continue;
		if (
			(pattern.tipo_secuencia === 'secuencia' || pattern.tipo_secuencia === 'ciclo') &&
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
		// Un esquema abierto no fija la disposición, y eso por sí solo no es un defecto: es lo que
		// hace una forma general. Solo lo es cuando la arquitectura entera no dice nada más de su
		// rima, y tiene tres maneras de decirlo —las restricciones del propio esquema, la densidad
		// declarada, o unos esquemas concretos que la realizan y de los que se calcula—.
		if (
			pattern.tipo_secuencia === 'abierta' &&
			!rhymeRestrictionPatternIds.has(patternId) &&
			!configurationsDeclaringRhymeDensity.has(String(pattern.arquitectura_id)) &&
			!configurationsWithConcreteRhyme.has(String(pattern.arquitectura_id))
		) {
			issues.push({
				code: 'patron_rima_sin_regla',
				level: 'warning',
				entityId: configuration.arquitectura_id,
				label: configuration.nombre,
				message:
					'Deja la disposición abierta y no declara ninguna restricción, ni su densidad de rima, ni ningún esquema concreto: no dice nada de su rima salvo el tipo.'
			});
		}
	}

	return issues;
}

/** El catálogo sin el sandbox: lo único que se puede guardar entre peticiones. */
type CatalogoCacheable = Omit<MetricCatalogPageData, 'editorSandbox'>;

/**
 * El catálogo construido, con la revisión con que se construyó.
 *
 * **Por qué se puede guardar en memoria del proceso y compartirlo entre peticiones.** Son unas
 * 2.400 filas que solo cambian cuando se aplica una migración, y **son las mismas para todo el que
 * las pide**: desde el 27 de agosto de 2026 el catálogo métrico se lee sin condiciones y
 * el demarcador son recursos públicos, y el equipo editorial lo necesita para anotar—.
 *
 * *Esa razón sustituye a la que había aquí*, que era más frágil: que `catalogo_metrico_estado`
 * fuera de admin o IP y por tanto haber leído la revisión demostrara verlo todo. Al abrirse la
 * lectura eso dejó de ser cierto, pero la conclusión mejoró: si nadie ve un catálogo distinto, no
 * hay nada que separar por visitante.
 *
 * *Y no caduca por tiempo, sino por dato:* mientras la revisión no cambie, lo guardado es exacto.
 */
let catalogoEnMemoria: { revision: number; valor: CatalogoCacheable } | null = null;

/**
 * Olvida el catálogo guardado.
 *
 * No hace falta en el curso normal —la revisión sube sola por disparador en las veinticinco tablas
 * del catálogo, y la petición siguiente lo reconstruye—, pero las pruebas necesitan poder empezar
 * de cero.
 */
export function olvidarCatalogoMetricoEnMemoria(): void {
	catalogoEnMemoria = null;
}

/**
 * Lo que el editor de pruebas tiene escrito. **Nunca se guarda en memoria**: cambia cada vez que un
 * editor toca algo, que es justo lo contrario del catálogo.
 */
async function cargarSandboxDelEditor(
	db: UntypedSupabaseClient
): Promise<MetricCatalogPageData['editorSandbox']> {
	const responses = await Promise.all([
		db.from('anotacion_escenarios_prueba').select('*').order('updated_at', { ascending: false }),
		db.from('anotaciones_metricas').select('*').order('orden'),
		db.from('anotacion_realizaciones').select('*').order('orden'),
		// La respuesta guarda el dato del catálogo que se eligió, no la opción que lo ofrecía,
		// para que las preguntas puedan regenerarse sin dejarla huérfana. La vista resuelve la
		// opción de vuelta, que es lo que el formulario pinta y marca como seleccionado.
		db.from('anotacion_elecciones_resueltas').select('*'),
		db.from('anotacion_desviaciones').select('*').order('v_ini')
	]);
	for (const response of responses) {
		throwQueryError('No se pudo cargar el editor métrico de prueba', response.error);
	}
	const [scenarios, sequences, units, choices, deviations] = responses;
	return {
		scenarios: scenarios.data ?? [],
		sequences: sequences.data ?? [],
		units: units.data ?? [],
		choices: choices.data ?? [],
		deviations: deviations.data ?? []
	};
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
		Number(stateResponse.data?.modelo_version ?? 0) < 56
	) {
		return {
			migrationPending: true,
			migrationMessage:
				'Falta aplicar una o más migraciones del nuevo catálogo métrico a esta base de datos.',
			revision: null,
			forms: [],
			configurations: [],
			lengthRules: [],
			traditions: [],
			domain: emptyDomain(),
			editorSandbox: emptyEditorSandbox(),
			options: { rhymeTypes: [], metres: [] },
			issues: [],
			stats: {
				forms: 0,
				configurations: 0,
			}
		};
	}

	// ------------------------------------------------------------------ La caché
	//
	// **Una consulta en vez de treinta.** Construir el catálogo son unas treinta consultas, cuatro
	// de ellas vistas derivadas que recorren el catálogo entero por funciones SQL. Medidas por
	// PostgREST, esas cuatro solas iban entre 750 y 1.500 ms cada una, porque salen todas a la vez
	// y compiten por la CPU de la instancia; la pantalla llegó a tardar seis segundos y a dar un 500
	// por `statement timeout`.
	//
	// Como el catálogo solo cambia por migración, basta con preguntar por su revisión —que ya se
	// leía aquí arriba— y devolver lo construido si no ha cambiado.
	const revision = Number(stateResponse.data?.revision ?? 1);
	if (catalogoEnMemoria?.revision === revision) {
		return { ...catalogoEnMemoria.valor, editorSandbox: await cargarSandboxDelEditor(db) };
	}

	const [catalogo, editorSandbox] = await Promise.all([
		construirCatalogoMetrico(db, revision),
		cargarSandboxDelEditor(db)
	]);
	catalogoEnMemoria = { revision, valor: catalogo };
	return { ...catalogo, editorSandbox };
}

/**
 * Lee el catálogo entero de la base y lo deja en la forma que consume la pantalla.
 *
 * Se llama **solo cuando la revisión ha cambiado**. Lo que devuelve se guarda tal cual, así que no
 * debe modificarse después: quien lo reciba lo comparte con las peticiones siguientes.
 */
async function construirCatalogoMetrico(
	db: UntypedSupabaseClient,
	revision: number
): Promise<CatalogoCacheable> {
	const [
		formsResponse,
		configurationsResponse,
		traditionsResponse,
		formTraditionsResponse,
		metrePatternsResponse,
		rhymePatternsResponse,
		lengthRulesResponse,
		optionsResponse
	] = await Promise.all([
		db.from('formas_metricas').select(FORM_SELECT).order('nombre', { ascending: true }),
		db
			.from('arquitecturas_forma')
			.select(CONFIGURATION_SELECT)
			.order('principal', { ascending: false })
			.order('orden', { ascending: true })
			.order('nombre', { ascending: true }),
		db
			.from('tradiciones_metricas')
			.select('tradicion_id,slug,nombre,descripcion,activo')
			.order('nombre', { ascending: true }),
		db.from('formas_tradiciones').select('tradicion_id,forma_id'),
		db.from('esquemas_metricos').select('esquema_metrico_id,arquitectura_id'),
		db.from('esquemas_rima').select('esquema_rima_id,arquitectura_id'),
		db
			.from('arquitecturas_reglas_longitud')
			.select(
				'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion,desplazamientos'
			),
		db
			.from('vocabularios')
			.select('termino_id,categoria,termino,etiqueta,numero_silabas')
			.in('categoria', ['tipo_rima', 'metro'])
			.eq('activo', true)
	]);

	const domainResponses = await Promise.all([
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
		db.from('grupos_eleccion_metrica_resueltos').select('*').order('orden'),
		db.from('opciones_eleccion_metrica').select('*').order('orden'),
		db.from('fuentes_metricas').select('*').order('titulo'),
		db.from('afirmaciones_fuentes_metricas').select('*')
	]);
	for (const response of domainResponses) {
		throwQueryError('No se pudo cargar una sección del catálogo métrico', response.error);
	}
	const [
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
	throwQueryError('No se pudieron cargar las tradiciones métricas', traditionsResponse.error);
	throwQueryError(
		'No se pudieron cargar las relaciones de tradiciones',
		formTraditionsResponse.error
	);
	throwQueryError('No se pudieron cargar los patrones métricos', metrePatternsResponse.error);
	throwQueryError('No se pudieron cargar los patrones de rima', rhymePatternsResponse.error);
	throwQueryError('No se pudieron derivar las reglas de longitud', lengthRulesResponse.error);
	throwQueryError('No se pudieron cargar las opciones métricas', optionsResponse.error);
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

	const traditionFormCounts = new Map<string, number>();
	for (const row of formTraditionsResponse.data ?? []) {
		traditionFormCounts.set(row.tradicion_id, (traditionFormCounts.get(row.tradicion_id) ?? 0) + 1);
	}
	const traditions: MetricCatalogTradition[] = (traditionsResponse.data ?? []).map((row: any) => ({
		...row,
		formas: traditionFormCounts.get(row.tradicion_id) ?? 0
	}));

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
	return {
		migrationPending: false,
		migrationMessage: null,
		revision,
		forms,
		configurations,
		lengthRules: (lengthRulesResponse.data ?? []) as MetricLengthRule[],
		traditions,
		domain,
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
			forms: forms.filter((form) => form.activo && form.tipo_registro === 'forma').length,
			configurations: configurations.filter((configuration) => configuration.activo).length,
		}
	};
}
