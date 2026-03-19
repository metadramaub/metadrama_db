import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getDashboardGuidePagePayload } from '$lib/server/dashboard-guide';

export const load: PageServerLoad = async ({ params }) => {
	const payload = getDashboardGuidePagePayload(params.slug);
	if (!payload) {
		throw error(404, 'Capítulo de guía no encontrado');
	}
	return payload;
};
