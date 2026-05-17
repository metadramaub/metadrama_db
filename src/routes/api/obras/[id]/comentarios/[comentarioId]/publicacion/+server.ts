import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { conflictResponse, forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { comentarioPublicacionPatchSchema } from '$lib/utils/validators';
import type { Tables } from '$lib/types/database.types';

type ComentarioRow = Tables<'comentarios_internos'>;

function isAdminOrIp(roleTerm: string): boolean {
	return roleTerm === 'admin' || roleTerm === 'ip';
}

async function findComentarioById(
	locals: App.Locals,
	obraId: string,
	comentarioId: string
): Promise<{ comentario: ComentarioRow | null; error: string | null }> {
	const { data, error } = await locals.supabase
		.from('comentarios_internos')
		.select('*')
		.eq('obra_id', obraId)
		.eq('comentario_id', comentarioId)
		.maybeSingle();

	if (error) {
		return { comentario: null, error: error.message };
	}
	return { comentario: (data ?? null) as ComentarioRow | null, error: null };
}

async function resolveTipoComentarioTerm(
	locals: App.Locals,
	tipoComentarioId: string | null | undefined
): Promise<string> {
	if (!tipoComentarioId) return 'general';
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino')
		.eq('termino_id', tipoComentarioId)
		.maybeSingle();
	return (data?.termino ?? 'general').trim().toLowerCase();
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const { profile, assignedEditor } = await getObraContext({ locals }, params.id, {
		requireComment: true
	});

	if (!assignedEditor && !isAdminOrIp(profile.roleTerm)) {
		return forbiddenResponse('No tienes permisos para publicar comentarios de esta obra');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = comentarioPublicacionPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const comentarioLookup = await findComentarioById(locals, params.id, params.comentarioId);
	if (comentarioLookup.error) {
		return json({ error: 'db_error', message: comentarioLookup.error }, { status: 500 });
	}
	const comentarioActual = comentarioLookup.comentario;
	if (!comentarioActual) {
		return json({ error: 'not_found', message: 'Comentario no encontrado' }, { status: 404 });
	}

	const tipoActual = await resolveTipoComentarioTerm(locals, comentarioActual.tipo_comentario_id);
	if (tipoActual === 'estado') {
		return conflictResponse('Los comentarios de estado son de solo lectura');
	}
	if (parsed.data.visible_publico && tipoActual !== 'observacion_publica') {
		return conflictResponse('Solo los comentarios de tipo observacion_publica pueden publicarse');
	}

	const { data: updated, error } = await locals.supabase
		.from('comentarios_internos')
		.update({
			visible_publico: parsed.data.visible_publico,
			publicado_por: parsed.data.visible_publico ? profile.userId : null,
			publicado_at: parsed.data.visible_publico ? new Date().toISOString() : null
		})
		.eq('obra_id', params.id)
		.eq('comentario_id', params.comentarioId)
		.select('*')
		.single();

	if (error || !updated) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar la publicacion' },
			{ status: 500 }
		);
	}

	return json({ comentario: updated });
};
