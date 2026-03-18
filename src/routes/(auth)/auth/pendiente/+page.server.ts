import { redirect } from '@sveltejs/kit';
import { findEditorProfile } from '$lib/server/auth';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) {
		throw redirect(303, '/login?auth=session_required');
	}

	const profile = await findEditorProfile({ locals }, user.id);
	if (profile) {
		throw redirect(303, '/dashboard');
	}

	return {
		userId: user.id,
		email: user.email ?? ''
	};
};
