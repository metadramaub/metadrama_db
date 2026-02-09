import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { comentarioInputSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { getObraContext, requireAuthenticated } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';

export const GET: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const { data: comments, error } = await locals.supabase
		.from('comentarios_internos')
		.select('*')
		.eq('obra_id', params.id)
		.order('created_at', { ascending: false });

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	const commentsRows = (comments ?? []) as Tables<'comentarios_internos'>[];

	const userIds = [
		...new Set(commentsRows.map((comment) => comment.user_id).filter(Boolean) as string[])
	];
	const { data: editores } =
		userIds.length > 0
			? await locals.supabase
					.from('editores')
					.select('user_id,nombre_completo')
					.in('user_id', userIds)
			: { data: [] };

	const names = new Map((editores ?? []).map((editor) => [editor.user_id, editor.nombre_completo]));
	return json({
		items: commentsRows.map((comment) => ({
			...comment,
			nombre_editor: comment.user_id ? (names.get(comment.user_id) ?? 'Editor') : 'Editor'
		}))
	});
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
	const user = await requireAuthenticated({ locals });
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const body = await request.json().catch(() => ({}));
	const parsed = comentarioInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data, error } = await locals.supabase
		.from('comentarios_internos')
		.insert({
			obra_id: params.id,
			user_id: user.id,
			comentario: parsed.data.comentario
		})
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo guardar el comentario' },
			{ status: 500 }
		);
	}

	return json({ comentario: data }, { status: 201 });
};
