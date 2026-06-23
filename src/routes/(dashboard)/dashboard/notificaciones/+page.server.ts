import type { PageServerLoad } from './$types';
import { getNotifications } from '$lib/server/dashboard';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const notifications = await getNotifications(locals, profile, 7, 200);

	return {
		profile,
		notifications,
		groups: {
			assignedEditor: notifications.filter((item) => item.type === 'assigned_editor'),
			assignedReview: notifications.filter((item) => item.type === 'assigned_review'),
			stateChanges: notifications.filter((item) => item.type === 'state_change'),
			comments: notifications.filter((item) => item.type === 'comment')
		}
	};
};
