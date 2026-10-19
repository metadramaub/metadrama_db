import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { buildObraCapabilities, requireEditorProfile } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { obraCreateSchema, queryFilterSchema } from '$lib/utils/validators';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { createObras } from '$lib/server/create-obras';


export const GET: RequestHandler = async ({ locals, url }) => {
	const profile = await requireEditorProfile({ locals });
	const requestedScope = (url.searchParams.get('scope') ?? '').trim().toLowerCase();
	const scope = requestedScope === 'all' ? 'all' : 'mine';
	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';

	const parsed = queryFilterSchema.safeParse({
		q: url.searchParams.get('q') ?? undefined,
		estado: url.searchParams.get('estado') ?? undefined,
		editor: url.searchParams.get('editor') ?? undefined,
		page: url.searchParams.get('page') ?? 1,
		pageSize: url.searchParams.get('pageSize') ?? 20
	});
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { q, estado, editor, page, pageSize } = parsed.data;
	const from = (page - 1) * pageSize;
	const to = from + pageSize - 1;

	const reviewerAssignments = await locals.supabase
		.from('obras_revisores')
		.select('obra_id')
		.eq('revisor_id', profile.userId);
	if (reviewerAssignments.error) {
		return json(
			{
				error: 'db_error',
				message: reviewerAssignments.error.message ?? 'No se pudieron cargar asignaciones'
			},
			{ status: 500 }
		);
	}
	const reviewerAssignedIds = [...new Set((reviewerAssignments.data ?? []).map((row) => row.obra_id))];
	const reviewerAssignedSet = new Set(reviewerAssignedIds);

	let query = locals.supabase
		.from('obras')
		.select('*', { count: 'exact' })
		.order('updated_at', { ascending: false })
		.range(from, to);

	if (scope === 'mine') {
		if (isAdminOrIp) {
			// Admin/IP: "mine" includes all works.
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
	if (q) {
		query = query.ilike('titulo', `%${q}%`);
	}
	if (estado) {
		query = query.eq('estado', estado);
	}

	const { data, error, count } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	const estadoIds = new Set((data ?? []).map((obra) => obra.estado));
	const estados = estadoIds.size > 0 ? await loadInternalVocabulario(locals.supabase, ['estado']) : [];
	const estadoMap = new Map(
		estados.filter((item) => estadoIds.has(item.termino_id)).map((item) => [item.termino_id, item.termino])
	);

	return json({
		items: (data ?? []).map((obra) => {
			const estadoTerm = estadoMap.get(obra.estado) ?? obra.estado;
			return {
				...obra,
				estadoTerm,
				...buildObraCapabilities(profile, obra, estadoTerm.toLowerCase(), reviewerAssignedSet.has(obra.obra_id))
			};
		}),
		total: count ?? 0,
		page,
		pageSize,
		scope
	});
};

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!['admin', 'ip'].includes(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden crear obras.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = obraCreateSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const [obra] = await createObras(locals, [payload.titulo], payload.editor_asignado, payload.genero_id);
	return json({ obra }, { status: 201 });
};
