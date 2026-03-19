import { browser } from '$app/environment';
import { env as publicEnv } from '$env/dynamic/public';
import { createBrowserClient } from '@supabase/ssr';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';

let browserClient: SupabaseClient<Database> | null = null;

function readSupabaseEnv() {
	const viteEnv = import.meta.env as Record<string, string | undefined>;
	const supabaseUrl = publicEnv.PUBLIC_SUPABASE_URL || viteEnv.VITE_SUPABASE_URL;
	const supabaseAnonKey = publicEnv.PUBLIC_SUPABASE_ANON_KEY || viteEnv.VITE_SUPABASE_ANON_KEY;

	if (!supabaseUrl || !supabaseAnonKey) {
		throw new Error(
			'Missing Supabase browser env. Define PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY (or VITE_* fallback).'
		);
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
