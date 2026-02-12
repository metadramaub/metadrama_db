import { isHttpError, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';
import { obraDeleteSchema } from '$lib/utils/validators';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canDeleteObras } from '$lib/utils/permissions';

export const GET: RequestHandler = async ({ locals, params }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id, { requireEdit: false });

	const [jornadas, secuencias, comentarios] = await Promise.all([
		locals.supabase.from('jornadas').select('*').eq('obra_id', obra.obra_id).order('v_ini'),
		locals.supabase
			.from('secuencias_metricas')
			.select('*')
			.eq('obra_id', obra.obra_id)
			.order('v_ini'),
		locals.supabase
			.from('comentarios_internos')
			.select('*')
			.eq('obra_id', obra.obra_id)
			.order('created_at', { ascending: false })
	]);

	const jornadasRows = (jornadas.data ?? []) as Tables<'jornadas'>[];
	const secuenciasRows = (secuencias.data ?? []) as Tables<'secuencias_metricas'>[];
	const comentariosRows = (comentarios.data ?? []) as Tables<'comentarios_internos'>[];

	const jornadaIds = jornadasRows.map((item) => item.jornada_id);
	const { data: cuadros } =
		jornadaIds.length > 0
			? await locals.supabase
					.from('cuadros')
					.select('*')
					.in('jornada_id', jornadaIds)
					.order('v_ini')
			: { data: [] };

	return json({
		obra,
		profile,
		jornadas: jornadasRows,
		cuadros: (cuadros ?? []) as Tables<'cuadros'>[],
		secuencias: secuenciasRows,
		comentarios: comentariosRows
	});
};

export const DELETE: RequestHandler = async ({ locals, params, request }) => {
	let context: Awaited<ReturnType<typeof getObraContext>>;
	try {
		context = await getObraContext({ locals }, params.id, { requireDelete: true });
	} catch (error) {
		if (isHttpError(error) && error.status === 403) {
			return forbiddenResponse('Solo admin o IP pueden eliminar obras.');
		}
		throw error;
	}

	const { profile, obra } = context;
	if (!canDeleteObras(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden eliminar obras.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = obraDeleteSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { error } = await locals.supabase.from('obras').delete().eq('obra_id', obra.obra_id);
	if (error) {
		const status = error.code === '23503' ? 409 : 500;
		const message =
			error.code === '23503'
				? 'No se puede eliminar la obra por dependencias activas.'
				: 'No se pudo eliminar la obra.';
		return json({ error: 'db_error', message, details: error.message }, { status });
	}

	return json({ deleted: true, obraId: obra.obra_id });
};
