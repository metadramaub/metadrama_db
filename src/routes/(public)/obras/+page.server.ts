import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';
import type { Tables } from '$lib/types/database.types';

type PublicCatalogObra = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'fecha_inicio_metadrama'
	| 'fecha_fin_metadrama'
	| 'updated_at'
	| 'visible_publico'
> & {
	autoria_autores: string[];
};

export const load: PageServerLoad = async ({ locals }) => {
	const viewer = await resolvePublicViewerContext(locals);
	const publicadoId = await getPublicadoEstadoId(locals);

	if (!publicadoId) {
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			obras: [] as PublicCatalogObra[]
		};
	}

	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,titulo,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,updated_at,visible_publico'
		)
		.eq('estado', publicadoId)
		.order('titulo');

	if (!viewer.canSeeAllPublished) {
		query = query.eq('visible_publico', true);
	}

	const { data, error: dbError } = await query.limit(500);
	if (dbError) {
		throw error(500, `No se pudo cargar el catalogo publico: ${dbError.message}`);
	}

	const obraRows = (data ?? []) as PublicCatalogObra[];
	const obraIds = obraRows.map((obra) => obra.obra_id);
	if (obraIds.length === 0) {
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			obras: [] as PublicCatalogObra[]
		};
	}

	const jornadasResp = await locals.supabase
		.from('jornadas')
		.select('jornada_id,obra_id')
		.in('obra_id', obraIds);
	const jornadas = (jornadasResp.data ?? []) as Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'obra_id'>>;
	const jornadaIds = jornadas.map((jornada) => jornada.jornada_id);

	const [globalResp, jornadaResp] = await Promise.all([
		locals.supabase
			.from('atribuciones')
			.select('atribucion_id,obra_id,jornada_id')
			.eq('adoptada', true)
			.in('obra_id', obraIds),
		jornadaIds.length > 0
			? locals.supabase
					.from('atribuciones')
					.select('atribucion_id,obra_id,jornada_id')
					.eq('adoptada', true)
					.in('jornada_id', jornadaIds)
			: Promise.resolve({ data: [] as Pick<Tables<'atribuciones'>, 'atribucion_id' | 'obra_id' | 'jornada_id'>[] })
	]);

	const atribuciones = [
		...((globalResp.data ?? []) as Pick<Tables<'atribuciones'>, 'atribucion_id' | 'obra_id' | 'jornada_id'>[]),
		...((jornadaResp.data ?? []) as Pick<Tables<'atribuciones'>, 'atribucion_id' | 'obra_id' | 'jornada_id'>[])
	];
	const atribucionIds = [...new Set(atribuciones.map((row) => row.atribucion_id))];

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

	const jornadaToObra = new Map(jornadas.map((row) => [row.jornada_id, row.obra_id]));
	const atribucionToObra = new Map<string, string>();
	for (const atribucion of atribuciones) {
		const obraId = atribucion.obra_id ?? (atribucion.jornada_id ? jornadaToObra.get(atribucion.jornada_id) : null);
		if (!obraId) continue;
		atribucionToObra.set(atribucion.atribucion_id, obraId);
	}

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

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		obras: obraRows.map((obra) => ({
			...obra,
			autoria_autores: [...(obraAutores.get(obra.obra_id) ?? new Set<string>())].sort((a, b) =>
				a.localeCompare(b, 'es')
			)
		}))
	};
};
