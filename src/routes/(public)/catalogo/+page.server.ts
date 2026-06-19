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
function buildMetricFacetOptions(
	obras: MetricFacetObra[],
	vocabMaps: PublicVocabularioMaps
): MetricFacetOptions {
	const uniqueSlugs = (pick: (o: MetricFacetObra) => string[] | null): Set<string> => {
		const set = new Set<string>();
		for (const obra of obras) for (const slug of pick(obra) ?? []) set.add(slug);
		return set;
	};

	const estrofaLabels = vocabMaps.labelBySlug.get('estrofa_tipo') ?? new Map<string, string>();
	const estrofaParents = vocabMaps.parentSlugBySlug.get('estrofa_tipo') ?? new Map<string, string>();

	const toOptions = (slugs: Set<string>, labels: Map<string, string>): CatalogFilterOption[] =>
		[...slugs]
			.map((slug) => ({ id: slug, label: labels.get(slug) ?? slug }))
			.sort((a, b) => a.label.localeCompare(b.label, 'es'));

	return {
		formas: toOptions(uniqueSlugs((o) => o.formas_presentes), estrofaLabels),
		// Subtipos: llevan el slug de su forma raíz como parentId para anidarlos
		// (p. ej. subquintillas bajo quintilla) en el selector único de forma.
		subtipos: [...uniqueSlugs((o) => o.subtipos_presentes)]
			.map((slug) => ({
				id: slug,
				label: estrofaLabels.get(slug) ?? slug,
				parentId: estrofaParents.get(slug) ?? null
			}))
			.sort((a, b) => a.label.localeCompare(b.label, 'es')),
		metros: toOptions(
			uniqueSlugs((o) => o.metros_presentes),
			vocabMaps.labelBySlug.get('metro') ?? new Map<string, string>()
		),
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

	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,slug,titulo,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,total_versos,genero_id,updated_at,visible_publico,editor_asignado'
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

	const obraRows = (data ?? []) as ObraRow[];
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

	const gruposResp = await locals.supabase
		.from('grupos_atribucion')
		.select('grupo_atribucion_id,obra_id')
		.in('obra_id', obraIds);
	const grupos = (gruposResp.data ?? []) as Array<
		Pick<Tables<'grupos_atribucion'>, 'grupo_atribucion_id' | 'obra_id'>
	>;
	const grupoIds = grupos.map((grupo) => grupo.grupo_atribucion_id);

	const atribucionesResp =
		grupoIds.length > 0
			? await locals.supabase
					.from('atribuciones')
					.select('atribucion_id,grupo_atribucion_id')
					.in('grupo_atribucion_id', grupoIds)
			: { data: [] as Pick<Tables<'atribuciones'>, 'atribucion_id' | 'grupo_atribucion_id'>[] };
	const atribuciones = (atribucionesResp.data ?? []) as Pick<
		Tables<'atribuciones'>,
		'atribucion_id' | 'grupo_atribucion_id'
	>[];
	const atribucionesByGrupo = new Map<string, string[]>();
	for (const atribucion of atribuciones) {
		if (!atribucion.grupo_atribucion_id) continue;
		const current = atribucionesByGrupo.get(atribucion.grupo_atribucion_id) ?? [];
		current.push(atribucion.atribucion_id);
		atribucionesByGrupo.set(atribucion.grupo_atribucion_id, current);
	}
	const atribucionToObra = new Map<string, string>();
	for (const grupo of grupos) {
		if (!grupo.obra_id) continue;
		const atribucionIdsForGroup = atribucionesByGrupo.get(grupo.grupo_atribucion_id) ?? [];
		if (atribucionIdsForGroup.length !== 1) continue;
		atribucionToObra.set(atribucionIdsForGroup[0], grupo.obra_id);
	}
	const atribucionIds = [...atribucionToObra.keys()];

	const atribucionAutoresResp =
		atribucionIds.length > 0
			? await locals.supabase
					.from('atribucion_autores')
					.select('atribucion_id,autor_id')
					.in('atribucion_id', atribucionIds)
			: { data: [] as Pick<Tables<'atribucion_autores'>, 'atribucion_id' | 'autor_id'>[] };
	const atribucionAutores = (atribucionAutoresResp.data ?? []) as Pick<
		Tables<'atribucion_autores'>,
		'atribucion_id' | 'autor_id'
	>[];

	const authorIds = [...new Set(atribucionAutores.map((row) => row.autor_id))];
	const autoresResp =
		authorIds.length > 0
			? await locals.supabase.from('autores').select('autor_id,nombre_completo,slug').in('autor_id', authorIds)
			: { data: [] as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'slug'>[] };
	const autores = (autoresResp.data ?? []) as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'slug'>[];

	const authorNameById = new Map(autores.map((row) => [row.autor_id, row.nombre_completo]));
	const obraAutores = new Map<string, Set<string>>();
	for (const link of atribucionAutores) {
		const obraId = atribucionToObra.get(link.atribucion_id);
		if (!obraId) continue;
		const authorName = authorNameById.get(link.autor_id);
		if (!authorName) continue;
		const current = obraAutores.get(obraId) ?? new Set<string>();
		current.add(authorName);
		obraAutores.set(obraId, current);
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
		| 'tramos'
		| 'numero_efectivo_formas'
		| 'densidad_transiciones'
		| 'n_formas_distintas'
		| 'formas_presentes'
		| 'metros_presentes'
		| 'tipos_forma_presentes'
		| 'variaciones_presentes'
		| 'subtipos_presentes'
	>;
	const resumenByObra = new Map<string, ResumenRow>();
	if (wantsMetric) {
		const resumenResp = await locals.supabase
			.from('obras_resumen')
			.select(
				'obra_id,tramos,numero_efectivo_formas,densidad_transiciones,n_formas_distintas,formas_presentes,metros_presentes,tipos_forma_presentes,variaciones_presentes,subtipos_presentes'
			)
			.in('obra_id', obraIds);
		for (const row of (resumenResp.data ?? []) as Array<ResumenRow & { obra_id: string }>) {
			resumenByObra.set(row.obra_id, row);
		}
	}

	const obras: PublicCatalogObra[] = obraRows.map(
		({ editor_asignado, genero_id, ...obra }): PublicCatalogObra => {
			const resumen = resumenByObra.get(obra.obra_id) ?? null;
			return {
				...obra,
				genero_term: genero_id ? (generoTermById.get(genero_id) ?? null) : null,
				es_obra_asignada: Boolean(viewer.userId) && editor_asignado === viewer.userId,
				autoria_autores: [...(obraAutores.get(obra.obra_id) ?? new Set<string>())].sort((a, b) =>
					a.localeCompare(b, 'es')
				),
				tramos: (resumen?.tramos as CatalogTramo[] | null) ?? null,
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
		? buildMetricFacetOptions(obras, vocabMaps)
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
