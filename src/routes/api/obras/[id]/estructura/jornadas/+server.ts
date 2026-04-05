import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { jornadaInputSchema } from '$lib/utils/validators';
import { validationErrorResponse, conflictResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';

async function syncObraTotalVersos(
	supabase: SupabaseClient<Database>,
	obraId: string
): Promise<string | null> {
	const { data: maxJornada, error: maxJornadaError } = await supabase
		.from('jornadas')
		.select('v_fin')
		.eq('obra_id', obraId)
		.order('v_fin', { ascending: false })
		.limit(1);
	if (maxJornadaError) {
		return maxJornadaError.message ?? 'No se pudo recalcular el total de versos';
	}

	const totalVersos = maxJornada?.[0]?.v_fin ?? null;
	const { error: obraUpdateError } = await supabase
		.from('obras')
		.update({ total_versos: totalVersos })
		.eq('obra_id', obraId);
	if (obraUpdateError) {
		return obraUpdateError.message ?? 'No se pudo actualizar total_versos';
	}

	return null;
}

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

	const syncError = await syncObraTotalVersos(locals.supabase, params.id);
	if (syncError) {
		return json({ error: 'db_error', message: syncError }, { status: 500 });
	}

	return json({ jornada: data }, { status: 201 });
};
