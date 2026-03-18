import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';
import {
	loadSecuenciaContext,
	mapSecuenciaSubtipo,
	type SecuenciaSubtipoRowWithTerm,
	validateSecuenciaSubtipoContext,
	validationMessageResponse
} from '$lib/server/secuencias-subtipos';
import { secuenciaSubtipoEstrofaInputSchema } from '$lib/utils/validators';

const subtipoSelect =
	'subtipo_secuencia_id,secuencia_id,subtipo_estrofa_id,v_ini,v_fin,subtipo_estrofa:vocabularios!secuencias_subtipos_estrofa_subtipo_estrofa_id_fkey(termino_id,termino,termino_padre_id)';

export const GET: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const secuenciaResult = await loadSecuenciaContext(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;

	const { data, error } = await locals.supabase
		.from('secuencias_subtipos_estrofa')
		.select(subtipoSelect)
		.eq('secuencia_id', params.secuenciaId)
		.order('v_ini', { ascending: true })
		.order('v_fin', { ascending: true });

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	const items = ((data ?? []) as SecuenciaSubtipoRowWithTerm[]).map(mapSecuenciaSubtipo);
	return json({ items });
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = secuenciaSubtipoEstrofaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const secuenciaResult = await loadSecuenciaContext(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;
	if (!secuenciaResult.secuencia) {
		return json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 });
	}

	const contextualValidation = await validateSecuenciaSubtipoContext({
		locals,
		secuencia: secuenciaResult.secuencia,
		payload: parsed.data
	});
	if (contextualValidation.errorResponse) {
		return contextualValidation.errorResponse;
	}

	const { data: created, error: insertError } = await locals.supabase
		.from('secuencias_subtipos_estrofa')
		.insert({
			secuencia_id: params.secuenciaId,
			subtipo_estrofa_id: parsed.data.subtipo_estrofa_id,
			v_ini: parsed.data.v_ini,
			v_fin: parsed.data.v_fin
		})
		.select(subtipoSelect)
		.single();

	if (insertError || !created) {
		if (insertError?.code === '23514' || insertError?.code === '23503') {
			return validationMessageResponse(insertError.message, 'subtipo_estrofa_id');
		}
		return json(
			{ error: 'db_error', message: insertError?.message ?? 'No se pudo crear el subtipo' },
			{ status: 500 }
		);
	}

	return json({ subtipo: mapSecuenciaSubtipo(created as SecuenciaSubtipoRowWithTerm) }, { status: 201 });
};
