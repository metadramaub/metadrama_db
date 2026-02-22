import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import type { PublicObraFichaPayload } from '$lib/types/public-ficha.types';

export const load: PageServerLoad = async ({ locals, params }) => {
	const viewer = await resolvePublicViewerContext(locals);

	const supabase = locals.supabase as typeof locals.supabase & {
		rpc: (
			fn: 'get_obra_ficha_publica',
			args: { p_obra_id: string; p_include_hidden?: boolean }
		) => Promise<{ data: unknown; error: { message: string } | null }>;
	};

	const { data, error: rpcError } = await supabase.rpc('get_obra_ficha_publica', {
		p_obra_id: params.id,
		p_include_hidden: viewer.canSeeAllPublished
	});

	if (rpcError) {
		throw error(500, `No se pudo cargar la ficha pública: ${rpcError.message}`);
	}
	if (!data) {
		throw error(404, 'Obra no encontrada.');
	}

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		ficha: data as PublicObraFichaPayload
	};
};
