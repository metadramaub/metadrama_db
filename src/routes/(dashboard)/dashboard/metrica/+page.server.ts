import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { loadMetricCatalog } from '$lib/server/catalogo-metrico';
import { canManageVocabularios } from '$lib/utils/permissions';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();

	if (!canManageVocabularios(parentData.profile.roleTerm)) {
		throw error(403, 'Solo admin o IP pueden administrar el catálogo métrico.');
	}

	try {
		return await loadMetricCatalog(locals.supabase);
	} catch (cause) {
		const message =
			cause instanceof Error ? cause.message : 'No se pudo cargar el catálogo métrico.';
		throw error(500, message);
	}
};
