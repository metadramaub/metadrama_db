import type { PageServerLoad } from './$types';
import { canReadAllObras } from '$lib/utils/permissions';
import type { Tables } from '$lib/types/database.types';

export const load: PageServerLoad = async ({ locals, parent, url }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	const q = url.searchParams.get('q')?.trim() ?? '';
	const estado = url.searchParams.get('estado') ?? '';
	const editor = url.searchParams.get('editor') ?? '';

	let query = locals.supabase.from('obras').select('*').order('updated_at', { ascending: false });

	if (!canReadAllObras(profile.roleTerm)) {
		query = query.eq('editor_asignado', profile.userId);
	} else if (editor) {
		query = query.eq('editor_asignado', editor);
	}

	if (estado) {
		query = query.eq('estado', estado);
	}
	if (q) {
		query = query.ilike('titulo', `%${q}%`);
	}

	const { data: obras } = await query.limit(200);
	const obraRows = (obras ?? []) as Tables<'obras'>[];
	const estadoIds = [...new Set(obraRows.map((obra) => obra.estado))];
	const editorIds = [
		...new Set(obraRows.map((obra) => obra.editor_asignado).filter(Boolean) as string[])
	];

	const [estadoResp, editoresResp, estadoOptionsResp, editoresOptionsResp] = await Promise.all([
		estadoIds.length
			? locals.supabase
					.from('vocabularios')
					.select('termino_id, termino')
					.eq('categoria', 'estado')
					.in('termino_id', estadoIds)
			: Promise.resolve({ data: [] }),
		editorIds.length
			? locals.supabase.from('editores').select('user_id,nombre_completo').in('user_id', editorIds)
			: Promise.resolve({ data: [] }),
		locals.supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'estado')
			.order('orden'),
		canReadAllObras(profile.roleTerm)
			? locals.supabase.from('editores').select('user_id,nombre_completo').eq('activo', true)
			: Promise.resolve({ data: [] })
	]);

	const estadoMap = new Map(
		(estadoResp.data ?? []).map((estadoItem) => [estadoItem.termino_id, estadoItem.termino])
	);
	const editoresMap = new Map(
		(editoresResp.data ?? []).map((row) => [row.user_id, row.nombre_completo])
	);

	return {
		profile,
		filters: { q, estado, editor },
		estadoOptions: estadoOptionsResp.data ?? [],
		editorOptions: editoresOptionsResp.data ?? [],
		obras: obraRows.map((obra) => ({
			...obra,
			estadoTerm: estadoMap.get(obra.estado) ?? obra.estado,
			editorNombre: obra.editor_asignado
				? (editoresMap.get(obra.editor_asignado) ?? 'Sin nombre')
				: 'Sin asignar'
		}))
	};
};
