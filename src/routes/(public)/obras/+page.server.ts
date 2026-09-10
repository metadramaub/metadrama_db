import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import {
	deriveCatalogBounds,
	isCatalogMetricFiltersVisible,
	isCatalogMetricSortVisible,
	isCatalogPerfilMetricoVisible,
	parseCatalogFilters,
	withCatalogVisibilityDefaults,
	type CatalogFilterOption,
	type CatalogFilterOptions,
	type CatalogStructureTramo,
	type CatalogTramo
} from '$lib/catalogo/catalog-filters';
import { buildSectionVisibilityMap } from '$lib/secciones-publicas';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';
import {
	buildPublicVocabularioMaps,
	loadPublicVocabulario,
	type PublicVocabularioMaps
} from '$lib/server/vocabulario-publico';
import { loadPublicSections, requireSectionVisible } from '$lib/server/secciones-publicas';
import type { Tables } from '$lib/types/database.types';

type PublicCatalogObra = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'slug'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'fecha_inicio_metadrama'
	| 'fecha_fin_metadrama'
	| 'total_versos'
	| 'updated_at'
	| 'visible_publico'
> & {
	autoria_autores: string[];
	genero_term: string | null;
	es_obra_asignada: boolean;
	// Perfil métrico precomputado (obras_resumen). Null si la sección métrica no
	// es visible para este visitante o la obra aún no tiene resumen.
	tramos: CatalogTramo[] | null;
	jornadas_tramos: CatalogStructureTramo[] | null;
	cuadros_tramos: CatalogStructureTramo[] | null;
	numero_efectivo_formas: number | null;
	densidad_transiciones: number | null;
	n_formas_distintas: number | null;
	// Facetas para filtros métricos (solo si el grupo de filtros métricos es visible).
	formas_presentes: string[] | null;
	metros_presentes: string[] | null;
	tipos_forma_presentes: string[] | null;
	variaciones_presentes: string[] | null;
	subtipos_presentes: string[] | null;
};

type ObraRow = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'slug'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'fecha_inicio_metadrama'
	| 'fecha_fin_metadrama'
	| 'total_versos'
	| 'genero_id'
	| 'updated_at'
	| 'visible_publico'
	| 'editor_asignado'
>;

function emptyFilterOptions(): CatalogFilterOptions {
	return {
		autores: [],
		generos: [],
		formas: [],
		metros: [],
		tiposForma: [],
		variaciones: [],
		subtipos: [],
		bounds: {
			datacion: null,
			versos: null,
			densidad: null
		}
	};
}

function setCatalogCacheHeaders(
	setHeaders: Parameters<PageServerLoad>[0]['setHeaders'],
	viewerScope: 'anon' | 'authenticated' | 'admin_ip'
) {
	if (viewerScope === 'anon') {
		setHeaders({
			'cache-control': 'public, max-age=60, s-maxage=300, stale-while-revalidate=600'
		});
		return;
	}
	setHeaders({
		'cache-control': 'private, no-store'
	});
}

const TIPO_FORMA_LABELS: Record<string, string> = {
	forma_espanola: 'Forma española',
	forma_italiana: 'Forma italiana'
};

type MetricFacetObra = Pick<
	PublicCatalogObra,
	| 'formas_presentes'
	| 'metros_presentes'
	| 'tipos_forma_presentes'
	| 'variaciones_presentes'
	| 'subtipos_presentes'
>;

type MetricFacetOptions = {
	formas: CatalogFilterOption[];
	metros: CatalogFilterOption[];
	tiposForma: CatalogFilterOption[];
	variaciones: CatalogFilterOption[];
	subtipos: CatalogFilterOption[];
};

/**
 * Opciones de filtro métrico a partir de los términos presentes en las obras
 * visibles. Las etiquetas visibles y la jerarquía (subtipo → forma padre) se
 * resuelven desde el vocabulario cacheado (slug → etiqueta), sin consultas extra.
 */
type CatalogoMetricoNombres = {
	formaLabels: Map<string, string>;
	metroLabels: Map<string, string>;
	/** clave `forma_slug/esquema_slug` → nombre visible del esquema. */
	esquemaLabels: Map<string, string>;
};

/**
 * Los nombres de las facetas métricas, leídos de las tablas del catálogo.
 *
 * No se usa aquí el mapa de vocabulario porque **indexa por slug a secas** y en el nivel 2 eso
 * pierde la mitad: 261 filas para 130 slugs distintos, con `octosilabica` en ocho formas y `abab`
 * en siete. Las tres tablas las lee cualquiera —su política es `catalogo_metrico_publico()`—.
 */
