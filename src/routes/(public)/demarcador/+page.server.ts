import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import { esArtefactoDemarcadorNuevo } from '$lib/server/demarcador-nuevo';

export const load: PageServerLoad = async ({ locals, url }) => {
	await requireSectionVisible(locals, 'demarcador');
	const metricCatalogDb = locals.supabase as unknown as {
		from: (table: string) => any;
	};

	const requestedVersionId = url.searchParams.get('version')?.trim() || null;
	let query = locals.supabase
		.from('demarcador_versiones')
		.select(
			'version_id,numero,estado,artefacto,catalogo_revision,generado_en,publicado_en'
		)
		.eq('fuente_tipo', 'catalogo_metrico');

	query = requestedVersionId
		? query.eq('version_id', requestedVersionId)
		: query.order('generado_en', { ascending: false }).limit(1);

	const [versionResponse, catalogStateResponse] = await Promise.all([
		query.maybeSingle(),
		metricCatalogDb
			.from('catalogo_metrico_estado')
			.select('revision')
			.eq('id', true)
			.maybeSingle()
	]);
	const { data, error: dbError } = versionResponse;
	if (dbError) {
		throw error(500, `No se pudo cargar el demarcador: ${dbError.message}`);
	}
	if (catalogStateResponse.error) {
		throw error(
			500,
			`No se pudo comprobar la revisión del catálogo métrico: ${catalogStateResponse.error.message}`
		);
	}
	if (requestedVersionId && !data) {
		throw error(404, 'Prueba del nuevo catálogo no encontrada o no accesible.');
	}
	if (!data) {
		return {
			artefacto: null,
			version: null,
			esVersionSolicitada: false,
			catalogoRevisionActual: catalogStateResponse.data?.revision ?? null,
			catalogoDesactualizado: false
		};
	}
	if (!esArtefactoDemarcadorNuevo(data.artefacto)) {
		throw error(500, 'La prueba del demarcador tiene un formato no reconocido.');
	}

	const catalogoRevisionActual = catalogStateResponse.data?.revision ?? null;

	return {
		artefacto: data.artefacto,
		version: {
			version_id: data.version_id,
			numero: data.numero,
			estado: data.estado,
			catalogo_revision: data.catalogo_revision,
			generado_en: data.generado_en,
			publicado_en: data.publicado_en
		},
		esVersionSolicitada: Boolean(requestedVersionId),
		catalogoRevisionActual,
		catalogoDesactualizado:
			catalogoRevisionActual !== null && data.catalogo_revision !== catalogoRevisionActual
	};
};
