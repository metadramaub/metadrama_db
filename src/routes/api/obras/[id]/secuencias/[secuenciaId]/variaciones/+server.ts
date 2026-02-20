import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';
import { validateSecuenciaVariacionContext } from '$lib/server/secuencias-variaciones';
import { secuenciaVariacionInputSchema } from '$lib/utils/validators';

type VariacionRowWithTipo = {
	variacion_id: string;
	secuencia_id: string;
	tipo_variacion_id: string;
	v_ini: number;
	v_fin: number;
	observaciones: string | null;
	tipo_variacion:
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

function validationMessageResponse(message: string, path = 'tipo_variacion_id') {
	return json(
		{
			error: 'validation_error',
			details: [{ path, message }]
		},
		{ status: 422 }
	);
}

function flattenTipoPayload(tipo: VariacionRowWithTipo['tipo_variacion']) {
	if (!tipo) return null;
	if (Array.isArray(tipo)) return tipo[0] ?? null;
	return tipo;
}

function mapVariacion(row: VariacionRowWithTipo) {
	const tipo = flattenTipoPayload(row.tipo_variacion);
	return {
		variacion_id: row.variacion_id,
		secuencia_id: row.secuencia_id,
		tipo_variacion_id: row.tipo_variacion_id,
		tipo_variacion_term: tipo?.termino ?? '',
		tipo_variacion_parent_id: tipo?.termino_padre_id ?? null,
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

async function loadTipoVariacion(locals: App.Locals, tipoVariacionId: string) {
	const { data, error } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,termino_padre_id,activo')
		.eq('termino_id', tipoVariacionId)
		.maybeSingle();

	if (error) {
		return { errorResponse: json({ error: 'db_error', message: error.message }, { status: 500 }), tipo: null };
	}
	if (!data || data.categoria !== 'tipo_variacion' || !data.activo) {
		return {
			errorResponse: validationMessageResponse(
				'El tipo de variacion no existe o no esta activo.',
				'tipo_variacion_id'
			),
			tipo: null
		};
	}

	return { errorResponse: null, tipo: data };
}

export const GET: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const secuenciaResult = await loadSecuenciaRange(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;

	const { data, error } = await locals.supabase
		.from('secuencias_variaciones')
		.select(
			'variacion_id,secuencia_id,tipo_variacion_id,v_ini,v_fin,observaciones,tipo_variacion:vocabularios!secuencias_variaciones_tipo_variacion_id_fkey(termino_id,termino,termino_padre_id)'
		)
		.eq('secuencia_id', params.secuenciaId)
		.order('v_ini', { ascending: true })
		.order('v_fin', { ascending: true });

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	const items = ((data ?? []) as VariacionRowWithTipo[]).map(mapVariacion);
	return json({ items });
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = secuenciaVariacionInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const secuenciaResult = await loadSecuenciaRange(locals, params.id, params.secuenciaId);
	if (secuenciaResult.errorResponse) return secuenciaResult.errorResponse;
	if (!secuenciaResult.secuencia) {
		return json({ error: 'not_found', message: 'Secuencia no encontrada' }, { status: 404 });
	}

	const tipoResult = await loadTipoVariacion(locals, parsed.data.tipo_variacion_id);
	if (tipoResult.errorResponse) return tipoResult.errorResponse;
	if (!tipoResult.tipo) {
		return validationMessageResponse('El tipo de variacion no existe o no esta activo.', 'tipo_variacion_id');
	}

	const contextualError = validateSecuenciaVariacionContext({
		secuencia: secuenciaResult.secuencia,
		tipoTerm: tipoResult.tipo.termino,
		payload: parsed.data
	});
	if (contextualError) {
		return validationMessageResponse(contextualError, 'v_ini');
	}

	const { data: created, error: insertError } = await locals.supabase
		.from('secuencias_variaciones')
		.insert({
			secuencia_id: params.secuenciaId,
			tipo_variacion_id: parsed.data.tipo_variacion_id,
			v_ini: parsed.data.v_ini,
			v_fin: parsed.data.v_fin,
			observaciones: parsed.data.observaciones
		})
		.select(
			'variacion_id,secuencia_id,tipo_variacion_id,v_ini,v_fin,observaciones,tipo_variacion:vocabularios!secuencias_variaciones_tipo_variacion_id_fkey(termino_id,termino,termino_padre_id)'
		)
		.single();

	if (insertError || !created) {
		return json(
			{ error: 'db_error', message: insertError?.message ?? 'No se pudo crear la variacion' },
			{ status: 500 }
		);
	}

	return json({ variacion: mapVariacion(created as VariacionRowWithTipo) }, { status: 201 });
};
