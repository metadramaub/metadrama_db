import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { getObraContext } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';

const schema = z.object({
	metro_ids: z.array(z.string().uuid()).min(1)
});

export const PUT: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = schema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data: secuencia } = await locals.supabase
		.from('secuencias_metricas')
		.select('secuencia_id')
		.eq('obra_id', params.id)
		.eq('secuencia_id', params.secuenciaId)
		.single();
	if (!secuencia) {
		return json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 });
	}

	await locals.supabase.from('secuencias_metros').delete().eq('secuencia_id', params.secuenciaId);
	const rows = parsed.data.metro_ids.map((metroId) => ({
		secuencia_id: params.secuenciaId,
		metro_id: metroId
	}));
	const { error } = await locals.supabase.from('secuencias_metros').insert(rows);
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	return json({ ok: true, metro_ids: parsed.data.metro_ids });
};
