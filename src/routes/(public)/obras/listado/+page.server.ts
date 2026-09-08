import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import type { Tables } from '$lib/types/database.types';

type PublicObraListItem = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'slug'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'total_versos'
	| 'updated_at'
	| 'visible_publico'
> & {
	es_obra_asignada: boolean;
};

type ObraRow = PublicObraListItem & {
	editor_asignado: string | null;
};

function setObrasListCacheHeaders(
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

export const load: PageServerLoad = async ({ locals, setHeaders }) => {
	await requireSectionVisible(locals, 'catalogo');

	const [viewer, publicadoId] = await Promise.all([
		resolvePublicViewerContext(locals),
		getPublicadoEstadoId(locals)
	]);
	setObrasListCacheHeaders(setHeaders, viewer.scope);

	if (!publicadoId) {
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			obras: [] as PublicObraListItem[]
		};
	}

	let query = locals.supabase
		.from('obras')
		.select('obra_id,slug,titulo,fecha_inicio_trad,fecha_fin_trad,total_versos,updated_at,visible_publico,editor_asignado')
		.eq('estado', publicadoId)
		.order('titulo');

	if (!viewer.canSeeAllPublished) {
		if (viewer.userId) {
			query = query.or(`visible_publico.eq.true,editor_asignado.eq.${viewer.userId}`);
		} else {
			query = query.eq('visible_publico', true);
		}
	}

	const { data, error: dbError } = await query.limit(500);
	if (dbError) {
		throw error(500, `No se pudo cargar el listado público de obras: ${dbError.message}`);
	}

	const obras: PublicObraListItem[] = ((data ?? []) as ObraRow[]).map(
		({ editor_asignado, ...obra }) => ({
			...obra,
			es_obra_asignada: Boolean(viewer.userId) && editor_asignado === viewer.userId
		})
	);

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		obras
	};
};
