import { createServerClient } from '@supabase/ssr';
import type { Handle } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';
import type { Database } from '$lib/types/database.types';
import { env as publicEnv } from '$env/dynamic/public';
import { env as privateEnv } from '$env/dynamic/private';
import {
	GLOBAL_ACCESS_PASSWORD_ENV,
	hasValidGlobalAccess
} from '$lib/server/global-access';

function readSupabaseEnv() {
	const supabaseUrl = publicEnv.PUBLIC_SUPABASE_URL ?? privateEnv.VITE_SUPABASE_URL;
	const supabaseAnonKey =
		publicEnv.PUBLIC_SUPABASE_ANON_KEY ?? privateEnv.VITE_SUPABASE_ANON_KEY;

	if (!supabaseUrl || !supabaseAnonKey) {
		throw new Error(
			'Missing Supabase environment variables. Set PUBLIC_SUPABASE_URL/PUBLIC_SUPABASE_ANON_KEY or VITE equivalents.'
		);
	}

	return { supabaseUrl, supabaseAnonKey };
}

export const handle: Handle = async ({ event, resolve }) => {
	const { supabaseUrl, supabaseAnonKey } = readSupabaseEnv();

	event.locals.supabase = createServerClient<Database>(supabaseUrl, supabaseAnonKey, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			setAll: (cookiesToSet) => {
				cookiesToSet.forEach(({ name, value, options }) =>
					event.cookies.set(name, value, { ...options, path: '/' })
				);
			}
		}
	});

	event.locals.safeGetSession = async () => {
		const {
			data: { user },
			error
		} = await event.locals.supabase.auth.getUser();

		if (error || !user) {
			return { session: null, user: null };
		}

		return { session: null, user };
	};

	const accessPassword = privateEnv[GLOBAL_ACCESS_PASSWORD_ENV]?.trim() ?? '';
	if (requiresGlobalAccess(event.url.pathname) && !hasValidGlobalAccess(event.cookies, accessPassword)) {
		const redirectTo = encodeURIComponent(event.url.pathname + event.url.search);
		throw redirect(303, `/acceso?redirectTo=${redirectTo}`);
	}

	return resolve(event);
};

function requiresGlobalAccess(pathname: string): boolean {
	if (pathname === '/acceso') return false;
	if (pathname === '/login' || pathname.startsWith('/auth/')) return false;
	if (pathname.startsWith('/_app/')) return false;
	if (pathname === '/favicon.ico' || pathname === '/robots.txt' || pathname === '/sitemap.xml') {
		return false;
	}

	return true;
}
