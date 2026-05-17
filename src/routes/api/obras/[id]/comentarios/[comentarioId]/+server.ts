import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { comentarioPatchSchema } from '$lib/utils/validators';
import { conflictResponse, forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';
import type { ComentarioTipoTerm } from '$lib/server/comentarios';

type ComentarioRow = Tables<'comentarios_internos'>;

function isAdminOrIp(roleTerm: string): boolean {
	return roleTerm === 'admin' || roleTerm === 'ip';
}

async function resolveTipoComentarioId(
	locals: App.Locals,
	term: Exclude<ComentarioTipoTerm, 'estado'>
) {
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'tipo_comentario')
		.eq('termino', term)
		.eq('activo', true)
		.maybeSingle();
	return data?.termino_id ?? null;
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

	const body = await request.json().catch(() => ({}));
	const parsed = comentarioPatchSchema.safeParse(body);
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

	const canManageAll = isAdminOrIp(profile.roleTerm);
	const canPublishPublicComments = canManageAll || assignedEditor;
	if (comentarioActual.visible_publico && !canPublishPublicComments) {
		return forbiddenResponse('No tienes permisos para editar un comentario publicado');
	}
	if (!comentarioActual.visible_publico && !canManageAll && comentarioActual.user_id !== profile.userId) {
		return forbiddenResponse('No tienes permisos para editar este comentario');
	}

	const tipoActual = await resolveTipoComentarioTerm(locals, comentarioActual.tipo_comentario_id);
	if (tipoActual === 'estado') {
		return conflictResponse('Los comentarios de estado son de solo lectura');
	}

	let tipoComentarioId = comentarioActual.tipo_comentario_id;
	let nextVisiblePublico = Boolean(comentarioActual.visible_publico);
	let nextPublicadoPor = comentarioActual.publicado_por;
	let nextPublicadoAt = comentarioActual.publicado_at;
	if (parsed.data.tipo_comentario) {
		const resolvedTipoId = await resolveTipoComentarioId(locals, parsed.data.tipo_comentario);
		if (!resolvedTipoId) {
			return json(
				{
					error: 'validation_error',
					message: `No existe tipo_comentario '${parsed.data.tipo_comentario}' en vocabularios.`
				},
				{ status: 422 }
			);
		}
		tipoComentarioId = resolvedTipoId;
		if (parsed.data.tipo_comentario !== 'observacion_publica') {
			nextVisiblePublico = false;
			nextPublicadoPor = null;
			nextPublicadoAt = null;
		}
	}

	const { data: updated, error } = await locals.supabase
		.from('comentarios_internos')
		.update({
			comentario: parsed.data.comentario,
			tipo_comentario_id: tipoComentarioId,
			visible_publico: nextVisiblePublico,
			publicado_por: nextPublicadoPor,
			publicado_at: nextPublicadoAt
		})
		.eq('obra_id', params.id)
		.eq('comentario_id', params.comentarioId)
		.select('*')
		.single();

	if (error || !updated) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el comentario' },
			{ status: 500 }
		);
	}

	return json({ comentario: updated });
};

export const DELETE: RequestHandler = async ({ locals, params }) => {
	const { profile, assignedEditor } = await getObraContext({ locals }, params.id, {
		requireComment: true
	});

	const comentarioLookup = await findComentarioById(locals, params.id, params.comentarioId);
	if (comentarioLookup.error) {
		return json({ error: 'db_error', message: comentarioLookup.error }, { status: 500 });
	}
	const comentarioActual = comentarioLookup.comentario;
	if (!comentarioActual) {
		return json({ error: 'not_found', message: 'Comentario no encontrado' }, { status: 404 });
	}

	const canManageAll = isAdminOrIp(profile.roleTerm);
	const canPublishPublicComments = canManageAll || assignedEditor;
	if (comentarioActual.visible_publico && !canPublishPublicComments) {
		return forbiddenResponse('No tienes permisos para eliminar un comentario publicado');
	}
	if (!comentarioActual.visible_publico && !canManageAll && comentarioActual.user_id !== profile.userId) {
		return forbiddenResponse('No tienes permisos para eliminar este comentario');
	}

	const tipoActual = await resolveTipoComentarioTerm(locals, comentarioActual.tipo_comentario_id);
	if (tipoActual === 'estado') {
		return conflictResponse('Los comentarios de estado son de solo lectura');
	}

	const { error, count } = await locals.supabase
		.from('comentarios_internos')
		.delete({ count: 'exact' })
		.eq('obra_id', params.id)
		.eq('comentario_id', params.comentarioId);

	if (error) {
		return json(
			{ error: 'db_error', message: error.message ?? 'No se pudo eliminar el comentario' },
			{ status: 500 }
		);
	}
	if ((count ?? 0) === 0) {
		return forbiddenResponse(
			'No se pudo eliminar el comentario. Verifica permisos de borrado en la base de datos.'
		);
	}

	return json({ ok: true });
};
