import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { loadPublicForm } from '$lib/server/formas-publicas';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

export const load: PageServerLoad = async ({ locals, params }) => {
	await requireSectionVisible(locals, 'formas');
	let forma;
	try {
		forma = await loadPublicForm(locals.supabase, params.slug);
	} catch (cause) {
		throw error(
			500,
			cause instanceof Error
				? `No se pudo cargar la forma: ${cause.message}`
				: 'No se pudo cargar la forma.'
		);
	}
	if (!forma) throw error(404, 'No existe esa forma en el catálogo.');
	return { forma };
};
