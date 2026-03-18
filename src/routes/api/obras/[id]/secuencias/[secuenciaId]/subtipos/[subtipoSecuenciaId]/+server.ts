import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';
import {
	ensureSubtipoBelongsToSecuencia,
	loadSecuenciaContext,
	mapSecuenciaSubtipo,
	type SecuenciaSubtipoRowWithTerm,
	validateSecuenciaSubtipoContext,
	validationMessageResponse
} from '$lib/server/secuencias-subtipos';
import { secuenciaSubtipoEstrofaInputSchema } from '$lib/utils/validators';

const subtipoSelect =
	'subtipo_secuencia_id,secuencia_id,subtipo_estrofa_id,v_ini,v_fin,subtipo_estrofa:vocabularios!secuencias_subtipos_estrofa_subtipo_estrofa_id_fkey(termino_id,termino,termino_padre_id)';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
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

	const ownershipResult = await ensureSubtipoBelongsToSecuencia(
		locals,
		params.secuenciaId,
		params.subtipoSecuenciaId
	);
	if (ownershipResult.errorResponse) return ownershipResult.errorResponse;

	const contextualValidation = await validateSecuenciaSubtipoContext({
		locals,
		secuencia: secuenciaResult.secuencia,
		payload: parsed.data,
		excludeSubtipoSecuenciaId: params.subtipoSecuenciaId
	});
	if (contextualValidation.errorResponse) {
		return contextualValidation.errorResponse;
	}

	const { data: updated, error: updateError } = await locals.supabase
		.from('secuencias_subtipos_estrofa')
		.update({
			subtipo_estrofa_id: parsed.data.subtipo_estrofa_id,
			v_ini: parsed.data.v_ini,
			v_fin: parsed.data.v_fin
		})
		.eq('secuencia_id', params.secuenciaId)
		.eq('subtipo_secuencia_id', params.subtipoSecuenciaId)
		.select(subtipoSelect)
		.single();

	if (updateError || !updated) {
		if (updateError?.code === '23514' || updateError?.code === '23503') {
			return validationMessageResponse(updateError.message, 'subtipo_estrofa_id');
		}
		return json(
			{ error: 'db_error', message: updateError?.message ?? 'No se pudo actualizar el subtipo' },
			{ status: 500 }
		);
	}

	return json({ subtipo: mapSecuenciaSubtipo(updated as SecuenciaSubtipoRowWithTerm) });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const secuenciaResult = await loadSecuenciaContext(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;

	const ownershipResult = await ensureSubtipoBelongsToSecuencia(
		locals,
		params.secuenciaId,
		params.subtipoSecuenciaId
	);
	if (ownershipResult.errorResponse) return ownershipResult.errorResponse;

	const { error } = await locals.supabase
		.from('secuencias_subtipos_estrofa')
		.delete()
		.eq('secuencia_id', params.secuenciaId)
		.eq('subtipo_secuencia_id', params.subtipoSecuenciaId);

	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar el subtipo' },
			{ status: 500 }
		);
	}

	return json({ ok: true });
};
