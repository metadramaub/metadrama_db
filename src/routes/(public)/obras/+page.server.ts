import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';

export const load: PageServerLoad = async ({ locals }) => {
	const viewer = await resolvePublicViewerContext(locals);
	const publicadoId = await getPublicadoEstadoId(locals);

	if (!publicadoId) {
		return {
			viewerScope: viewer.scope,
			canSeeAllPublished: viewer.canSeeAllPublished,
			obras: []
		};
	}

	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,titulo,autoria,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,updated_at,visible_publico'
		)
		.eq('estado', publicadoId)
		.order('titulo');

	if (!viewer.canSeeAllPublished) {
		query = query.eq('visible_publico', true);
	}

	const { data, error: dbError } = await query.limit(500);
	if (dbError) {
		throw error(500, `No se pudo cargar el catálogo público: ${dbError.message}`);
	}

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		obras: data ?? []
	};
};
