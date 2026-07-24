import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { secuenciaInputSchema } from '$lib/utils/validators';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';
import { stateAllowsRangeEditing } from '$lib/utils/range-consistency';

export const GET: RequestHandler = async ({ locals, params, url }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const estrofa = url.searchParams.get('estrofa') ?? '';

	let query = locals.supabase
		.from('secuencias_metricas')
		.select('*')
		.eq('obra_id', params.id)
		.order('v_ini', { ascending: true });

	if (estrofa) query = query.eq('estrofa_tipo_id', estrofa);

	const { data, error } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	const secuenciasRows = (data ?? []) as Tables<'secuencias_metricas'>[];
	return json({ items: secuenciasRows });
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
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

	const { data: secuencia, error } = await locals.supabase
		.from('secuencias_metricas')
		.insert({
			...payload,
			obra_id: params.id,
			n_versos: payload.v_fin - payload.v_ini + 1
		})
		.select('*')
		.single();

	if (error || !secuencia) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo crear la secuencia' },
			{ status: 500 }
		);
	}
	const secuenciaRow = secuencia as Tables<'secuencias_metricas'>;
	return json({ secuencia: secuenciaRow }, { status: 201 });
};
