import type { PageServerLoad } from './$types';
import { getDashboardGuideIndexPayload } from '$lib/server/dashboard-guide';

export const load: PageServerLoad = async () => {
	return getDashboardGuideIndexPayload();
};

