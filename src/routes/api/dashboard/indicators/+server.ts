import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { countUnreadNotifications, getMisObrasCount } from '$lib/server/dashboard';

export const GET: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });

	const [misObrasCount, notificationsUnreadCount] = await Promise.all([
		getMisObrasCount(locals, profile),
		countUnreadNotifications(locals, profile, 7)
	]);

	return json({
		misObrasCount,
		notificationsUnreadCount,
		generatedAt: new Date().toISOString()
	});
};
