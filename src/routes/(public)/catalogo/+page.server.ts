import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import {
	deriveCatalogBounds,
	parseCatalogFilters,
	withCatalogVisibilityDefaults,
	type CatalogFilterOption,
	type CatalogFilterOptions
} from '$lib/catalogo/catalog-filters';
import { buildSectionVisibilityMap } from '$lib/secciones-publicas';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';
import { loadPublicSections, requireSectionVisible } from '$lib/server/secciones-publicas';
import type { Tables } from '$lib/types/database.types';
import { displayTerm } from '$lib/utils/vocabulario';

type PublicCatalogObra = Pick<
	Tables<'obras'>,
	| 'obra_id'
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
};

type ObraRow = Pick<
	Tables<'obras'>,
	| 'obra_id'
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
		bounds: {
			datacion: null,
			versos: null
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
			'obra_id,titulo,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,total_versos,genero_id,updated_at,visible_publico,editor_asignado'
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
			? await locals.supabase.from('autores').select('autor_id,nombre_completo').in('autor_id', authorIds)
			: { data: [] as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>[] };
	const autores = (autoresResp.data ?? []) as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>[];

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

	const generoIds = [...new Set(obraRows.map((o) => o.genero_id).filter((id): id is string => Boolean(id)))];
	const generosResp =
		generoIds.length > 0
			? await locals.supabase.from('vocabularios').select('termino_id,termino,etiqueta').in('termino_id', generoIds)
			: { data: [] as Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>[] };
	const generoTermById = new Map(
		((generosResp.data ?? []) as Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>[]).map((row) => [
			row.termino_id,
			displayTerm(row)
		])
	);

	const obras: PublicCatalogObra[] = obraRows.map(
		({ editor_asignado, genero_id, ...obra }): PublicCatalogObra => ({
			...obra,
			genero_term: genero_id ? (generoTermById.get(genero_id) ?? null) : null,
			es_obra_asignada: Boolean(viewer.userId) && editor_asignado === viewer.userId,
			autoria_autores: [...(obraAutores.get(obra.obra_id) ?? new Set<string>())].sort((a, b) =>
				a.localeCompare(b, 'es')
			)
		})
	);

	const autorOptions: CatalogFilterOption[] = [...new Set(obras.flatMap((o) => o.autoria_autores))]
		.sort((a, b) => a.localeCompare(b, 'es'))
		.map((nombre) => ({ id: nombre, label: nombre }));
	const generoOptions: CatalogFilterOption[] = [
		...new Set(obras.map((o) => o.genero_term).filter((t): t is string => Boolean(t)))
	]
		.sort((a, b) => a.localeCompare(b, 'es'))
		.map((term) => ({ id: term, label: term }));

	const filterOptions: CatalogFilterOptions = {
		autores: autorOptions,
		generos: generoOptions,
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