async function loadCatalogoMetricoNombres(locals: App.Locals): Promise<CatalogoMetricoNombres> {
	const [formasResp, metrosResp, esquemasResp] = await Promise.all([
		locals.supabase.from('formas_metricas').select('forma_id,slug,nombre'),
		locals.supabase.from('metros').select('slug,nombre'),
		locals.supabase
			.from('esquemas_rima')
			.select('slug,nombre,notacion,arquitecturas_forma!inner(forma_id)')
	]);

	type FormaRow = { forma_id: string; slug: string; nombre: string };
	type MetroRow = { slug: string; nombre: string };
	type EsquemaRow = {
		slug: string | null;
		nombre: string | null;
		notacion: string | null;
		arquitecturas_forma: { forma_id: string } | { forma_id: string }[] | null;
	};

	const formas = (formasResp.data ?? []) as FormaRow[];
	const formaSlugById = new Map(formas.map((forma) => [forma.forma_id, forma.slug]));
	const formaLabels = new Map(formas.map((forma) => [forma.slug, forma.nombre]));
	const metroLabels = new Map(
		((metrosResp.data ?? []) as MetroRow[]).map((metro) => [metro.slug, metro.nombre])
	);

	const esquemaLabels = new Map<string, string>();
	for (const esquema of (esquemasResp.data ?? []) as EsquemaRow[]) {
		if (!esquema.slug) continue;
		const arq = Array.isArray(esquema.arquitecturas_forma)
			? esquema.arquitecturas_forma[0]
			: esquema.arquitecturas_forma;
		const formaSlug = arq ? formaSlugById.get(arq.forma_id) : undefined;
		if (!formaSlug) continue;
		// El nombre del catálogo cuando lo hay —«Cruzada», «Cuartetos de rima abrazada»— y la
		// notación cuando no: un esquema sin nombre se reconoce por sus letras.
		esquemaLabels.set(
			`${formaSlug}/${esquema.slug}`,
			esquema.nombre ?? esquema.notacion ?? esquema.slug
		);
	}

	return { formaLabels, metroLabels, esquemaLabels };
}

function buildMetricFacetOptions(
	obras: MetricFacetObra[],
	vocabMaps: PublicVocabularioMaps,
	catalogo: CatalogoMetricoNombres
): MetricFacetOptions {
	const uniqueSlugs = (pick: (o: MetricFacetObra) => string[] | null): Set<string> => {
		const set = new Set<string>();
		for (const obra of obras) for (const slug of pick(obra) ?? []) set.add(slug);
		return set;
	};

	const toOptions = (slugs: Set<string>, labels: Map<string, string>): CatalogFilterOption[] =>
		[...slugs]
			.map((slug) => ({ id: slug, label: labels.get(slug) ?? slug }))
			.sort((a, b) => a.label.localeCompare(b.label, 'es'));

	return {
		formas: toOptions(uniqueSlugs((o) => o.formas_presentes), catalogo.formaLabels),
		// **Esquemas de rima, no subtipos de estrofa.** La faceta cambió de contenido el 7 de
		// septiembre de 2026 y de clave el 10, cuando pasó a `forma_slug/esquema_slug`: el slug del
		// esquema no identifica uno —`abab` está en siete formas— y sin la forma no había manera de
		// colgarlo de la suya. El `parentId` es esa forma, que es lo que anida el selector.
		subtipos: [...uniqueSlugs((o) => o.subtipos_presentes)]
			.map((clave) => ({
				id: clave,
				label: catalogo.esquemaLabels.get(clave) ?? clave.slice(clave.indexOf('/') + 1),
				parentId: clave.includes('/') ? clave.slice(0, clave.indexOf('/')) : null
			}))
			.sort((a, b) => a.label.localeCompare(b.label, 'es')),
		metros: toOptions(uniqueSlugs((o) => o.metros_presentes), catalogo.metroLabels),
		// Las caracterizaciones —cantado, prosa— sí son vocabulario, y del vivo: es donde vive hoy
		// `secuencias_caracterizaciones_rango`. No tiene nada que ver con el vocabulario métrico
		// legado.
		variaciones: toOptions(
			uniqueSlugs((o) => o.variaciones_presentes),
			vocabMaps.labelBySlug.get('caracterizacion_rango') ?? new Map<string, string>()
		),
		tiposForma: [...uniqueSlugs((o) => o.tipos_forma_presentes)]
			.map((slug) => ({ id: slug, label: TIPO_FORMA_LABELS[slug] ?? slug }))
			.sort((a, b) => a.label.localeCompare(b.label, 'es'))
	};
}

