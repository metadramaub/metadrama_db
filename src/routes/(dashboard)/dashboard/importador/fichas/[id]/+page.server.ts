import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import {
	clienteImportador,
	consultarImportacion,
	ErrorImportacion
} from '$lib/server/importador-metrico/persistencia';
import { vistaDeFichaGuardada } from '$lib/server/importador-metrico/vista-previa';

export const load: PageServerLoad = async (event) => {
	await requireEditorProfile(event);
	try {
		const f = await consultarImportacion(clienteImportador(event.locals.supabase), event.params.id);
		return {
			importadoPor: f.importado_por,
			importadoEn: f.importado_en,
			vista: vistaDeFichaGuardada(f.datos_confirmados, f.entrada_original, {
				obra_id: f.obra_id,
				importacion_id: f.importacion_id
			})
		};
	} catch (e) {
		throw error(
			e instanceof ErrorImportacion ? e.status : 503,
			e instanceof ErrorImportacion ? e.message : 'No se pudo cargar la ficha básica.'
		);
	}
};
