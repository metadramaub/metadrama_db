import { modeloEditorialActivo, relacionObras } from '$lib/server/modelo-obras';
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { obraDatosPatchSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { esFichaBasica, esObraSinFicha, requiereInicioCompleta } from '$lib/importador-metrico/tipo-ficha';

function normalizeTitulo(titulo: string) {
	return titulo.normalize('NFD').replaceAll(/\p{M}/gu, '').trim().toLowerCase();
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const { obra } = await getObraContext({ locals }, params.id, { requireEditMetadata: true });

	const body = await request.json().catch(() => ({}));
	const parsed = obraDatosPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const soloDatos = esObraSinFicha(obra) || esFichaBasica(obra) || requiereInicioCompleta(obra);
	if (soloDatos && payload.edicion !== undefined) {
		return json({ message: 'La edición base se guarda desde la ficha.' }, { status: 409 });
	}
	if (modeloEditorialActivo() && ['fecha_inicio_trad','fecha_fin_trad','fuente_fecha','fecha_inicio_metadrama','fecha_fin_metadrama']
		.some(key => Object.prototype.hasOwnProperty.call(body, key))) {
		return json({ message: 'El modelo de fechas se ha actualizado. Conserva tus cambios y recarga el editor antes de guardar.' }, { status: 409 });
	}
	const tituloToPersist = payload.titulo ?? obra.titulo;
	if (payload.dataciones !== undefined && !modeloEditorialActivo()) {
		return json({ message: 'El nuevo modelo de dataciones aún no está activado' }, { status: 409 });
	}
	const fechas = payload.dataciones !== undefined ? { dataciones: payload.dataciones } : {
		fecha_inicio_trad: payload.fecha_inicio_trad,
		fecha_fin_trad: payload.fecha_fin_trad,
		fuente_fecha: payload.fuente_fecha,
		fecha_inicio_metadrama: payload.fecha_inicio_metadrama,
		fecha_fin_metadrama: payload.fecha_fin_metadrama
	};

	const { data, error } = await locals.supabase
		.from(relacionObras())
		.update({
			titulo: tituloToPersist,
			titulo_normalizado: normalizeTitulo(tituloToPersist),
			variantes_titulo: payload.variantes_titulo,
			genero_id: payload.genero_id,
			...fechas,
			edicion: payload.edicion
		})
		.eq('obra_id', params.id)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar' },
			{ status: ['40001','PT409'].includes(error?.code ?? '') ? 409 : 500 }
		);
	}

	return json({ obra: data });
};
