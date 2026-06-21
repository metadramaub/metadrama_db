import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { conflictResponse, forbiddenResponse } from '$lib/server/http';
import type { Tables } from '$lib/types/database.types';

/**
 * Fase 2 del plan de precomputación: dispara recompute_obra_resumen para una obra.
 *
 * Permiso: admin/IP o el editor asignado a esta obra (doc §8.1).
 * Condición: solo tiene efecto si estado = publicado (doc §8.3); en otros estados
 * los datos públicos no existen, así que recalcularlos no procede.
 */
export const POST: RequestHandler = async ({ locals, params }) => {
	const { profile, obra, estadoTerm, assignedEditor } = await getObraContext(
		{ locals },
		params.id,
		{ requireEdit: false }
	);

	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';
	if (!isAdminOrIp && !assignedEditor) {
		return forbiddenResponse(
			'Solo el editor asignado o un administrador pueden actualizar los datos públicos.'
		);
	}

	if (estadoTerm.trim().toLowerCase() !== 'publicado') {
		return conflictResponse(
			'Solo se pueden actualizar los datos públicos de una obra en estado publicado.'
		);
	}

	// Recalcula la obra y, encadenado, el perfil métrico de sus autores afectados (Fase 3).
	const { error: rpcError } = await locals.supabase.rpc('recompute_obra_y_autores', {
		p_obra_id: obra.obra_id
	});

	if (rpcError) {
		return json(
			{ error: 'db_error', message: `No se pudieron actualizar los datos públicos: ${rpcError.message}` },
			{ status: 500 }
		);
	}

	const { data, error: readError } = await locals.supabase
		.from('obras_resumen')
		.select('metrica_sucia,actualizado_en')
		.eq('obra_id', obra.obra_id)
		.maybeSingle();

	if (readError) {
		return json(
			{ error: 'db_error', message: readError.message },
			{ status: 500 }
		);
	}

	const resumen = data as Pick<Tables<'obras_resumen'>, 'metrica_sucia' | 'actualizado_en'> | null;

	return json({
		ok: true,
		metrica_sucia: resumen?.metrica_sucia ?? false,
		actualizado_en: resumen?.actualizado_en ?? null
	});
};
