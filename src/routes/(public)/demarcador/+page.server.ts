import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { cargarCatalogoDemarcador } from '$lib/server/demarcador-metrico';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'demarcador');
	const { user } = await locals.safeGetSession();
	if (!user) {
		return {
			catalogo: { formas: [], hipotesis: [], advertencias: [] },
			accesoRestringido: true
		};
	}
	try {
		const catalogo = await cargarCatalogoDemarcador(locals.supabase);
		return {
			catalogo,
			accesoRestringido: catalogo.hipotesis.length === 0
		};
	} catch (cause) {
		throw error(
			500,
			cause instanceof Error
				? `No se pudo preparar el demarcador: ${cause.message}`
				: 'No se pudo preparar el demarcador.'
		);
	}
};
