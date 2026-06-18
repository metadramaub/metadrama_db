import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import {
	resolveObraScope,
	resolvePublicViewerContext,
	type PublicObraVisibility
} from '$lib/server/public-obras';
import type {
	PublicFichaComentarioPublico,
	PublicObraFichaPayload
} from '$lib/types/public-ficha.types';

export const load: PageServerLoad = async ({ locals, params }) => {
	const viewer = await resolvePublicViewerContext(locals);

	// El scope efectivo depende de ESTA obra: el editor asignado la ve como admin/IP.
	// Necesitamos editor_asignado/visible_publico antes de llamar a la RPC para decidir
	// si incluir la versión "no visible" (p_include_hidden). El muro estado=publicado lo
	// sigue aplicando la propia RPC, así que esta consulta previa no expone nada.
	const obraVisibilityResp = await locals.supabase
		.from('obras')
		.select('editor_asignado,visible_publico')
		.eq('obra_id', params.id)
		.maybeSingle();
	const obraVisibility = (obraVisibilityResp.data ?? null) as PublicObraVisibility | null;
	const obraScope = obraVisibility
		? resolveObraScope(viewer, obraVisibility)
		: viewer.scope;
	const includeHidden = obraScope === 'admin_ip';

	const supabase = locals.supabase as typeof locals.supabase & {
		rpc: (
			fn: 'get_obra_ficha_publica' | 'get_obra_comentarios_publicos',
			args: { p_obra_id: string; p_include_hidden?: boolean }
		) => Promise<{ data: unknown; error: { message: string } | null }>;
	};

	const [fichaResp, comentariosResp] = await Promise.all([
		supabase.rpc('get_obra_ficha_publica', {
			p_obra_id: params.id,
			p_include_hidden: includeHidden
		}),
		supabase.rpc('get_obra_comentarios_publicos', {
			p_obra_id: params.id,
			p_include_hidden: includeHidden
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
		viewerScope: obraScope,
		canSeeAllPublished: includeHidden,
		ficha: {
			...ficha,
			comentarios_publicos: (comentariosResp.data ?? []) as unknown as PublicFichaComentarioPublico[]
		} satisfies PublicObraFichaPayload
	};
};
