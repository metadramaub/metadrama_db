import { createServerClient } from '@supabase/ssr';
import type { Handle } from '@sveltejs/kit';
import type { Database } from '$lib/types/database.types';
import { env as publicEnv } from '$env/dynamic/public';
import { env as privateEnv } from '$env/dynamic/private';

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
			data: { session }
		} = await event.locals.supabase.auth.getSession();

		if (!session) {
			return { session: null, user: null };
		}

		const {
			data: { user },
			error
		} = await event.locals.supabase.auth.getUser();

		if (error) {
			return { session: null, user: null };
		}

		return { session, user };
	};

	return resolve(event);
};
