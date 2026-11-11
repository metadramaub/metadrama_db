import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { loadAutoriaCatalogs, loadAutoriaData, replaceAutoriaGroups, validateAutoriaPayload } from '$lib/server/autoria';
import { validationErrorResponse } from '$lib/server/http';
import type { Tables } from '$lib/types/database.types';
import { canManageAutoriaMetricProfile } from '$lib/utils/permissions';
import { autoriaInputSchema } from '$lib/utils/validators';
import { esFichaBasica, esObraSinFicha, requiereInicioCompleta } from '$lib/importador-metrico/tipo-ficha';

function soloAutoriaGlobal(obra: object) {
	return esObraSinFicha(obra) || esFichaBasica(obra) || requiereInicioCompleta(obra);
}

function buildValidationResponse(details: Array<{ path: string; message: string }>) {
	return json({ error: 'validation_error', details }, { status: 422 });
}

export const GET: RequestHandler = async ({ locals, params }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id, { requireEdit: false });
	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos, {
		includePerfilMetrico: canManageAutoriaMetricProfile(profile.roleTerm),
		soloGlobal: soloAutoriaGlobal(obra)
	});
	return json({
		loaded_at: new Date().toISOString(),
		...data
	});
};

export const PUT: RequestHandler = async ({ locals, params, request }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id, { requireEditMetadata: true });
	const soloGlobal = soloAutoriaGlobal(obra);
	const canEditPerfilMetrico = canManageAutoriaMetricProfile(profile.roleTerm);
	const body = await request.json().catch(() => ({}));
	const parsed = autoriaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = canEditPerfilMetrico
		? parsed.data
		: {
				grupos: parsed.data.grupos.map((grupo) => ({
					...grupo,
					propuestas: grupo.propuestas.map((propuesta) => ({
						...propuesta,
						perfil_metrico: false
					}))
				}))
			};
	const [jornadasResp, catalogs, autoresResp] = await Promise.all([
		soloGlobal ? { data: [] } : locals.supabase.from('jornadas').select('jornada_id').eq('obra_id', obra.obra_id),
		loadAutoriaCatalogs(locals.supabase),
		locals.supabase.from('autores').select('autor_id')
	]);

	const jornadaIds = [...new Set((jornadasResp.data ?? []).map((row) => row.jornada_id))];
	const tipoIds = new Set(catalogs.tipos.map((item) => item.termino_id));
	const composicionTermById = new Map(catalogs.composiciones.map((item) => [item.termino_id, item.termino]));
	const authorIds = new Set(((autoresResp.data ?? []) as Pick<Tables<'autores'>, 'autor_id'>[]).map((row) => row.autor_id));

	const issues = validateAutoriaPayload(payload, {
		jornadaIds: new Set(jornadaIds),
		tipoIds,
		composicionTermById,
		authorIds
	});

	if (issues.length > 0) {
		return buildValidationResponse(issues);
	}

	if (soloGlobal) {
		const { error } = await locals.supabase.rpc(
			'guardar_autoria_global_previa' as never,
			{ p_obra: obra.obra_id, p_propuestas: payload.grupos[0]?.propuestas ?? [] } as never
		);
		if (error) return json({ error: 'db_error', message: error.message }, {
			status: error.code === 'PT409' ? 409 : 500
		});
	} else {
		const replaceResult = await replaceAutoriaGroups(locals.supabase, obra.obra_id, jornadaIds, payload, {
			canManagePerfilMetrico: canEditPerfilMetrico
		});
		if (replaceResult.errorMessage) {
			return json({ error: 'db_error', message: replaceResult.errorMessage }, { status: 500 });
		}
	}

	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos, {
		includePerfilMetrico: canEditPerfilMetrico,
		soloGlobal
	});
	return json({
		loaded_at: new Date().toISOString(),
		...data
	});
};
