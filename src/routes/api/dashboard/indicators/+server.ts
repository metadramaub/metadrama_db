import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { countUnreadNotifications } from '$lib/server/dashboard';

export const GET: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });

	const notificationsUnreadCount = await countUnreadNotifications(locals, profile, 7);

	return json({
		notificationsUnreadCount,
		generatedAt: new Date().toISOString()
	});
};
