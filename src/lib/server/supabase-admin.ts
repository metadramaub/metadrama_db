import { createClient } from '@supabase/supabase-js';
import { env } from '$env/dynamic/private';
import { env as publicEnv } from '$env/dynamic/public';
import { error } from '@sveltejs/kit';
import type { Database } from '$lib/types/database.types';

// Solo se importa desde módulos de servidor y después de comprobar admin/IP.
export function getSupabaseAdmin() {
	const url = publicEnv.PUBLIC_SUPABASE_URL ?? env.VITE_SUPABASE_URL;
	const key = env.SUPABASE_SERVICE_ROLE_KEY;
	if (!url || !key) {
		throw error(
			503,
			'La gestión de editores requiere configurar SUPABASE_SERVICE_ROLE_KEY en el servidor.'
		);
	}
	return createClient<Database>(url, key, {
		auth: {
			persistSession: false,
			autoRefreshToken: false,
			detectSessionInUrl: false,
			flowType: 'implicit'
		}
	});
}
