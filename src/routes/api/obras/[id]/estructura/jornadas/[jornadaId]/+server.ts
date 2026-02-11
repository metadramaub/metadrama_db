import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { jornadaInputSchema } from '$lib/utils/validators';
import { validationErrorResponse, conflictResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import { hasOverlap } from '$lib/server/obras';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';

async function syncObraTotalVersosAndSimpleAutoria(
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

	if (!totalVersos) {
		return null;
	}

	const { data: rangos, error: rangosError } = await supabase
		.from('rangos')
		.select('rango_id,v_ini,v_fin')
		.eq('obra_id', obraId)
		.order('v_ini');
	if (rangosError) {
		return rangosError.message ?? 'No se pudo revisar autoria para autoajuste';
	}

	if (!rangos || rangos.length !== 1) {
		return null;
	}

	const [singleRange] = rangos;
	if (singleRange.v_ini !== 1 || singleRange.v_fin >= totalVersos) {
		return null;
	}

	const { error: rangeUpdateError } = await supabase
		.from('rangos')
		.update({ v_fin: totalVersos })
		.eq('rango_id', singleRange.rango_id);
	if (rangeUpdateError) {
		return rangeUpdateError.message ?? 'No se pudo extender el rango de autoria';
	}

	return null;
}

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

	const syncError = await syncObraTotalVersosAndSimpleAutoria(locals.supabase, params.id);
	if (syncError) {
		return json({ error: 'db_error', message: syncError }, { status: 500 });
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

	const syncError = await syncObraTotalVersosAndSimpleAutoria(locals.supabase, params.id);
	if (syncError) {
		return json({ error: 'db_error', message: syncError }, { status: 500 });
	}

	return json({ ok: true });
};
