import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import type {
	PublicFichaComentarioPublico,
	PublicObraFichaPayload
} from '$lib/types/public-ficha.types';

export const load: PageServerLoad = async ({ locals, params }) => {
	const viewer = await resolvePublicViewerContext(locals);

	const supabase = locals.supabase as typeof locals.supabase & {
		rpc: (
			fn: 'get_obra_ficha_publica' | 'get_obra_comentarios_publicos',
			args: { p_obra_id: string; p_include_hidden?: boolean }
		) => Promise<{ data: unknown; error: { message: string } | null }>;
	};

	const [fichaResp, comentariosResp] = await Promise.all([
		supabase.rpc('get_obra_ficha_publica', {
			p_obra_id: params.id,
			p_include_hidden: viewer.canSeeAllPublished
		}),
		supabase.rpc('get_obra_comentarios_publicos', {
			p_obra_id: params.id,
			p_include_hidden: viewer.canSeeAllPublished
		})
	]);
	const { data, error: rpcError } = fichaResp;

	if (rpcError) {
		throw error(500, `No se pudo cargar la ficha pública: ${rpcError.message}`);
	}
	if (comentariosResp.error) {
		throw error(500, `No se pudieron cargar los comentarios públicos: ${comentariosResp.error.message}`);
	}
	if (!data) {
		throw error(404, 'Obra no encontrada.');
	}

	const ficha = data as unknown as PublicObraFichaPayload;

	return {
		viewerScope: viewer.scope,
		canSeeAllPublished: viewer.canSeeAllPublished,
		ficha: {
			...ficha,
			comentarios_publicos: (comentariosResp.data ?? []) as unknown as PublicFichaComentarioPublico[]
		} satisfies PublicObraFichaPayload
	};
};
