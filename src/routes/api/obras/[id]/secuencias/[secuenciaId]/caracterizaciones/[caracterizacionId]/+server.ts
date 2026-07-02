import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { validationErrorResponse } from '$lib/server/http';
import { validateSecuenciaCaracterizacionRangoContext } from '$lib/server/secuencias-caracterizaciones-rango';
import { secuenciaCaracterizacionRangoInputSchema } from '$lib/utils/validators';

type CaracterizacionRowWithTipo = {
	caracterizacion_rango_id: string;
	secuencia_id: string;
	tipo_caracterizacion_rango_id: string;
	v_ini: number;
	v_fin: number;
	observaciones: string | null;
	tipo_caracterizacion_rango:
		| {
				termino_id: string;
				termino: string;
				termino_padre_id: string | null;
		  }
		| {
				termino_id: string;
				termino: string;
				termino_padre_id: string | null;
		  }[]
		| null;
};

function validationMessageResponse(
	message: string,
	path = 'tipo_caracterizacion_rango_id'
) {
	return json(
		{
			error: 'validation_error',
			details: [{ path, message }]
		},
		{ status: 422 }
	);
}

function flattenTipoPayload(tipo: CaracterizacionRowWithTipo['tipo_caracterizacion_rango']) {
	if (!tipo) return null;
	if (Array.isArray(tipo)) return tipo[0] ?? null;
	return tipo;
}

function mapCaracterizacion(row: CaracterizacionRowWithTipo) {
	const tipo = flattenTipoPayload(row.tipo_caracterizacion_rango);
	return {
		caracterizacion_rango_id: row.caracterizacion_rango_id,
		secuencia_id: row.secuencia_id,
		tipo_caracterizacion_rango_id: row.tipo_caracterizacion_rango_id,
		tipo_caracterizacion_rango_term: tipo?.termino ?? '',
		tipo_caracterizacion_rango_parent_id: tipo?.termino_padre_id ?? null,
		v_ini: row.v_ini,
		v_fin: row.v_fin,
		observaciones: row.observaciones
	};
}

async function loadSecuenciaRange(locals: App.Locals, obraId: string, secuenciaId: string) {
	const { data, error } = await locals.supabase
		.from('secuencias_metricas')
		.select('secuencia_id,v_ini,v_fin')
		.eq('obra_id', obraId)
		.eq('secuencia_id', secuenciaId)
		.maybeSingle();

	if (error) {
		return {
			errorResponse: json({ error: 'db_error', message: error.message }, { status: 500 }),
			secuencia: null
		};
	}
	if (!data) {
		return {
			errorResponse: json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 }),
			secuencia: null
		};
	}

	return {
		errorResponse: null,
		secuencia: {
			v_ini: data.v_ini,
			v_fin: data.v_fin
		}
	};
}

async function loadTipoCaracterizacionRango(
	locals: App.Locals,
	tipoCaracterizacionRangoId: string
) {
	const tipos = await loadInternalVocabulario(locals.supabase, ['caracterizacion_rango']);
	const tipo = tipos.find((item) => item.termino_id === tipoCaracterizacionRangoId);

	if (!tipo) {
		return {
			errorResponse: validationMessageResponse(
				'El tipo de caracterización no existe o no está activo.',
				'tipo_caracterizacion_rango_id'
			),
			tipo: null
		};
	}

	return { errorResponse: null, tipo };
}

async function ensureCaracterizacionBelongsToSecuencia(
	locals: App.Locals,
	secuenciaId: string,
	caracterizacionRangoId: string
) {
	const { data, error } = await locals.supabase
		.from('secuencias_caracterizaciones_rango')
		.select('caracterizacion_rango_id')
		.eq('secuencia_id', secuenciaId)
		.eq('caracterizacion_rango_id', caracterizacionRangoId)
		.maybeSingle();

	if (error) {
		return {
			errorResponse: json({ error: 'db_error', message: error.message }, { status: 500 }),
			caracterizacionRangoId: null
		};
	}
	if (!data) {
		return {
			errorResponse: json({ error: 'not_found', message: 'Caracterización no encontrada' }, { status: 404 }),
			caracterizacionRangoId: null
		};
	}
	return { errorResponse: null, caracterizacionRangoId: data.caracterizacion_rango_id };
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = secuenciaCaracterizacionRangoInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const secuenciaResult = await loadSecuenciaRange(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;
	if (!secuenciaResult.secuencia) {
		return json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 });
	}

	const ownershipResult = await ensureCaracterizacionBelongsToSecuencia(
		locals,
		params.secuenciaId,
		params.caracterizacionId
	);
	if (ownershipResult.errorResponse) return ownershipResult.errorResponse;

	const tipoResult = await loadTipoCaracterizacionRango(
		locals,
		parsed.data.tipo_caracterizacion_rango_id
	);
	if (tipoResult.errorResponse) return tipoResult.errorResponse;
	if (!tipoResult.tipo) {
		return validationMessageResponse(
			'El tipo de caracterización no existe o no está activo.',
			'tipo_caracterizacion_rango_id'
		);
	}

	const contextualError = validateSecuenciaCaracterizacionRangoContext({
		secuencia: secuenciaResult.secuencia,
		tipo: tipoResult.tipo,
		payload: parsed.data
	});
	if (contextualError) {
		return validationMessageResponse(contextualError, 'v_ini');
	}

	const { data: updated, error: updateError } = await locals.supabase
		.from('secuencias_caracterizaciones_rango')
		.update({
			tipo_caracterizacion_rango_id: parsed.data.tipo_caracterizacion_rango_id,
			v_ini: parsed.data.v_ini,
			v_fin: parsed.data.v_fin,
			observaciones: parsed.data.observaciones
		})
		.eq('secuencia_id', params.secuenciaId)
		.eq('caracterizacion_rango_id', params.caracterizacionId)
		.select(
			'caracterizacion_rango_id,secuencia_id,tipo_caracterizacion_rango_id,v_ini,v_fin,observaciones,tipo_caracterizacion_rango:vocabularios(termino_id,termino,termino_padre_id)'
		)
		.single();

	if (updateError || !updated) {
		return json(
			{ error: 'db_error', message: updateError?.message ?? 'No se pudo actualizar la caracterización' },
			{ status: 500 }
		);
	}

	return json({ caracterizacion: mapCaracterizacion(updated as CaracterizacionRowWithTipo) });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const secuenciaResult = await loadSecuenciaRange(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;

	const ownershipResult = await ensureCaracterizacionBelongsToSecuencia(
		locals,
		params.secuenciaId,
		params.caracterizacionId
	);
	if (ownershipResult.errorResponse) return ownershipResult.errorResponse;

	const { error } = await locals.supabase
		.from('secuencias_caracterizaciones_rango')
		.delete()
		.eq('secuencia_id', params.secuenciaId)
		.eq('caracterizacion_rango_id', params.caracterizacionId);

	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar la caracterización' },
			{ status: 500 }
		);
	}

	return json({ ok: true });
};
