import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { comentarioInputSchema, comentarioListQuerySchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { getObraContext, requireAuthenticated } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';

type ComentarioTipoTerm = 'general' | 'revision' | 'tecnico' | 'estado';

type ComentarioWithMeta = Tables<'comentarios_internos'> & {
	tipo_comentario_id?: string | null;
	secuencia_id?: string | null;
	jornada_id?: string | null;
	cuadro_id?: string | null;
	rango_id?: string | null;
};

type ContextMaps = {
	secuenciaById: Map<string, Pick<Tables<'secuencias_metricas'>, 'secuencia_id' | 'v_ini' | 'v_fin'>>;
	jornadaById: Map<string, Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>;
	cuadroById: Map<string, Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'v_ini' | 'v_fin'>>;
};

function isAdminOrIp(roleTerm: string): boolean {
	return roleTerm === 'admin' || roleTerm === 'ip';
}

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

function contextLabel(comment: ComentarioWithMeta, maps: ContextMaps): string | null {
	if (comment.secuencia_id) {
		const secuencia = maps.secuenciaById.get(comment.secuencia_id);
		return secuencia ? `Secuencia vv. ${secuencia.v_ini}-${secuencia.v_fin}` : 'Secuencia';
	}
	if (comment.cuadro_id) {
		const cuadro = maps.cuadroById.get(comment.cuadro_id);
		return cuadro ? `Cuadro ${cuadro.cuadro_num} (vv. ${cuadro.v_ini}-${cuadro.v_fin})` : 'Cuadro';
	}
	if (comment.jornada_id) {
		const jornada = maps.jornadaById.get(comment.jornada_id);
		return jornada ? `Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})` : 'Jornada';
	}
	if (comment.rango_id) {
		return 'Rango de autoría';
	}
	return null;
}

async function loadContextMaps(locals: App.Locals, commentsRows: ComentarioWithMeta[]): Promise<ContextMaps> {
	const secuenciaIds = [
		...new Set(commentsRows.map((comment) => comment.secuencia_id).filter(Boolean) as string[])
	];
	const jornadaIds = [
		...new Set(commentsRows.map((comment) => comment.jornada_id).filter(Boolean) as string[])
	];
	const cuadroIds = [...new Set(commentsRows.map((comment) => comment.cuadro_id).filter(Boolean) as string[])];

	const [secuenciasResp, jornadasResp, cuadrosResp] = await Promise.all([
		secuenciaIds.length > 0
			? locals.supabase
					.from('secuencias_metricas')
					.select('secuencia_id,v_ini,v_fin')
					.in('secuencia_id', secuenciaIds)
			: Promise.resolve({ data: [] as Pick<Tables<'secuencias_metricas'>, 'secuencia_id' | 'v_ini' | 'v_fin'>[] }),
		jornadaIds.length > 0
			? locals.supabase
					.from('jornadas')
					.select('jornada_id,jornada_num,v_ini,v_fin')
					.in('jornada_id', jornadaIds)
			: Promise.resolve({ data: [] as Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>[] }),
		cuadroIds.length > 0
			? locals.supabase
					.from('cuadros')
					.select('cuadro_id,cuadro_num,v_ini,v_fin')
					.in('cuadro_id', cuadroIds)
			: Promise.resolve({ data: [] as Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'v_ini' | 'v_fin'>[] })
	]);

	return {
		secuenciaById: new Map((secuenciasResp.data ?? []).map((row) => [row.secuencia_id, row])),
		jornadaById: new Map((jornadasResp.data ?? []).map((row) => [row.jornada_id, row])),
		cuadroById: new Map((cuadrosResp.data ?? []).map((row) => [row.cuadro_id, row]))
	};
}

export const GET: RequestHandler = async ({ locals, params, url }) => {
	const { profile } = await getObraContext({ locals }, params.id, { requireEdit: false });

	const parsedQuery = comentarioListQuerySchema.safeParse({
		secuencia_id: url.searchParams.get('secuencia_id') ?? undefined,
		jornada_id: url.searchParams.get('jornada_id') ?? undefined,
		cuadro_id: url.searchParams.get('cuadro_id') ?? undefined,
		rango_id: url.searchParams.get('rango_id') ?? undefined,
		limit: url.searchParams.get('limit') ?? undefined,
		offset: url.searchParams.get('offset') ?? undefined
	});
	if (!parsedQuery.success) {
		return validationErrorResponse(parsedQuery.error);
	}
	const { secuencia_id, jornada_id, cuadro_id, rango_id, limit, offset } = parsedQuery.data;

	let commentsQuery = locals.supabase
		.from('comentarios_internos')
		.select('*')
		.eq('obra_id', params.id)
		.order('created_at', { ascending: false })
		.range(offset, offset + limit - 1);

	if (secuencia_id) commentsQuery = commentsQuery.eq('secuencia_id', secuencia_id);
	if (jornada_id) commentsQuery = commentsQuery.eq('jornada_id', jornada_id);
	if (cuadro_id) commentsQuery = commentsQuery.eq('cuadro_id', cuadro_id);
	if (rango_id) commentsQuery = commentsQuery.eq('rango_id', rango_id);

	const { data: comments, error } = await commentsQuery;

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
	const contextMaps = await loadContextMaps(locals, commentsRows);

	const names = new Map((editores ?? []).map((editor) => [editor.user_id, editor.nombre_completo]));
	const tipoById = new Map((tipos ?? []).map((tipo) => [tipo.termino_id, tipo.termino as ComentarioTipoTerm]));
	const canManageAll = isAdminOrIp(profile.roleTerm);

	return json({
		items: commentsRows.map((comment) => {
			const tipoTerm = comment.tipo_comentario_id
				? (tipoById.get(comment.tipo_comentario_id) ?? 'general')
				: 'general';
			const locked = tipoTerm === 'estado';
			const canMutate = !locked && (canManageAll || comment.user_id === profile.userId);
			return {
				...comment,
				nombre_editor: comment.user_id ? (names.get(comment.user_id) ?? 'Editor') : 'Editor',
				tipo_comentario_term: tipoTerm,
				contexto_label: contextLabel(comment, contextMaps),
				locked,
				can_edit: canMutate,
				can_delete: canMutate
			};
		})
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
