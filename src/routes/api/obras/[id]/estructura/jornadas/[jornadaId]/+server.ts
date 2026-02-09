import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { jornadaInputSchema } from '$lib/utils/validators';
import { validationErrorResponse, conflictResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });
	const body = await request.json().catch(() => ({}));
	const parsed = jornadaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data: current } = await locals.supabase
		.from('jornadas')
		.select('*')
		.eq('jornada_id', params.jornadaId)
		.eq('obra_id', params.id)
		.single();

	if (!current) {
		return json({ error: 'not_found', message: 'Jornada no encontrada' }, { status: 404 });
	}

	const { data: others } = await locals.supabase
		.from('jornadas')
		.select('v_ini,v_fin')
		.eq('obra_id', params.id)
		.neq('jornada_id', params.jornadaId);

	if (hasOverlap(others ?? [], parsed.data)) {
		return conflictResponse('El rango de versos se solapa con otra jornada');
	}

	const { data, error } = await locals.supabase
		.from('jornadas')
		.update(parsed.data)
		.eq('jornada_id', params.jornadaId)
		.eq('obra_id', params.id)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar la jornada' },
			{ status: 500 }
		);
	}

	const { data: maxJornada } = await locals.supabase
		.from('jornadas')
		.select('v_fin')
		.eq('obra_id', params.id)
		.order('v_fin', { ascending: false })
		.limit(1);
	if (maxJornada?.[0]?.v_fin) {
		await locals.supabase
			.from('obras')
			.update({ total_versos: maxJornada[0].v_fin })
			.eq('obra_id', params.id);
	}

	return json({ jornada: data });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const { data: jornada } = await locals.supabase
		.from('jornadas')
		.select('jornada_id')
		.eq('jornada_id', params.jornadaId)
		.eq('obra_id', params.id)
		.single();

	if (!jornada) {
		return json({ error: 'not_found', message: 'Jornada no encontrada' }, { status: 404 });
	}

	await locals.supabase.from('cuadros').delete().eq('jornada_id', params.jornadaId);
	const { error } = await locals.supabase
		.from('jornadas')
		.delete()
		.eq('jornada_id', params.jornadaId)
		.eq('obra_id', params.id);

	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar la jornada' },
			{ status: 500 }
		);
	}

	const { data: maxJornada } = await locals.supabase
		.from('jornadas')
		.select('v_fin')
		.eq('obra_id', params.id)
		.order('v_fin', { ascending: false })
		.limit(1);
	await locals.supabase
		.from('obras')
		.update({ total_versos: maxJornada?.[0]?.v_fin ?? null })
		.eq('obra_id', params.id);

	return json({ ok: true });
};
