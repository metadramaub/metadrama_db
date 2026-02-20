import { redirect } from '@sveltejs/kit';
import type { EmailOtpType } from '@supabase/supabase-js';
import type { PageServerLoad } from './$types';

function parseEmailType(value: string | null): EmailOtpType | null {
	if (value === 'invite' || value === 'recovery' || value === 'email') {
		return value;
	}
	return null;
}

function nextPathForType(type: EmailOtpType | null): string {
	if (type === 'invite' || type === 'recovery') {
		return '/auth/set-password';
	}
	return '/login';
}

export const load: PageServerLoad = async ({ locals, url }) => {
	const code = url.searchParams.get('code');
	const tokenHash = url.searchParams.get('token_hash') ?? url.searchParams.get('token');
	const emailType = parseEmailType(url.searchParams.get('type'));
	const authError = url.searchParams.get('error') ?? url.searchParams.get('error_code');

	if (authError) {
		throw redirect(303, '/login?auth=link_error');
	}

	if (code) {
		const { error } = await locals.supabase.auth.exchangeCodeForSession(code);
		if (error) {
			throw redirect(303, '/login?auth=link_error');
		}

		throw redirect(303, nextPathForType(emailType));
	}

	if (tokenHash && emailType) {
		const { error } = await locals.supabase.auth.verifyOtp({
			token_hash: tokenHash,
			type: emailType
		});
		if (error) {
			throw redirect(303, '/login?auth=link_error');
		}

		throw redirect(303, nextPathForType(emailType));
	}

	// Some invite links complete the auth flow on the browser and provide
	// access_token/refresh_token inside location.hash. The server cannot read
	// URL fragments, so the page component handles that fallback flow.
	return {};
};
