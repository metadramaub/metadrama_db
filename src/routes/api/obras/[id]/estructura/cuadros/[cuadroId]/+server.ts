import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { cuadroInputSchema } from '$lib/utils/validators';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';
import type { Tables } from '$lib/types/database.types';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });
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

	const { data: existing } = await locals.supabase
		.from('cuadros')
		.select('v_ini,v_fin')
		.eq('jornada_id', payload.jornada_id)
		.neq('cuadro_id', params.cuadroId);
	if (hasOverlap(existing ?? [], payload)) {
		return conflictResponse('El rango de versos se solapa con otro cuadro');
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
	await getObraContext({ locals }, params.id, { requireEdit: true });
	const { error } = await locals.supabase.from('cuadros').delete().eq('cuadro_id', params.cuadroId);
	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar el cuadro' },
			{ status: 500 }
		);
	}

	return json({ ok: true });
};
