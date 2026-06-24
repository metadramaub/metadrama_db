import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse } from '$lib/server/http';
import { canManagePublicacion } from '$lib/utils/permissions';

type PublicAttributionGroup = {
	grupo_atribucion_id: string;
};

type AttributionRow = {
	atribucion_id: string;
};

type AttributionAuthorRow = {
	autor_id: string;
};

async function countDistinctPublicLinkedAuthors(locals: App.Locals, publishedObraIds: string[]) {
	if (publishedObraIds.length === 0) return 0;

	const jornadasResp = await locals.supabase
		.from('jornadas')
		.select('jornada_id')
		.in('obra_id', publishedObraIds)
		.limit(10000);
	const jornadaIds = (jornadasResp.data ?? []).map((row) => row.jornada_id);

	let gruposQuery = locals.supabase
		.from('grupos_atribucion')
		.select('grupo_atribucion_id')
		.in('obra_id', publishedObraIds)
		.limit(10000);

	if (jornadaIds.length > 0) {
		gruposQuery = locals.supabase
			.from('grupos_atribucion')
			.select('grupo_atribucion_id')
			.or(`obra_id.in.(${publishedObraIds.join(',')}),jornada_id.in.(${jornadaIds.join(',')})`)
			.limit(10000);
	}

	const gruposResp = await gruposQuery;
	const grupoIds = ((gruposResp.data ?? []) as PublicAttributionGroup[]).map((row) => row.grupo_atribucion_id);
	if (grupoIds.length === 0) return 0;

	const atribucionesResp = await locals.supabase
		.from('atribuciones')
		.select('atribucion_id')
		.in('grupo_atribucion_id', grupoIds)
		.limit(20000);
	const atribucionIds = ((atribucionesResp.data ?? []) as AttributionRow[]).map((row) => row.atribucion_id);
	if (atribucionIds.length === 0) return 0;

	const autoresResp = await locals.supabase
		.from('atribucion_autores')
		.select('autor_id')
		.in('atribucion_id', atribucionIds)
		.limit(20000);
	return new Set(((autoresResp.data ?? []) as AttributionAuthorRow[]).map((row) => row.autor_id)).size;
}

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

	const { data: publicadoEstado } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'estado')
		.eq('termino', 'publicado')
		.maybeSingle();

	const publishedObrasResp = publicadoEstado?.termino_id
		? await locals.supabase
				.from('obras')
				.select('obra_id')
				.eq('estado', publicadoEstado.termino_id)
				.limit(10000)
		: { data: [] };
	const publishedObraIds = (publishedObrasResp.data ?? []).map((obra) => obra.obra_id);

	const { count: obrasResumen } = await locals.supabase
		.from('obras_resumen')
		.select('obra_id', { count: 'exact', head: true });
	const { count: autoresPerfilMetrico } = await locals.supabase
		.from('autores_resumen')
		.select('autor_id', { count: 'exact', head: true })
		.eq('alcance', 'completo');
	const autoresVinculadosPublicados = await countDistinctPublicLinkedAuthors(locals, publishedObraIds);

	return json({
		ok: true,
		// Backward compatible aliases used by older UI code.
		obras: obrasResumen ?? null,
		autores: autoresPerfilMetrico ?? null,
		obrasResumen: obrasResumen ?? null,
		obrasPublicadas: publishedObraIds.length,
		autoresPerfilMetrico: autoresPerfilMetrico ?? null,
		autoresVinculadosPublicados
	});
};
