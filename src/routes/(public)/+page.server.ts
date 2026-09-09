import type { PageServerLoad } from './$types';
import type { CatalogStructureTramo, CatalogTramo } from '$lib/catalogo/catalog-filters';
import { PORTADA_AUTORES_DESTACADOS, PORTADA_OBRA_DESTACADA_ID } from '$lib/config/portada';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { getWikidataImage } from '$lib/server/wikidata-images';

type PortadaStats = {
	obras: number;
	autores: number;
	versos: number;
	formas: number;
	datacionInicio: number | null;
	datacionFin: number | null;
};

type PortadaObraDestacada = {
	slug: string;
	titulo: string;
	total_versos: number | null;
	tramos: CatalogTramo[];
	jornadas_tramos: CatalogStructureTramo[];
	cuadros_tramos: CatalogStructureTramo[];
};

type PortadaPayload = {
	stats: PortadaStats;
	featuredObra: PortadaObraDestacada | null;
};

const EMPTY_STATS: PortadaStats = {
	obras: 0,
	autores: 0,
	versos: 0,
	formas: 0,
	datacionInicio: null,
	datacionFin: null
};

function setPortadaCacheHeaders(
	setHeaders: Parameters<PageServerLoad>[0]['setHeaders'],
	viewerScope: 'anon' | 'authenticated' | 'admin_ip'
) {
	if (viewerScope === 'anon') {
		setHeaders({
			'cache-control': 'public, max-age=60, s-maxage=300, stale-while-revalidate=600'
		});
		return;
	}
	setHeaders({ 'cache-control': 'private, no-store' });
}

export const load: PageServerLoad = async ({ fetch, locals, setHeaders }) => {
	const [viewer, portadaResp, autores] = await Promise.all([
		resolvePublicViewerContext(locals),
		locals.supabase.rpc('get_portada_publica', {
			p_obra_destacada_id: PORTADA_OBRA_DESTACADA_ID
		}),
		Promise.all(
			PORTADA_AUTORES_DESTACADOS.map(async (autor) => ({
				slug: autor.slug,
				nombre_completo: autor.nombre_completo,
				imagen_wikidata: await getWikidataImage(autor.wikidata_id, fetch)
			}))
		)
	]);

	setPortadaCacheHeaders(setHeaders, viewer.scope);
	const payload = (portadaResp.error ? null : portadaResp.data) as PortadaPayload | null;

	return {
		autores,
		featuredObra: payload?.featuredObra ?? null,
		stats: payload?.stats ?? EMPTY_STATS
	};
};
