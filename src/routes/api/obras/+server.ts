import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { queryFilterSchema } from '$lib/utils/validators';
import { canReadAllObras } from '$lib/utils/permissions';
import { validationErrorResponse } from '$lib/server/http';

export const GET: RequestHandler = async ({ locals, url }) => {
	const profile = await requireEditorProfile({ locals });
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

	let query = locals.supabase
		.from('obras')
		.select('*', { count: 'exact' })
		.order('updated_at', { ascending: false })
		.range(from, to);

	if (!canReadAllObras(profile.roleTerm)) {
		query = query.eq('editor_asignado', profile.userId);
	} else if (editor) {
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

	return json({
		items: data ?? [],
		total: count ?? 0,
		page,
		pageSize
	});
};
