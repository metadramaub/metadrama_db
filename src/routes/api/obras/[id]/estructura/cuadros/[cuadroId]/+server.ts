import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { cuadroInputSchema } from '$lib/utils/validators';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';
import { stateAllowsRangeEditing } from '$lib/utils/range-consistency';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const { estadoTerm } = await getObraContext({ locals }, params.id, { requireEdit: true });
	if (!stateAllowsRangeEditing(estadoTerm)) {
		return conflictResponse('Mueve la obra a borrador antes de editar sus rangos.');
	}
	const body = await request.json().catch(() => ({}));
	const parsed = cuadroInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const { data: jornada } = await locals.supabase
		.from('jornadas')
		.select('*')
		.eq('jornada_id', payload.jornada_id)
		.eq('obra_id', params.id)
		.single();
	const jornadaRow = (jornada ?? null) as Tables<'jornadas'> | null;

	if (!jornadaRow) {
		return json(
			{ error: 'validation_error', message: 'Jornada inválida para esta obra' },
			{ status: 422 }
		);
	}
	if (payload.v_ini < jornadaRow.v_ini || payload.v_fin > jornadaRow.v_fin) {
		return json(
			{ error: 'validation_error', message: 'El cuadro debe estar dentro del rango de la jornada' },
			{ status: 422 }
		);
	}

	const { data, error } = await locals.supabase
		.from('cuadros')
		.update(payload)
		.eq('cuadro_id', params.cuadroId)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el cuadro' },
			{ status: 500 }
		);
	}

	return json({ cuadro: data });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	const { estadoTerm } = await getObraContext({ locals }, params.id, { requireEdit: true });
	if (!stateAllowsRangeEditing(estadoTerm)) {
		return conflictResponse('Mueve la obra a borrador antes de editar sus rangos.');
	}
	const { error } = await locals.supabase.from('cuadros').delete().eq('cuadro_id', params.cuadroId);
	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar el cuadro' },
			{ status: 500 }
		);
	}

	return json({ ok: true });
};
