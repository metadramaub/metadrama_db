import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { visibilidadInputSchema } from '$lib/utils/validators';
import { validationErrorResponse, forbiddenResponse } from '$lib/server/http';
import { canToggleVisibility } from '$lib/utils/permissions';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const { profile, obra } = await getObraContext({ locals }, params.id, {
		requireToggleVisibility: true
	});
	if (!canToggleVisibility(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden cambiar la visibilidad publica.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = visibilidadInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data, error } = await locals.supabase
		.from('obras')
		.update({ visible_publico: parsed.data.visible_publico })
		.eq('obra_id', obra.obra_id)
		.select('obra_id,visible_publico,updated_at')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar visibilidad.' },
			{ status: 500 }
		);
	}

	return json({ obra: data });
};
