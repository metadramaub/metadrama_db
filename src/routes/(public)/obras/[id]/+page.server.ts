import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';

export const load: PageServerLoad = async ({ locals, params }) => {
	const viewer = await resolvePublicViewerContext(locals);
	const publicadoId = await getPublicadoEstadoId(locals);

	if (!publicadoId) {
		throw error(404, 'Obra no encontrada.');
	}

	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,titulo,variantes_titulo,autoria,edicion,analisis_editor,bibliografia,fuente_fecha,fecha_inicio_trad,fecha_fin_trad,fecha_inicio_metadrama,fecha_fin_metadrama,updated_at,visible_publico'
		)
		.eq('obra_id', params.id)
		.eq('estado', publicadoId);

	if (!viewer.canSeeAllPublished) {
		query = query.eq('visible_publico', true);
	}

	const { data, error: dbError } = await query.maybeSingle();
	if (dbError) {
		throw error(500, `No se pudo cargar la obra: ${dbError.message}`);
	}
	if (!data) {
		throw error(404, 'Obra no encontrada.');
	}

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		obra: data
	};
};
