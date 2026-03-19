import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getFirstDashboardGuideChapterSlug } from '$lib/server/dashboard-guide';

export const load: PageServerLoad = async () => {
	const firstSlug = getFirstDashboardGuideChapterSlug();
	if (!firstSlug) {
		throw redirect(303, '/dashboard');
	}
	throw redirect(303, `/dashboard/guia/${firstSlug}`);
};

