import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getInformePorSlug } from '$lib/server/migracion-informes';

export const load: PageServerLoad = async ({ locals, params, parent }) => {
	const { profile } = await parent();
	const { informe, permitido } = await getInformePorSlug(locals.supabase, profile, params.slug);
	if (!informe) {
		throw error(404, 'No hay informe de migración para esa obra.');
	}
	if (!permitido) {
		throw error(403, 'Este informe solo lo ven admin, el IP y el editor asignado a la obra.');
	}
	return { profile, informe };
};
