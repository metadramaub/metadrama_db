import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { analisisInputSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = analisisInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const { data, error } = await locals.supabase
		.from('obras')
		.update({
			analisis_editor: payload.analisis_editor,
			bibliografia: payload.bibliografia
		})
		.eq('obra_id', params.id)
		.select('obra_id,analisis_editor,bibliografia,updated_at')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el analisis.' },
			{ status: 500 }
		);
	}

	return json({ obra: data });
};
