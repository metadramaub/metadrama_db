import type { PageServerLoad } from './$types';
import { getNotifications } from '$lib/server/dashboard';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const notifications = await getNotifications(locals, profile, 7, 200, parentData.importador != null);

	return { notifications };
};
