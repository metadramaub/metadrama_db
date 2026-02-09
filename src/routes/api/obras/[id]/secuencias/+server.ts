import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { secuenciaInputSchema } from '$lib/utils/validators';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';
import type { Tables } from '$lib/types/database.types';

export const GET: RequestHandler = async ({ locals, params, url }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const estrofa = url.searchParams.get('estrofa') ?? '';
	const estado = url.searchParams.get('estado') ?? '';
	const certeza = url.searchParams.get('certeza') ?? '';

	let query = locals.supabase
		.from('secuencias_metricas')
		.select('*')
		.eq('obra_id', params.id)
		.order('v_ini', { ascending: true });

	if (estrofa) query = query.eq('estrofa_tipo_id', estrofa);
	if (estado) query = query.eq('estado_revision', estado);
	if (certeza) query = query.eq('certeza_editor', certeza);

	const { data, error } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	const secuenciasRows = (data ?? []) as Tables<'secuencias_metricas'>[];

	const secuenciaIds = secuenciasRows.map((item) => item.secuencia_id);
	const { data: metros } =
		secuenciaIds.length > 0
			? await locals.supabase.from('secuencias_metros').select('*').in('secuencia_id', secuenciaIds)
			: { data: [] };

	return json({
		items: secuenciasRows,
		metros: (metros ?? []) as Tables<'secuencias_metros'>[]
	});
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });
	const body = await request.json().catch(() => ({}));
	const parsed = secuenciaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}
	const payload = parsed.data;

	const { data: existing } = await locals.supabase
		.from('secuencias_metricas')
		.select('v_ini,v_fin')
		.eq('obra_id', params.id);
	if (hasOverlap(existing ?? [], payload)) {
		return conflictResponse('El rango de versos se solapa con otra secuencia');
	}

	const { metro_ids, ...secuenciaPayload } = payload;
	const { data: secuencia, error } = await locals.supabase
		.from('secuencias_metricas')
		.insert({
			...secuenciaPayload,
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

	const rows = metro_ids.map((metroId) => ({
		secuencia_id: secuenciaRow.secuencia_id,
		metro_id: metroId
	}));
	const { error: metrosError } = await locals.supabase.from('secuencias_metros').insert(rows);
	if (metrosError) {
		await locals.supabase
			.from('secuencias_metricas')
			.delete()
			.eq('secuencia_id', secuenciaRow.secuencia_id);
		return json(
			{ error: 'db_error', message: metrosError.message ?? 'No se pudieron guardar los metros' },
			{ status: 500 }
		);
	}

	return json({ secuencia: secuenciaRow, metro_ids }, { status: 201 });
};
