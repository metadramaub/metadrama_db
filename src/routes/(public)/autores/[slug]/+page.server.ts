import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getWikidataAuthorData } from '$lib/server/wikidata-images';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { buildPublicVocabularioMaps, loadPublicVocabulario } from '$lib/server/vocabulario-publico';
import type { AutorPublicoPayload, AutorResumen } from '$lib/autores/perfil-autor';

export const load: PageServerLoad = async ({ fetch, locals, params }) => {
	await requireSectionVisible(locals, 'autores');

	const viewer = await resolvePublicViewerContext(locals);

	// Identidad + obras asociadas (anon no puede leer `autores`: vía RPC SECURITY DEFINER).
	// La RPC decide internamente si incluye obras no visibles (admin/IP); no se le pasa flag.
	const { data: rpcData, error: rpcError } = await locals.supabase.rpc('get_autor_publico', {
		p_slug: params.slug
	});

	if (rpcError) {
		throw error(500, 'No se pudo cargar el autor.');
	}
	const payload = rpcData as AutorPublicoPayload | null;
	if (!payload) {
		throw error(404, 'Autor no encontrado.');
	}

	// Perfil métrico agregado: alcance por rol (RLS reparte; pedimos el que corresponde).
	const alcance = viewer.canSeeAllPublished ? 'completo' : 'publico';
	const { data: resumenData } = await locals.supabase
		.from('autores_resumen')
		.select(
			'perfil_formas,perfil_formas_hijos,numero_efectivo_formas_medio,numero_efectivo_formas_agregado,total_versos_autor,n_obras_completas,n_jornadas_sueltas'
		)
		.eq('autor_id', payload.autor.autor_id)
		.eq('alcance', alcance)
		.maybeSingle();

	const resumen = (resumenData as AutorResumen | null) ?? null;

	// Sin nada que mostrar para un visitante normal: 404 (no delatar autores vacíos).
	if (!viewer.canSeeAllPublished && payload.obras.length === 0 && !resumen) {
		throw error(404, 'Autor no encontrado.');
	}

	// Etiquetas de vocabulario (slug → etiqueta) desde el loader cacheado: el resumen
	// guarda slugs; la etiqueta visible se resuelve en lectura.
	const vocab = buildPublicVocabularioMaps(await loadPublicVocabulario(locals));
	const generoLabels = vocab.labelBySlug.get('genero') ?? new Map<string, string>();
	const formaLabels = Object.fromEntries(vocab.labelBySlug.get('estrofa_tipo') ?? new Map());
	// Slug hijo → slug raíz, para reconstruir la jerarquía de formas en el desglose del perfil.
	const formaParents = Object.fromEntries(vocab.parentSlugBySlug.get('estrofa_tipo') ?? new Map());

	const obras = payload.obras.map((obra) => ({
		...obra,
		genero_term: obra.genero_term ? (generoLabels.get(obra.genero_term) ?? obra.genero_term) : null
	}));
	const wikidata = await getWikidataAuthorData(payload.autor.wikidata_id, fetch);

	return {
		autor: payload.autor,
		wikidata,
		obras,
		resumen,
		formaLabels,
		formaParents,
		canSeeAllPublished: viewer.canSeeAllPublished
	};
};
