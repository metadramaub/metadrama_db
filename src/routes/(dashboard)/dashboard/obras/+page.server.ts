import type { PageServerLoad } from './$types';
import { buildObraCapabilities } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { resolveDashboardObrasScopePlan } from '$lib/server/dashboard-obras';
import type { Tables } from '$lib/types/database.types';
import { error } from '@sveltejs/kit';

const SCOPE_COOKIE = 'dashboard_obras_scope';
const OBRAS_LIST_SELECT = 'obra_id,titulo,slug,estado,editor_asignado,updated_at,visible_publico';
type DashboardObraRow = Pick<
	Tables<'obras'>,
	'obra_id' | 'titulo' | 'slug' | 'estado' | 'editor_asignado' | 'updated_at' | 'visible_publico'
>;

export const load: PageServerLoad = async ({ locals, parent, url, cookies }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	// Ámbito "Mis obras / Todas las obras": se recuerda por sesión. Si la URL no trae
	// ?scope, se usa la cookie de sesión (última selección); el resuelto se re-persiste.
	const explicitScope = url.searchParams.get('scope');
	const rawScope = (explicitScope ?? cookies.get(SCOPE_COOKIE) ?? '').trim().toLowerCase();
	const scope = rawScope === 'all' ? 'all' : 'mine';
	cookies.set(SCOPE_COOKIE, scope, { path: '/dashboard/obras', sameSite: 'lax' });
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

	let query = locals.supabase.from('obras').select(OBRAS_LIST_SELECT).order('updated_at', { ascending: false });

	if (scope === 'mine') {
		const scopePlan = resolveDashboardObrasScopePlan(scope, profile.userId, reviewerAssignedIds);
		if (scopePlan.mode === 'editor_or_reviewer') {
			query = query.or(
				`editor_asignado.eq.${scopePlan.editorAssignedUserId},obra_id.in.(${scopePlan.reviewerAssignedIds.join(',')})`
			);
		} else if (scopePlan.mode === 'editor_only') {
			query = query.eq('editor_asignado', scopePlan.editorAssignedUserId);
		}
	}

	const { data: obras, error: obrasError } = await query.limit(200);
	if (obrasError) {
		throw error(500, `No se pudieron cargar las obras: ${obrasError.message}`);
	}

	const obraRows = (obras ?? []) as DashboardObraRow[];
	const editorIds = [...new Set(obraRows.map((obra) => obra.editor_asignado).filter(Boolean) as string[])];

	const [estadoOptions, editoresResp, editoresOptionsResp] = await Promise.all([
		loadInternalVocabulario(locals.supabase, ['estado']),
		editorIds.length > 0
			? locals.supabase.from('editores').select('user_id,nombre_completo').in('user_id', editorIds)
			: Promise.resolve({ data: [] }),
		isAdminOrIp
			? locals.supabase.from('editores').select('user_id,nombre_completo').eq('activo', true)
			: Promise.resolve({ data: [] })
	]);

	const editoresError = 'error' in editoresResp ? editoresResp.error : null;
	const editoresOptionsError = 'error' in editoresOptionsResp ? editoresOptionsResp.error : null;
	if (editoresError) {
		throw error(500, `No se pudieron cargar los editores: ${editoresError.message}`);
	}
	if (editoresOptionsError) {
		throw error(500, `No se pudo cargar el listado de editores: ${editoresOptionsError.message}`);
	}

	const estadoMap = new Map(estadoOptions.map((estadoItem) => [estadoItem.termino_id, estadoItem.termino]));
	const editoresMap = new Map((editoresResp.data ?? []).map((row) => [row.user_id, row.nombre_completo]));

	return {
		profile,
		scope,
		estadoOptions,
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
