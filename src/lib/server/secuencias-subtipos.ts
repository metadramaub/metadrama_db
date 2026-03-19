import { json } from '@sveltejs/kit';
import type { SecuenciaSubtipoEstrofaInput } from '$lib/types/obra.types';

export type SecuenciaSubtipoRowWithTerm = {
	subtipo_secuencia_id: string;
	secuencia_id: string;
	subtipo_estrofa_id: string;
	v_ini: number;
	v_fin: number;
	subtipo_estrofa:
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

type SecuenciaContext = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	estrofa_tipo_id: string | null;
};

function flattenSubtipoPayload(subtipo: SecuenciaSubtipoRowWithTerm['subtipo_estrofa']) {
	if (!subtipo) return null;
	if (Array.isArray(subtipo)) return subtipo[0] ?? null;
	return subtipo;
}

export function mapSecuenciaSubtipo(row: SecuenciaSubtipoRowWithTerm) {
	const subtipo = flattenSubtipoPayload(row.subtipo_estrofa);
	return {
		subtipo_secuencia_id: row.subtipo_secuencia_id,
		secuencia_id: row.secuencia_id,
		subtipo_estrofa_id: row.subtipo_estrofa_id,
		subtipo_estrofa_term: subtipo?.termino ?? '',
		subtipo_estrofa_parent_id: subtipo?.termino_padre_id ?? null,
		v_ini: row.v_ini,
		v_fin: row.v_fin
	};
}

export function validationMessageResponse(message: string, path = 'subtipo_estrofa_id') {
	return json(
		{
			error: 'validation_error',
			details: [{ path, message }]
		},
		{ status: 422 }
	);
}

export async function loadSecuenciaContext(locals: App.Locals, obraId: string, secuenciaId: string) {
	const { data, error } = await locals.supabase
		.from('secuencias_metricas')
		.select('secuencia_id,v_ini,v_fin,estrofa_tipo_id')
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
			secuencia_id: data.secuencia_id,
			v_ini: data.v_ini,
			v_fin: data.v_fin,
			estrofa_tipo_id: data.estrofa_tipo_id
		} satisfies SecuenciaContext
	};
}

export async function ensureSubtipoBelongsToSecuencia(
	locals: App.Locals,
	secuenciaId: string,
	subtipoSecuenciaId: string
) {
	const { data, error } = await locals.supabase
		.from('secuencias_subtipos_estrofa')
		.select('subtipo_secuencia_id')
		.eq('secuencia_id', secuenciaId)
		.eq('subtipo_secuencia_id', subtipoSecuenciaId)
		.maybeSingle();

	if (error) {
		return {
			errorResponse: json({ error: 'db_error', message: error.message }, { status: 500 }),
			subtipoSecuenciaId: null
		};
	}
	if (!data) {
		return {
			errorResponse: json({ error: 'not_found', message: 'Subtipo no encontrado' }, { status: 404 }),
			subtipoSecuenciaId: null
		};
	}
	return { errorResponse: null, subtipoSecuenciaId: data.subtipo_secuencia_id };
}

export async function validateSecuenciaSubtipoContext(args: {
	locals: App.Locals;
	secuencia: SecuenciaContext;
	payload: SecuenciaSubtipoEstrofaInput;
	excludeSubtipoSecuenciaId?: string;
}) {
	const { locals, secuencia, payload, excludeSubtipoSecuenciaId } = args;

	if (!secuencia.estrofa_tipo_id) {
		return {
			errorResponse: validationMessageResponse(
				'La secuencia no tiene estrofa base y no admite subtipos.',
				'subtipo_estrofa_id'
			)
		};
	}

	if (payload.v_ini < secuencia.v_ini || payload.v_fin > secuencia.v_fin) {
		return {
			errorResponse: validationMessageResponse(
				`El subtipo debe quedar dentro del rango de la secuencia (${secuencia.v_ini}-${secuencia.v_fin}).`,
				'v_ini'
			)
		};
	}

	const { data: subtipo, error: subtipoError } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino_padre_id,activo')
		.eq('termino_id', payload.subtipo_estrofa_id)
		.maybeSingle();

	if (subtipoError) {
		return {
			errorResponse: json({ error: 'db_error', message: subtipoError.message }, { status: 500 })
		};
	}
	if (!subtipo || subtipo.categoria !== 'estrofa_tipo' || !subtipo.activo) {
		return {
			errorResponse: validationMessageResponse(
				'El subtipo de estrofa no existe o no está activo.',
				'subtipo_estrofa_id'
			)
		};
	}
	if (subtipo.termino_padre_id !== secuencia.estrofa_tipo_id) {
		return {
			errorResponse: validationMessageResponse(
				'El subtipo seleccionado no pertenece a la estrofa base de la secuencia.',
				'subtipo_estrofa_id'
			)
		};
	}

	let overlapQuery = locals.supabase
		.from('secuencias_subtipos_estrofa')
		.select('subtipo_secuencia_id')
		.eq('secuencia_id', secuencia.secuencia_id)
		.lte('v_ini', payload.v_fin)
		.gte('v_fin', payload.v_ini)
		.limit(1);

	if (excludeSubtipoSecuenciaId) {
		overlapQuery = overlapQuery.neq('subtipo_secuencia_id', excludeSubtipoSecuenciaId);
	}

	const { data: overlaps, error: overlapError } = await overlapQuery;
	if (overlapError) {
		return {
			errorResponse: json({ error: 'db_error', message: overlapError.message }, { status: 500 })
		};
	}
	if ((overlaps ?? []).length > 0) {
		return {
			errorResponse: validationMessageResponse(
				'El rango del subtipo se solapa con otro subtipo de la secuencia.',
				'v_ini'
			)
		};
	}

	return { errorResponse: null };
}
