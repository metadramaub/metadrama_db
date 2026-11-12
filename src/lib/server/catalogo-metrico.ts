import type {
	MetricCatalogConfiguration,
	MetricCatalogDomainData,
	MetricCatalogForm,
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

/**
 * Cuántas filas se piden de una vez. **No puede pasar del `max_rows` de la API de Supabase**, que en
 * este proyecto es el de serie: 1000. Si se pidiera más de lo que el servidor da, la primera página
 * llegaría corta y `leerTodo` creería que la tabla se ha acabado.
 */
const PAGINA = 1000;

/**
 * Lee una tabla o una vista entera, página a página.
 *
 * **PostgREST no devuelve nunca más de 1000 filas por petición, y cuando corta no avisa**: ni error
 * ni marca, solo menos filas. El catálogo se leía de una vez, y en noviembre de 2026
 * `opciones_eleccion_metrica` pasó de las mil: el editor perdió en silencio las 96 últimas por
 * `orden`, que eran las medidas de los versos 10 a 15 de la canción y la asonancia u-o del romance,
 * entre otras. Una editora no pudo dar medida al último verso de una sirima.
 *
 * `clave` desempata el orden con columnas que juntas son únicas. Sin ella, dos filas con el mismo
 * `orden` pueden caer en cualquiera de las dos páginas, y una se repite mientras otra se pierde:
 * el corte de noviembre cayó justo en un empate de treinta opciones con `orden` 20.
 */
async function leerTodo(
	construir: () => any,
	clave: string[]
	// `data` sigue siendo `any`, como lo era la respuesta del cliente sin tipos que esto sustituye.
	// Tiparla destapa que `options.metres` no lleva el `slug` de `MetricCatalogOption`, que es
	// otro asunto.
): Promise<{ data: any; error: QueryError | null }> {
	const filas: any[] = [];
	for (let desde = 0; ; desde += PAGINA) {
		let consulta = construir();
		for (const columna of clave) consulta = consulta.order(columna, { ascending: true });
		const { data, error } = await consulta.range(desde, desde + PAGINA - 1);
		if (error) return { data: filas, error };
		filas.push(...(data ?? []));
		if (!data || data.length < PAGINA) return { data: filas, error: null };
	}
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
		leerTodo(
			() =>
				db.from('anotacion_escenarios_prueba').select('*').order('updated_at', { ascending: false }),
			['escenario_id']
		),
		leerTodo(() => db.from('anotaciones_metricas').select('*').order('orden'), ['anotacion_id']),
		leerTodo(
			() => db.from('anotacion_realizaciones').select('*').order('orden'),
			['realizacion_id']
		),
		// La respuesta guarda el dato del catálogo que se eligió, no la opción que lo ofrecía,
		// para que las preguntas puedan regenerarse sin dejarla huérfana. La vista resuelve la
		// opción de vuelta, que es lo que el formulario pinta y marca como seleccionado.
		leerTodo(() => db.from('anotacion_elecciones_resueltas').select('*'), ['eleccion_id']),
		leerTodo(() => db.from('anotacion_desviaciones').select('*').order('v_ini'), ['desviacion_id'])
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
	supabase: App.Locals['supabase'],
	{ incluirSandbox = false }: { incluirSandbox?: boolean } = {}
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
		return { ...catalogoEnMemoria.valor, editorSandbox: incluirSandbox ? await cargarSandboxDelEditor(db) : emptyEditorSandbox() };
	}

	const [catalogo, editorSandbox] = await Promise.all([
		construirCatalogoMetrico(db, revision),
		incluirSandbox ? cargarSandboxDelEditor(db) : emptyEditorSandbox()
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
		leerTodo(
			() => db.from('formas_metricas').select(FORM_SELECT).order('nombre', { ascending: true }),
			['forma_id']
		),
		leerTodo(
			() =>
				db
					.from('arquitecturas_forma')
					.select(CONFIGURATION_SELECT)
					.order('principal', { ascending: false })
					.order('orden', { ascending: true })
					.order('nombre', { ascending: true }),
			['arquitectura_id']
		),
		leerTodo(
			() =>
				db
					.from('tradiciones_metricas')
					.select('tradicion_id,slug,nombre,descripcion,activo')
					.order('nombre', { ascending: true }),
			['tradicion_id']
		),
		leerTodo(
			() => db.from('formas_tradiciones').select('tradicion_id,forma_id'),
			['forma_id', 'tradicion_id']
		),
		leerTodo(
			() => db.from('esquemas_metricos').select('esquema_metrico_id,arquitectura_id'),
			['esquema_metrico_id']
		),
		leerTodo(
			() => db.from('esquemas_rima').select('esquema_rima_id,arquitectura_id'),
			['esquema_rima_id']
		),
		leerTodo(
			() =>
				db
					.from('arquitecturas_reglas_longitud')
					.select(
						'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion,desplazamientos'
					),
			['arquitectura_id']
		),
		leerTodo(
			() =>
				db
					.from('vocabularios')
					.select('termino_id,categoria,termino,etiqueta,numero_silabas')
					.in('categoria', ['tipo_rima', 'metro'])
					.eq('activo', true),
			['termino_id']
		)
	]);

	// Cada lectura lleva su clave única —la primaria, o la que es única en la vista— para que la
	// paginación no repita ni pierda filas en los empates del orden. Ver `leerTodo`.
	const domainResponses = await Promise.all([
		leerTodo(() => db.from('tradiciones_metricas').select('*').order('nombre'), ['tradicion_id']),
		leerTodo(() => db.from('formas_tradiciones').select('*'), ['forma_id', 'tradicion_id']),
		leerTodo(() => db.from('denominaciones_metricas').select('*').order('nombre'), ['alias_id']),
		leerTodo(() => db.from('forma_relaciones').select('*'), ['relacion_id']),
		leerTodo(() => db.from('metros').select('*').order('silabas'), ['metro_id']),
		leerTodo(() => db.from('metro_segmentos').select('*').order('posicion'), ['segmento_id']),
		leerTodo(() => db.from('esquemas_metricos').select('*'), ['esquema_metrico_id']),
		leerTodo(
			() => db.from('esquema_metrico_posiciones').select('*').order('posicion'),
			['posicion_id']
		),
		leerTodo(
			() => db.from('esquema_metrico_opciones').select('*').order('orden'),
			['esquema_metrico_id', 'metro_id']
		),
		leerTodo(() => db.from('esquemas_rima').select('*'), ['esquema_rima_id']),
		leerTodo(
			() => db.from('esquema_rima_posiciones').select('*').order('posicion'),
			['posicion_id']
		),
		leerTodo(() => db.from('esquema_rima_enlaces').select('*'), ['enlace_id']),
		leerTodo(() => db.from('esquema_rima_restricciones').select('*'), ['restriccion_id']),
		leerTodo(() => db.from('variedades_arquitectura').select('*').order('orden'), ['variedad_id']),
		leerTodo(() => db.from('estructuras_secciones').select('*').order('orden'), ['seccion_id']),
		leerTodo(() => db.from('repeticiones_metricas').select('*'), ['repeticion_id']),
		leerTodo(() => db.from('repeticion_posiciones').select('*').order('posicion'), ['posicion_id']),
		leerTodo(() => db.from('rasgos_metricos').select('*').order('nombre'), ['rasgo_id']),
		leerTodo(() => db.from('rasgo_valores').select('*').order('orden'), ['valor_id']),
		// Su índice único trata los nulos como iguales; ordenar por las cuatro columnas basta.
		leerTodo(
			() => db.from('arquitectura_rasgos').select('*'),
			['arquitectura_id', 'rasgo_id', 'modalidad', 'valor_id']
		),
		leerTodo(
			() => db.from('grupos_eleccion_metrica_resueltos').select('*').order('orden'),
			['grupo_eleccion_id']
		),
		leerTodo(
			() => db.from('opciones_eleccion_metrica').select('*').order('orden'),
			['opcion_eleccion_id']
		),
		leerTodo(() => db.from('fuentes_metricas').select('*').order('titulo'), ['fuente_id']),
		leerTodo(() => db.from('afirmaciones_fuentes_metricas').select('*'), ['afirmacion_id'])
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
				label: `${row.nombre} — ${row.silabas} sílabas${row.tipo === 'compuesto' ? ' (compuesto)' : ''}`
			}))
		},
		stats: {
			forms: forms.filter((form) => form.activo && form.tipo_registro === 'forma').length,
			configurations: configurations.filter((configuration) => configuration.activo).length,
		}
	};
}
