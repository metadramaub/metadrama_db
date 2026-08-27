import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { loadPublicForms } from '$lib/server/formas-publicas';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'formas');
	try {
		return { formas: await loadPublicForms(locals.supabase) };
	} catch (cause) {
		throw error(
			500,
			cause instanceof Error
				? `No se pudo cargar el catálogo de formas: ${cause.message}`
				: 'No se pudo cargar el catálogo de formas.'
		);
	}
};
