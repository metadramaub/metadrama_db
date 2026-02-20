import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { getEditorProfile } from '$lib/server/auth';
import { countUnreadNotifications } from '$lib/server/dashboard';

export const load: LayoutServerLoad = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();

	if (!user) {
		const redirectTo = encodeURIComponent(url.pathname + url.search);
		throw redirect(303, `/login?redirectTo=${redirectTo}`);
	}

	const profile = await getEditorProfile({ locals }, user.id);

	const notificationsUnreadCount = await countUnreadNotifications(locals, profile, 7);

	return {
		user,
		profile,
		notificationsUnreadCount
	};
};
