import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import {
	resolveObraScope,
	resolvePublicViewerContext,
	type PublicObraVisibility
} from '$lib/server/public-obras';
import { loadPublicSections } from '$lib/server/secciones-publicas';
import { buildSectionVisibilityMap } from '$lib/secciones-publicas';
import { applyFichaSectionVisibility } from '$lib/server/ficha-secciones';
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
		.select('obra_id,editor_asignado,visible_publico')
		.eq('slug', params.slug)
		.maybeSingle();

	if (obraVisibilityResp.error) {
		throw error(500, `No se pudo resolver la obra pública: ${obraVisibilityResp.error.message}`);
	}
	if (!obraVisibilityResp.data) {
		throw error(404, 'Obra no encontrada.');
	}

	const obraId = obraVisibilityResp.data.obra_id;
	const obraVisibility = obraVisibilityResp.data as PublicObraVisibility;
	const obraScope = resolveObraScope(viewer, obraVisibility);
	const includeHidden = obraScope === 'admin_ip';

	const supabase = locals.supabase as typeof locals.supabase & {
		rpc: (
			fn: 'get_obra_ficha_publica' | 'get_obra_comentarios_publicos',
			args: { p_obra_id: string; p_include_hidden?: boolean }
		) => Promise<{ data: unknown; error: { message: string } | null }>;
	};

	const [fichaResp, comentariosResp] = await Promise.all([
		supabase.rpc('get_obra_ficha_publica', {
			p_obra_id: obraId,
			p_include_hidden: includeHidden
		}),
		supabase.rpc('get_obra_comentarios_publicos', {
			p_obra_id: obraId,
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

	const rawFicha = {
		...(data as unknown as PublicObraFichaPayload),
		comentarios_publicos: (comentariosResp.data ?? []) as unknown as PublicFichaComentarioPublico[]
	} satisfies PublicObraFichaPayload;

	// Recorta los bloques cuya sección esté apagada o restringida para el scope
	// EFECTIVO de esta obra. El dato no sale del servidor (no es solo {#if}).
	const sections = await loadPublicSections(locals);
	const visibility = buildSectionVisibilityMap(sections, obraScope);
	const ficha = applyFichaSectionVisibility(rawFicha, visibility);

	return {
		viewerScope: obraScope,
		canSeeAllPublished: includeHidden,
		sectionVisibility: visibility,
		ficha
	};
};
