import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import type { Tables } from '$lib/types/database.types';

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
