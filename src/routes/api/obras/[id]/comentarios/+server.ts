import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { comentarioInputSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { getObraContext, requireAuthenticated } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';

type ComentarioWithMeta = Tables<'comentarios_internos'> & {
	tipo_comentario_id?: string | null;
	secuencia_id?: string | null;
	jornada_id?: string | null;
	cuadro_id?: string | null;
	rango_id?: string | null;
};

async function resolveTipoComentarioId(locals: App.Locals, term: 'general' | 'revision' | 'tecnico' | 'estado') {
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'tipo_comentario')
		.eq('termino', term)
		.eq('activo', true)
		.maybeSingle();
	return data?.termino_id ?? null;
}

export const GET: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const { data: comments, error } = await locals.supabase
		.from('comentarios_internos')
		.select('*')
		.eq('obra_id', params.id)
		.order('created_at', { ascending: false });

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	const commentsRows = (comments ?? []) as ComentarioWithMeta[];

	const userIds = [
		...new Set(commentsRows.map((comment) => comment.user_id).filter(Boolean) as string[])
	];
	const tipoIds = [
		...new Set(
			commentsRows.map((comment) => comment.tipo_comentario_id).filter(Boolean) as string[]
		)
	];
	const { data: editores } =
		userIds.length > 0
			? await locals.supabase
					.from('editores')
					.select('user_id,nombre_completo')
					.in('user_id', userIds)
			: { data: [] };
	const { data: tipos } =
		tipoIds.length > 0
			? await locals.supabase
					.from('vocabularios')
					.select('termino_id,termino')
					.in('termino_id', tipoIds)
			: { data: [] };

	const names = new Map((editores ?? []).map((editor) => [editor.user_id, editor.nombre_completo]));
	const tipoById = new Map((tipos ?? []).map((tipo) => [tipo.termino_id, tipo.termino]));
	return json({
		items: commentsRows.map((comment) => ({
			...comment,
			nombre_editor: comment.user_id ? (names.get(comment.user_id) ?? 'Editor') : 'Editor',
			tipo_comentario_term: comment.tipo_comentario_id
				? (tipoById.get(comment.tipo_comentario_id) ?? 'general')
				: 'general'
		}))
	});
};

export const POST: RequestHandler = async ({ locals, params, request }) => {
	const user = await requireAuthenticated({ locals });
	await getObraContext({ locals }, params.id, { requireComment: true });

	const body = await request.json().catch(() => ({}));
	const parsed = comentarioInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}
	const tipoTerm = parsed.data.tipo_comentario;
	const tipoComentarioId = await resolveTipoComentarioId(locals, tipoTerm);
	if (!tipoComentarioId) {
		return json(
			{
				error: 'validation_error',
				message: `No existe tipo_comentario '${tipoTerm}' en vocabularios.`
			},
			{ status: 422 }
		);
	}

	const { data, error } = await locals.supabase
		.from('comentarios_internos')
		.insert({
			obra_id: params.id,
			user_id: user.id,
			comentario: parsed.data.comentario,
			tipo_comentario_id: tipoComentarioId,
			secuencia_id: parsed.data.secuencia_id ?? null,
			jornada_id: parsed.data.jornada_id ?? null,
			cuadro_id: parsed.data.cuadro_id ?? null,
			rango_id: parsed.data.rango_id ?? null
		})
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo guardar el comentario' },
			{ status: 500 }
		);
	}

	return json({ comentario: data }, { status: 201 });
};