export const load: PageServerLoad = async ({ locals, setHeaders, url }) => {
	await requireSectionVisible(locals, 'catalogo');

	const [viewer, sections, publicadoId] = await Promise.all([
		resolvePublicViewerContext(locals),
		loadPublicSections(locals),
		getPublicadoEstadoId(locals)
	]);
	const catalogVisibility = withCatalogVisibilityDefaults(buildSectionVisibilityMap(sections, viewer.scope));
	setCatalogCacheHeaders(setHeaders, viewer.scope);

	if (!publicadoId) {
		const filterOptions = emptyFilterOptions();
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			catalogVisibility,
			obras: [] as PublicCatalogObra[],
			filterOptions,
			initialFilters: parseCatalogFilters(url.searchParams, filterOptions, catalogVisibility)
		};
	}

	// **Una sola consulta.** El resumen viene incrustado, así que la página no encadena una lectura
	// por cada cosa que enseña: antes eran seis —la obra, su perfil métrico, y cuatro más para
	// reconstruir quién firma— y ahora es esta. Su RLS es la misma que la del muro, de modo que
	// incrustarlo no enseña ninguna obra que la consulta no fuera a devolver.
	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,slug,titulo,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,total_versos,genero_id,updated_at,visible_publico,editor_asignado,' +
				'obras_resumen(autores,tramos,jornadas_tramos,cuadros_tramos,numero_efectivo_formas,densidad_transiciones,n_formas_distintas,formas_presentes,metros_presentes,tipos_forma_presentes,variaciones_presentes,subtipos_presentes)'
		)
		.eq('estado', publicadoId)
		.order('titulo');

	// Muro: estado=publicado siempre (arriba). Sobre eso, una obra no visible solo la
	// ven admin/IP (canSeeAllPublished) y el editor asignado a esa obra concreta.
	if (!viewer.canSeeAllPublished) {
		if (viewer.userId) {
			query = query.or(`visible_publico.eq.true,editor_asignado.eq.${viewer.userId}`);
		} else {
			query = query.eq('visible_publico', true);
		}
	}

	const { data, error: dbError } = await query.limit(500);
	if (dbError) {
		throw error(500, `No se pudo cargar el catálogo público: ${dbError.message}`);
	}

	// Por `unknown`: la consulta incrusta el resumen y el tipo generado no lo reconoce en el `select`.
	const obraRows = (data ?? []) as unknown as ObraRow[];
	const obraIds = obraRows.map((obra) => obra.obra_id);
	if (obraIds.length === 0) {
		const filterOptions = emptyFilterOptions();
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			catalogVisibility,
			obras: [] as PublicCatalogObra[],
			filterOptions,
			initialFilters: parseCatalogFilters(url.searchParams, filterOptions, catalogVisibility)
		};
	}

	// Vocabulario público cacheado (una sola fuente para género + facetas métricas).
	// Las etiquetas se resuelven aquí desde el slug; el resumen nunca guarda etiquetas.
	const vocabMaps: PublicVocabularioMaps = buildPublicVocabularioMaps(
		await loadPublicVocabulario(locals)
	);
	const generoTermById = vocabMaps.labelByTerminoId;

	// Perfil métrico precomputado: solo se trae (y se serializa al cliente) si el
	// visitante puede ver el orden/filtros métricos o el perfil en resultados. La RLS
	// de obras_resumen ya limita las filas a obras visibles para este visitante.
	const wantsMetricFilters = isCatalogMetricFiltersVisible(catalogVisibility);
	const wantsMetric =
		wantsMetricFilters ||
		isCatalogMetricSortVisible(catalogVisibility) ||
		isCatalogPerfilMetricoVisible(catalogVisibility);
	type ResumenRow = Pick<
		Tables<'obras_resumen'>,
		| 'autores'
		| 'tramos'
		| 'jornadas_tramos'
		| 'cuadros_tramos'
		| 'numero_efectivo_formas'
		| 'densidad_transiciones'
		| 'n_formas_distintas'
		| 'formas_presentes'
		| 'metros_presentes'
		| 'tipos_forma_presentes'
		| 'variaciones_presentes'
		| 'subtipos_presentes'
	>;
	/**
	 * El resumen de una obra, que llegó incrustado en la consulta.
	 *
	 * **Y no sale del servidor si su sección está apagada.** El perfil venía antes de una consulta
	 * aparte que solo se hacía cuando era visible; ahora llega siempre —viaja con la obra—, así que
	 * la puerta se pone aquí: una sección apagada devuelve `null`, no un `{#if}` en la pantalla.
	 */
	const resumenDe = (obra: ObraRow): ResumenRow | null => {
		if (!wantsMetric) return null;
		const incrustado = (obra as unknown as { obras_resumen?: ResumenRow | ResumenRow[] | null })
			.obras_resumen;
		return (Array.isArray(incrustado) ? incrustado[0] : incrustado) ?? null;
	};

	/** Quién firma, que no depende de la sección métrica. */
	const autoresDe = (obra: ObraRow): string[] => {
		const incrustado = (obra as unknown as { obras_resumen?: ResumenRow | ResumenRow[] | null })
			.obras_resumen;
		const fila = Array.isArray(incrustado) ? incrustado[0] : incrustado;
		return [...(fila?.autores ?? [])].sort((a, b) => a.localeCompare(b, 'es'));
	};

	const obras: PublicCatalogObra[] = obraRows.map((fila): PublicCatalogObra => {
		const { editor_asignado, genero_id, ...obra } = fila;
			const resumen = resumenDe(fila);
			return {
				...obra,
				genero_term: genero_id ? (generoTermById.get(genero_id) ?? null) : null,
				es_obra_asignada: Boolean(viewer.userId) && editor_asignado === viewer.userId,
				// **Quién firma viene guardado.** Solo cuenta el grupo de atribución con una sola
				// propuesta, que es la regla que este mismo cargador aplicaba reconstruyéndola.
				autoria_autores: autoresDe(fila),
				tramos: (resumen?.tramos as CatalogTramo[] | null) ?? null,
				jornadas_tramos: (resumen?.jornadas_tramos as CatalogStructureTramo[] | null) ?? null,
				cuadros_tramos: (resumen?.cuadros_tramos as CatalogStructureTramo[] | null) ?? null,
				numero_efectivo_formas: resumen?.numero_efectivo_formas ?? null,
				densidad_transiciones: resumen?.densidad_transiciones ?? null,
				n_formas_distintas: resumen?.n_formas_distintas ?? null,
				// Las facetas solo se serializan al cliente si el panel de filtros métricos
				// es visible (respeta scope_minimo y evita payload innecesario).
				formas_presentes: wantsMetricFilters ? (resumen?.formas_presentes ?? null) : null,
				metros_presentes: wantsMetricFilters ? (resumen?.metros_presentes ?? null) : null,
				tipos_forma_presentes: wantsMetricFilters ? (resumen?.tipos_forma_presentes ?? null) : null,
				variaciones_presentes: wantsMetricFilters ? (resumen?.variaciones_presentes ?? null) : null,
				subtipos_presentes: wantsMetricFilters ? (resumen?.subtipos_presentes ?? null) : null
			};
		}
	);

	const autorOptions: CatalogFilterOption[] = [...new Set(obras.flatMap((o) => o.autoria_autores))]
		.sort((a, b) => a.localeCompare(b, 'es'))
		.map((nombre) => ({ id: nombre, label: nombre }));
	const generoOptions: CatalogFilterOption[] = [
		...new Set(obras.map((o) => o.genero_term).filter((t): t is string => Boolean(t)))
	]
		.sort((a, b) => a.localeCompare(b, 'es'))
		.map((term) => ({ id: term, label: term }));

	// Facetas métricas: etiquetas + jerarquía resueltas desde el vocabulario cacheado.
	const metricFacets = wantsMetricFilters
		? buildMetricFacetOptions(obras, vocabMaps, await loadCatalogoMetricoNombres(locals))
		: { formas: [], metros: [], tiposForma: [], variaciones: [], subtipos: [] };

	const filterOptions: CatalogFilterOptions = {
		autores: autorOptions,
		generos: generoOptions,
		formas: metricFacets.formas,
		metros: metricFacets.metros,
		tiposForma: metricFacets.tiposForma,
		variaciones: metricFacets.variaciones,
		subtipos: metricFacets.subtipos,
		bounds: deriveCatalogBounds(obras)
	};

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		catalogVisibility,
		obras,
		filterOptions,
		initialFilters: parseCatalogFilters(url.searchParams, filterOptions, catalogVisibility)
	};
};
