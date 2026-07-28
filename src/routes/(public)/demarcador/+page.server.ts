import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import { esArtefactoDemarcadorNuevo } from '$lib/server/demarcador-nuevo';

export const load: PageServerLoad = async ({ locals, url }) => {
	await requireSectionVisible(locals, 'demarcador');

	const requestedVersionId = url.searchParams.get('version')?.trim() || null;
	let query = locals.supabase
		.from('demarcador_versiones')
		.select('version_id,numero,estado,artefacto,generado_en,publicado_en');

	query = requestedVersionId
		? query.eq('version_id', requestedVersionId)
		: query.eq('estado', 'publicada').order('publicado_en', { ascending: false }).limit(1);

	const { data, error: dbError } = await query.maybeSingle();
	if (dbError) {
		throw error(500, `No se pudo cargar el demarcador: ${dbError.message}`);
	}
	if (requestedVersionId && !data) {
		throw error(404, 'Versión del demarcador no encontrada o no accesible.');
	}
	if (!data) {
		return {
			artefacto: null,
			version: null,
			esVistaPrevia: false
		};
	}
	if (!esArtefactoDemarcadorNuevo(data.artefacto)) {
		throw error(500, 'La versión publicada del demarcador tiene un formato no reconocido.');
	}

	return {
		artefacto: data.artefacto,
		version: {
			version_id: data.version_id,
			numero: data.numero,
			estado: data.estado,
			generado_en: data.generado_en,
			publicado_en: data.publicado_en
		},
		esVistaPrevia: data.estado !== 'publicada'
	};
};
