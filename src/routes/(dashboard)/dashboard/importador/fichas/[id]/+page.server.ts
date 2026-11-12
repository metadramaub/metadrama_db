import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';
import {
	clienteImportador,
	consultarImportacion,
	ErrorImportacion
} from '$lib/server/importador-metrico/persistencia';
import { corregirFichaGuardada, obtenerReferenciaImportador, vistaDeFichaGuardada } from '$lib/server/importador-metrico/vista-previa';

export const load: PageServerLoad = async (event) => {
	const profile = await requireEditorProfile(event);
	try {
		const f = await consultarImportacion(clienteImportador(event.locals.supabase), event.params.id);
		return {
			obraId: f.obra_id,
			puedeEditarMetadatos: ['admin', 'ip'].includes(profile.roleTerm),
			puedeEditarMetrica: f.puede_editar,
			modificadoEn: f.modificado_en,
			formas: f.puede_editar ? obtenerReferenciaImportador().formas : [],
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

async function revisar(event: Parameters<Actions[string]>[0], guardar: boolean) {
	const profile = await requireEditorProfile(event);
	try {
		const ficha = await consultarImportacion(clienteImportador(event.locals.supabase), event.params.id);
		if (!ficha.puede_editar) return fail(403, { mensaje: 'No puedes editar la métrica de esta ficha.' });

		const form = await event.request.formData();
		if (form.get('importacion_id') !== ficha.importacion_id || form.get('modificado_en') !== (ficha.modificado_en ?? '')) {
			return fail(409, { mensaje: 'La ficha ha cambiado. Recarga antes de volver a editar.' });
		}
		const entrada = form.get('cambio');
		if (typeof entrada !== 'string' || !entrada || entrada.length > 2_000_000) {
			return fail(400, { mensaje: 'El cambio de secuencia no es válido.' });
		}
		let corregida;
		try {
			corregida = corregirFichaGuardada(ficha.datos_confirmados, ficha.entrada_original, JSON.parse(entrada));
		} catch (e) {
			return fail(400, { mensaje: e instanceof Error ? e.message : 'Revisa los cambios de secuencia.' });
		}
		if (!guardar) {
			return { revision: vistaDeFichaGuardada(corregida, ficha.entrada_original, {
				obra_id: ficha.obra_id,
				importacion_id: ficha.importacion_id
			}) };
		}

		const resultado = await clienteImportador(getSupabaseAdmin()).rpc('editar_metrica_ficha_basica', {
			p_importacion: ficha.importacion_id,
			p_actor: profile.userId,
			p_modificado_en: ficha.modificado_en,
			p_datos: corregida
		});
		if (resultado.error) {
			const codigo = resultado.error.code;
			if (codigo === '42501') return fail(403, { mensaje: 'No puedes editar la métrica de esta ficha.' });
			if (codigo === '40001' || codigo === '23514' || codigo === 'P0002')
				return fail(409, { mensaje: resultado.error.message ?? 'No se pudo aplicar el cambio.' });
			return fail(503, { mensaje: 'No se pudo guardar la corrección métrica.' });
		}
		return { guardada: true };
	} catch (e) {
		return fail(e instanceof ErrorImportacion ? e.status : 503, {
			mensaje: e instanceof ErrorImportacion ? e.message : 'No se pudo editar la ficha básica.'
		});
	}
}

export const actions: Actions = {
	revisar: (event) => revisar(event, false),
	guardar: (event) => revisar(event, true)
};
