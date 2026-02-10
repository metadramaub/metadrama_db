import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();
	if (user) {
		throw redirect(303, '/dashboard/obras?scope=mine');
	}

	return {
		redirectTo: url.searchParams.get('redirectTo') ?? '/dashboard/obras?scope=mine'
	};
};
