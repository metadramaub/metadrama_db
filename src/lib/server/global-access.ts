import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { dev } from '$app/environment';
import type { Cookies } from '@sveltejs/kit';

export const GLOBAL_ACCESS_COOKIE = 'metadrama_global_access';
export const GLOBAL_ACCESS_PASSWORD_ENV = 'GLOBAL_ACCESS_PASSWORD';

const TOKEN_VERSION = 'v1';
const TOKEN_MAX_AGE_SECONDS = 60 * 60 * 12;

export function createGlobalAccessToken(password: string): string {
	const issuedAt = Math.floor(Date.now() / 1000).toString();
	const nonce = randomBytes(16).toString('base64url');
	const payload = `${TOKEN_VERSION}.${issuedAt}.${nonce}`;
	const signature = signPayload(payload, password);

	return `${payload}.${signature}`;
}

export function hasValidGlobalAccess(cookies: Cookies, password: string): boolean {
	const token = cookies.get(GLOBAL_ACCESS_COOKIE);
	if (!token) return false;

	const parts = token.split('.');
	if (parts.length !== 4) return false;

	const [version, issuedAtValue, nonce, signature] = parts;
	if (version !== TOKEN_VERSION || !issuedAtValue || !nonce || !signature) return false;

	const issuedAt = Number(issuedAtValue);
	if (!Number.isInteger(issuedAt)) return false;

	const now = Math.floor(Date.now() / 1000);
	if (issuedAt > now || now - issuedAt > TOKEN_MAX_AGE_SECONDS) return false;

	const expectedSignature = signPayload(`${version}.${issuedAtValue}.${nonce}`, password);
	return secureEquals(signature, expectedSignature);
}

export function passwordMatches(submittedPassword: string, configuredPassword: string): boolean {
	return secureEquals(submittedPassword, configuredPassword);
}

export function setGlobalAccessCookie(cookies: Cookies, password: string) {
	cookies.set(GLOBAL_ACCESS_COOKIE, createGlobalAccessToken(password), {
		path: '/',
		httpOnly: true,
		sameSite: 'lax',
		secure: !dev,
		maxAge: TOKEN_MAX_AGE_SECONDS
	});
}

function signPayload(payload: string, password: string): string {
	return createHmac('sha256', password).update(payload).digest('base64url');
}

function secureEquals(left: string, right: string): boolean {
	const leftBuffer = Buffer.from(left);
	const rightBuffer = Buffer.from(right);

	if (leftBuffer.byteLength !== rightBuffer.byteLength) {
		return false;
	}

	return timingSafeEqual(leftBuffer, rightBuffer);
}
