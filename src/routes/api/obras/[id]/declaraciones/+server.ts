import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { obraDeclaracionesPatchSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';

/**
 * Lo que no hay en la obra: figuras de donaire, personajes sobrenaturales, eventos sobrenaturales.
 *
 * Tiene endpoint propio y no va con los datos de la obra porque **se marca antes de anotar**, en la
 * pestaña de secuencias, que es donde se entiende y donde actúa. Compartir el de datos obligaría a
 * que aquel distinguiera entre «no me mandas el campo» y «me lo mandas vacío», y una pestaña
 * acabaría borrando lo que la otra escribe.
 *
 * **Marcarlo arrastra**, y de eso se encarga la base: un disparador responde por las secuencias que
 * aún callaban y rechaza la marca cuando alguna declara lo contrario. Ese rechazo llega aquí como
 * error de la base con un mensaje escrito para leerse, y se devuelve tal cual.
 */
export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = obraDeclaracionesPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data, error } = await locals.supabase
		.from('obras')
		.update({
			sin_figuras_donaire: parsed.data.sin_figuras_donaire,
			sin_personajes_sobrenaturales: parsed.data.sin_personajes_sobrenaturales,
			sin_eventos_sobrenaturales: parsed.data.sin_eventos_sobrenaturales
		})
		.eq('obra_id', params.id)
		.select('*')
		.single();

	if (error || !data) {
		// El disparador habla en castellano y dice qué quitar antes; no hay nada que reescribir.
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo guardar lo que la obra no tiene' },
			{ status: error?.code === '23514' ? 409 : 500 }
		);
	}

	return json({ obra: data });
};
