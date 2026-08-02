import { createServerClient } from '@supabase/ssr';
import type { Cookies, Handle } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';
import type { User } from '@supabase/supabase-js';
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

// Un 4xx del servidor de auth significa que la credencial almacenada es inválida
// o ha caducado (p. ej. un refresh token rotado o revocado, o un restore de BD).
// Los fallos de red transitorios llegan como AuthRetryableFetchError con status 0
// y NO deben borrar una cookie válida.
function isInvalidStoredCredential(error: unknown): boolean {
	const status = (error as { status?: number } | null)?.status;
	return typeof status === 'number' && status >= 400 && status < 500;
}

// Borra la cookie de sesión de Supabase (sb-<ref>-auth-token, incluidos sus
// posibles fragmentos .0/.1) para que un refresh token inválido no dispare un
// refresco fallido —y su log ruidoso— en cada petición.
function clearStaleSupabaseAuthCookies(cookies: Cookies) {
	for (const { name } of cookies.getAll()) {
		if (name.startsWith('sb-') && name.includes('-auth-token')) {
			cookies.delete(name, { path: '/' });
		}
	}
}

export const handle: Handle = async ({ event, resolve }) => {
	const { supabaseUrl, supabaseAnonKey } = readSupabaseEnv();

	// Supabase refresca el token en segundo plano y avisa a sus suscriptores, que piden
	// escribir las cookies nuevas. Ese aviso puede llegar cuando la respuesta ya ha salido:
	// SvelteKit lo rechaza y, como la llamada viene de una cadena asíncrona que nadie
	// recoge, el rechazo tumba el proceso entero. Terminada la respuesta no hay dónde
	// escribir, así que se ignora; la siguiente petición vuelve a refrescar y sí guarda.
	let responseSettled = false;

	event.locals.supabase = createServerClient<Database>(supabaseUrl, supabaseAnonKey, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			setAll: (cookiesToSet) => {
				if (responseSettled) return;
				try {
					cookiesToSet.forEach(({ name, value, options }) =>
						event.cookies.set(name, value, { ...options, path: '/' })
					);
				} catch (error) {
					// Carrera con el cierre de la respuesta: el mismo caso que el anterior, pero
					// avisado entre que se genera la respuesta y se marca como terminada.
					console.warn(
						'[auth] cookies de sesión descartadas: la respuesta ya estaba generada.',
						error instanceof Error ? error.message : error
					);
				}
			}
		}
	});

	event.locals.safeGetSession = async () => {
		let user: User | null = null;
		let authError: unknown = null;

		try {
			const { data, error } = await event.locals.supabase.auth.getUser();
			user = data.user;
			authError = error;
		} catch (error) {
			// Defensivo: algunas rutas de token inválido rechazan en vez de devolver error.
			authError = error;
		}

		if (!user) {
			// Cookie de auth caducada/inválida (p. ej. "Invalid Refresh Token"): la
			// eliminamos para que el refresco fallido no se repita en cada petición.
			if (isInvalidStoredCredential(authError)) {
				clearStaleSupabaseAuthCookies(event.cookies);
			}
			return { session: null, user: null };
		}

		return { session: null, user };
	};

	try {
		const accessPassword = privateEnv[GLOBAL_ACCESS_PASSWORD_ENV]?.trim() ?? '';
		if (
			requiresGlobalAccess(event.url.pathname) &&
			!hasValidGlobalAccess(event.cookies, accessPassword)
		) {
			const redirectTo = encodeURIComponent(event.url.pathname + event.url.search);
			throw redirect(303, `/acceso?redirectTo=${redirectTo}`);
		}

		return await resolve(event);
	} finally {
		// Cubre las dos salidas, la respuesta normal y la redirección del acceso global.
		responseSettled = true;
	}
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
