import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { loadMetricCatalog } from '$lib/server/catalogo-metrico';
import { loadShadowAnnotation } from '$lib/server/anotacion-en-sombra';
import { canManageVocabularios } from '$lib/utils/permissions';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();

	if (!canManageVocabularios(parentData.profile.roleTerm)) {
		throw error(403, 'Solo admin o IP pueden administrar el catálogo métrico.');
	}

	try {
		// La anotación en sombra es otra cosa que el catálogo: se carga aparte para que la
		// fase 0 pueda retirarse sin tocar el gestor.
		const [catalog, shadow] = await Promise.all([
			loadMetricCatalog(locals.supabase),
			loadShadowAnnotation(locals.supabase)
		]);
		return { ...catalog, shadow };
	} catch (cause) {
		const message =
			cause instanceof Error ? cause.message : 'No se pudo cargar el catálogo métrico.';
		throw error(500, message);
	}
};
