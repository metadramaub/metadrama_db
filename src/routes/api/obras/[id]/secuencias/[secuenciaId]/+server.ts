import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { secuenciaInputSchema } from '$lib/utils/validators';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { stateAllowsRangeEditing } from '$lib/utils/range-consistency';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const { estadoTerm } = await getObraContext({ locals }, params.id, { requireEdit: true });
	if (!stateAllowsRangeEditing(estadoTerm)) {
		return conflictResponse('Mueve la obra a borrador antes de editar sus rangos.');
	}
	const body = await request.json().catch(() => ({}));
	const parsed = secuenciaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const { data: current } = await locals.supabase
		.from('secuencias_metricas')
		.select('secuencia_id')
		.eq('obra_id', params.id)
		.eq('secuencia_id', params.secuenciaId)
		.single();
	if (!current) {
		return json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 });
	}

	const { data: secuencia, error } = await locals.supabase
		.from('secuencias_metricas')
		.update({
			...payload,
			n_versos: payload.v_fin - payload.v_ini + 1
		})
		.eq('obra_id', params.id)
		.eq('secuencia_id', params.secuenciaId)
		.select('*')
		.single();

	if (error || !secuencia) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar la secuencia' },
			{ status: 500 }
		);
	}
	return json({ secuencia });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	const { estadoTerm } = await getObraContext({ locals }, params.id, { requireEdit: true });
	if (!stateAllowsRangeEditing(estadoTerm)) {
		return conflictResponse('Mueve la obra a borrador antes de editar sus rangos.');
	}
	const { error } = await locals.supabase
		.from('secuencias_metricas')
		.delete()
		.eq('obra_id', params.id)
		.eq('secuencia_id', params.secuenciaId);

	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar la secuencia' },
			{ status: 500 }
		);
	}

	return json({ ok: true });
};
