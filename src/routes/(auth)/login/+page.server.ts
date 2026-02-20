import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

type AuthStatus = 'password_set' | 'link_error' | 'session_required';

function parseAuthStatus(value: string | null): AuthStatus | null {
	if (value === 'password_set' || value === 'link_error' || value === 'session_required') {
		return value;
	}
	return null;
}

export const load: PageServerLoad = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();
	if (user) {
		throw redirect(303, '/dashboard/obras?scope=mine');
	}

	return {
		redirectTo: url.searchParams.get('redirectTo') ?? '/dashboard/obras?scope=mine',
		authStatus: parseAuthStatus(url.searchParams.get('auth'))
	};
};
