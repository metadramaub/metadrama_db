import type { PageServerLoad } from './$types';
import { buildObraCapabilities } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';
import { error } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals, parent, url }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	const q = url.searchParams.get('q')?.trim() ?? '';
	const estado = url.searchParams.get('estado') ?? '';
	const editor = url.searchParams.get('editor') ?? '';
	const requestedScope = (url.searchParams.get('scope') ?? '').trim().toLowerCase();
	const scope = requestedScope === 'all' ? 'all' : 'mine';
	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';

	const reviewerAssignedResp = await locals.supabase
		.from('obras_revisores')
		.select('obra_id')
		.eq('revisor_id', profile.userId);
	if (reviewerAssignedResp.error) {
		throw error(500, `No se pudieron cargar asignaciones de revisor: ${reviewerAssignedResp.error.message}`);
	}
	const reviewerAssignedIds = [...new Set((reviewerAssignedResp.data ?? []).map((row) => row.obra_id))];
	const reviewerAssignedSet = new Set(reviewerAssignedIds);

	let query = locals.supabase.from('obras').select('*').order('updated_at', { ascending: false });

	if (scope === 'mine') {
		if (isAdminOrIp) {
			// Admin/IP: "Mis obras" is all works.
		} else if (reviewerAssignedIds.length > 0) {
			query = query.or(
				`editor_asignado.eq.${profile.userId},obra_id.in.(${reviewerAssignedIds.join(',')})`
			);
		} else {
			query = query.eq('editor_asignado', profile.userId);
		}
	}

	if (editor && isAdminOrIp) {
		query = query.eq('editor_asignado', editor);
	}
	if (estado) {
		query = query.eq('estado', estado);
	}
	if (q) {
		query = query.ilike('titulo', `%${q}%`);
	}

	const { data: obras, error: obrasError } = await query.limit(200);
	if (obrasError) {
		throw error(500, `No se pudieron cargar las obras: ${obrasError.message}`);
	}

	const obraRows = (obras ?? []) as Tables<'obras'>[];
	const estadoIds = [...new Set(obraRows.map((obra) => obra.estado))];
	const editorIds = [...new Set(obraRows.map((obra) => obra.editor_asignado).filter(Boolean) as string[])];

	const [estadoResp, editoresResp, estadoOptionsResp, editoresOptionsResp] = await Promise.all([
		estadoIds.length > 0
			? locals.supabase
					.from('vocabularios')
					.select('termino_id, termino')
					.eq('categoria', 'estado')
					.in('termino_id', estadoIds)
			: Promise.resolve({ data: [] }),
		editorIds.length > 0
			? locals.supabase.from('editores').select('user_id,nombre_completo').in('user_id', editorIds)
			: Promise.resolve({ data: [] }),
		locals.supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'estado')
			.order('orden'),
		isAdminOrIp
			? locals.supabase.from('editores').select('user_id,nombre_completo').eq('activo', true)
			: Promise.resolve({ data: [] })
	]);

	const estadoError = 'error' in estadoResp ? estadoResp.error : null;
	const editoresError = 'error' in editoresResp ? editoresResp.error : null;
	const estadoOptionsError = 'error' in estadoOptionsResp ? estadoOptionsResp.error : null;
	const editoresOptionsError = 'error' in editoresOptionsResp ? editoresOptionsResp.error : null;
	if (estadoError) {
		throw error(500, `No se pudieron cargar los estados: ${estadoError.message}`);
	}
	if (editoresError) {
		throw error(500, `No se pudieron cargar los editores: ${editoresError.message}`);
	}
	if (estadoOptionsError) {
		throw error(500, `No se pudo cargar el vocabulario de estados: ${estadoOptionsError.message}`);
	}
	if (editoresOptionsError) {
		throw error(500, `No se pudo cargar el listado de editores: ${editoresOptionsError.message}`);
	}

	const estadoMap = new Map((estadoResp.data ?? []).map((estadoItem) => [estadoItem.termino_id, estadoItem.termino]));
	const editoresMap = new Map((editoresResp.data ?? []).map((row) => [row.user_id, row.nombre_completo]));

	return {
		profile,
		scope,
		filters: { q, estado, editor },
		estadoOptions: estadoOptionsResp.data ?? [],
		editorOptions: editoresOptionsResp.data ?? [],
		obras: obraRows.map((obra) => {
			const estadoTerm = estadoMap.get(obra.estado) ?? obra.estado;
			const capabilities = buildObraCapabilities(
				profile,
				obra,
				estadoTerm.toLowerCase(),
				reviewerAssignedSet.has(obra.obra_id)
			);
			return {
				...obra,
				estadoTerm,
				editorNombre: obra.editor_asignado
					? (editoresMap.get(obra.editor_asignado) ?? 'Sin nombre')
					: 'Sin asignar',
				...capabilities
			};
		})
	};
};
