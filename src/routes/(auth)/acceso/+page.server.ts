import { fail, redirect } from '@sveltejs/kit';
import { env as privateEnv } from '$env/dynamic/private';
import type { Actions, PageServerLoad } from './$types';
import {
	GLOBAL_ACCESS_PASSWORD_ENV,
	hasValidGlobalAccess,
	passwordMatches,
	setGlobalAccessCookie
} from '$lib/server/global-access';

export const load: PageServerLoad = async ({ cookies, url }) => {
	const accessPassword = readAccessPassword();
	const redirectTo = normalizeRedirectTo(url.searchParams.get('redirectTo'));

	if (accessPassword && hasValidGlobalAccess(cookies, accessPassword)) {
		throw redirect(303, redirectTo);
	}

	return {
		redirectTo,
		configured: Boolean(accessPassword)
	};
};

export const actions: Actions = {
	default: async ({ cookies, request, url }) => {
		const formData = await request.formData();
		const redirectTo = normalizeRedirectTo(
			String(formData.get('redirectTo') ?? url.searchParams.get('redirectTo') ?? '/')
		);
		const submittedPassword = String(formData.get('password') ?? '');
		const accessPassword = readAccessPassword();

		if (!accessPassword) {
			return fail(500, {
				redirectTo,
				error: `La variable privada ${GLOBAL_ACCESS_PASSWORD_ENV} no está configurada.`
			});
		}

		if (!passwordMatches(submittedPassword, accessPassword)) {
			return fail(400, {
				redirectTo,
				error: 'Contraseña incorrecta.'
			});
		}

		setGlobalAccessCookie(cookies, accessPassword);
		throw redirect(303, redirectTo);
	}
};

function readAccessPassword(): string {
	return privateEnv[GLOBAL_ACCESS_PASSWORD_ENV]?.trim() ?? '';
}

function normalizeRedirectTo(value: string | null): string {
	if (!value || !value.startsWith('/') || value.startsWith('//')) {
		return '/';
	}

	return value;
}
