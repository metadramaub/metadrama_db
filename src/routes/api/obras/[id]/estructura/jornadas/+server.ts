import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { jornadaInputSchema } from '$lib/utils/validators';
import { validationErrorResponse, conflictResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';

export const POST: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });
	const body = await request.json().catch(() => ({}));
	const parsed = jornadaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data: existing } = await locals.supabase
		.from('jornadas')
		.select('v_ini,v_fin')
		.eq('obra_id', params.id);

	if (hasOverlap(existing ?? [], parsed.data)) {
		return conflictResponse('El rango de versos se solapa con otra jornada');
	}

	const { data, error } = await locals.supabase
		.from('jornadas')
		.insert({ ...parsed.data, obra_id: params.id })
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo crear la jornada' },
			{ status: 500 }
		);
	}

	const { data: allJornadas } = await locals.supabase
		.from('jornadas')
		.select('v_fin')
		.eq('obra_id', params.id)
		.order('v_fin', { ascending: false })
		.limit(1);
	const totalVersos = allJornadas?.[0]?.v_fin ?? null;
	if (totalVersos !== null) {
		await locals.supabase
			.from('obras')
			.update({ total_versos: totalVersos })
			.eq('obra_id', params.id);
	}

	return json({ jornada: data }, { status: 201 });
};
