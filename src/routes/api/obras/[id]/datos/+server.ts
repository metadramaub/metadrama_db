import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { obraDatosPatchSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';

function normalizeTitulo(titulo: string) {
	return titulo.normalize('NFD').replaceAll(/\p{M}/gu, '').trim().toLowerCase();
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = obraDatosPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;

	const { data, error } = await locals.supabase
		.from('obras')
		.update({
			titulo: payload.titulo,
			titulo_normalizado: normalizeTitulo(payload.titulo),
			variantes_titulo: payload.variantes_titulo,
			genero_id: payload.genero_id,
			fecha_inicio_trad: payload.fecha_inicio_trad,
			fecha_fin_trad: payload.fecha_fin_trad,
			fuente_fecha: payload.fuente_fecha,
			fecha_inicio_metadrama: payload.fecha_inicio_metadrama,
			fecha_fin_metadrama: payload.fecha_fin_metadrama,
			edicion: payload.edicion
		})
		.eq('obra_id', params.id)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar' },
			{ status: 500 }
		);
	}

	return json({ obra: data });
};
