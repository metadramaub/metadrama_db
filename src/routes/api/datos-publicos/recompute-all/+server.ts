import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse } from '$lib/server/http';
import { canManagePublicacion } from '$lib/utils/permissions';

/**
 * Recalcula obras_resumen (todas las obras publicadas) y, encadenado, autores_resumen
 * (perfiles métricos de autor). recompute_all hace ambas fases. Uso: reconstrucción tras
 * una inconsistencia o tras un cambio global (p. ej. renombrar formas en el vocabulario).
 * Solo admin/IP.
 */
export const POST: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManagePublicacion(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden recalcular todos los datos públicos.');
	}

	const { error: rpcError } = await locals.supabase.rpc('recompute_all');
	if (rpcError) {
		return json(
			{ error: 'db_error', message: `No se pudo recalcular: ${rpcError.message}` },
			{ status: 500 }
		);
	}

	// Conteo informativo tras el recálculo (obras y autores con perfil).
	const { count: obras } = await locals.supabase
		.from('obras_resumen')
		.select('obra_id', { count: 'exact', head: true });
	const { count: autores } = await locals.supabase
		.from('autores_resumen')
		.select('autor_id', { count: 'exact', head: true })
		.eq('alcance', 'completo');

	return json({ ok: true, obras: obras ?? null, autores: autores ?? null });
};
