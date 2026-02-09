import { browser } from '$app/environment';
import { createBrowserClient } from '@supabase/ssr';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';

let browserClient: SupabaseClient<Database> | null = null;

function readSupabaseEnv() {
	const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL ?? import.meta.env.VITE_SUPABASE_URL;
	const supabaseAnonKey =
		import.meta.env.PUBLIC_SUPABASE_ANON_KEY ?? import.meta.env.VITE_SUPABASE_ANON_KEY;

	if (!supabaseUrl || !supabaseAnonKey) {
		throw new Error('Supabase environment variables are missing in browser runtime.');
	}

	return { supabaseUrl, supabaseAnonKey };
}

export function getSupabaseBrowserClient(): SupabaseClient<Database> {
	if (!browser) {
		throw new Error('Browser supabase client cannot be instantiated on the server.');
	}

	if (browserClient) {
		return browserClient;
	}

	const { supabaseUrl, supabaseAnonKey } = readSupabaseEnv();
	browserClient = createBrowserClient<Database>(supabaseUrl, supabaseAnonKey);
	return browserClient;
}
