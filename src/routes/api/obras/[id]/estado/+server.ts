import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { canTransitionState } from '$lib/utils/permissions';
import { estadoInputSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { getObraContext, requireAuthenticated } from '$lib/server/auth';
import { getEstadoTerm } from '$lib/server/obras';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const user = await requireAuthenticated({ locals });
	const { obra, profile, estadoTerm } = await getObraContext({ locals }, params.id, {
		requireEdit: false
	});
	const body = await request.json().catch(() => ({}));
	const parsed = estadoInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { estado, comentario } = parsed.data;
	const targetTerm = await getEstadoTerm(locals.supabase, estado);
	const allowed = canTransitionState(profile.roleTerm, estadoTerm, targetTerm);

	if (!allowed) {
		return json(
			{
				error: 'forbidden',
				message: `Transición no permitida para rol ${profile.roleTerm}: ${estadoTerm} -> ${targetTerm}`
			},
			{ status: 403 }
		);
	}

	const { data, error } = await locals.supabase
		.from('obras')
		.update({
			estado,
			fecha_cambio_estado: new Date().toISOString()
		})
		.eq('obra_id', obra.obra_id)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo cambiar estado' },
			{ status: 500 }
		);
	}

	if (comentario?.trim()) {
		await locals.supabase.from('comentarios_internos').insert({
			obra_id: obra.obra_id,
			user_id: user.id,
			comentario: `[Cambio de estado ${estadoTerm} -> ${targetTerm}] ${comentario.trim()}`
		});
	}

	return json({ obra: data, estadoTerm: targetTerm });
};
