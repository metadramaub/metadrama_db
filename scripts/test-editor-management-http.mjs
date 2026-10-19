/** Prueba HTTP local con cuentas temporales en Supabase, sin enviar correos. */
import { readFileSync } from 'node:fs';
import { randomUUID, randomBytes } from 'node:crypto';
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';
import { createServerClient } from '@supabase/ssr';

if (!process.argv.includes('--allow-live-fixtures')) {
	throw new Error(
		'Esta prueba crea y elimina cuentas y obras temporales. Usa --allow-live-fixtures con el servidor local arrancado.'
	);
}
const origin = 'http://localhost:5174';
const env = Object.fromEntries(
	readFileSync('.env.local', 'utf8')
		.split(/\r?\n/)
		.filter((line) => /^[A-Z_]+=/.test(line))
		.map((line) => {
			const position = line.indexOf('=');
			return [
				line.slice(0, position),
				line
					.slice(position + 1)
					.trim()
					.replace(/^["']|["']$/g, '')
			];
		})
);
const admin = createClient(env.PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
	auth: { persistSession: false, autoRefreshToken: false }
});
const fixtures = { users: [], works: [] };
const suffix = randomUUID();
const password = randomBytes(32).toString('base64url');
const prefix = `Prueba HTTP gestión ${suffix}`;
let managerClient;
let editorClient;

async function session(email) {
	const cookies = new Map();
	const access = await fetch(`${origin}/acceso`, {
		method: 'POST',
		redirect: 'manual',
		headers: { Origin: origin, Accept: 'text/html' },
		body: new URLSearchParams({ password: env.GLOBAL_ACCESS_PASSWORD, redirectTo: '/dashboard' })
	});
	assert.equal(access.status, 303, 'Acceso global');
	for (const cookie of access.headers.getSetCookie()) {
		const pair = cookie.split(';')[0];
		const position = pair.indexOf('=');
		cookies.set(pair.slice(0, position), decodeURIComponent(pair.slice(position + 1)));
	}
	const client = createServerClient(env.PUBLIC_SUPABASE_URL, env.PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll: () => [...cookies].map(([name, value]) => ({ name, value })),
			setAll: (values) => values.forEach(({ name, value }) => cookies.set(name, value))
		}
	});
	const signed = await client.auth.signInWithPassword({ email, password });
	assert.ifError(signed.error);
	return {
		client,
		cookie: () =>
			[...cookies].map(([name, value]) => `${name}=${encodeURIComponent(value)}`).join('; ')
	};
}
async function request(actor, path, method = 'GET', body) {
	return fetch(`${origin}${path}`, {
		signal: AbortSignal.timeout(60_000),
		method,
		redirect: 'manual',
		headers: {
			Cookie: actor.cookie(),
			Origin: origin,
			Accept: 'application/json',
			'Content-Type': 'application/json'
		},
		body: body === undefined ? undefined : JSON.stringify(body)
	});
}
async function success(response, expected = 200) {
	const body = await response.json();
	assert.equal(response.status, expected, body.message ?? 'Estado HTTP inesperado');
	return body;
}
async function snapshot() {
	const works = await admin
		.from('obras')
		.select('obra_id,editor_asignado')
		.in('obra_id', fixtures.works);
	const reviewers = await admin
		.from('obras_revisores')
		.select('obra_id,revisor_id')
		.in('obra_id', fixtures.works);
	assert.ifError(works.error);
	assert.ifError(reviewers.error);
	return works.data.map((work) => ({
		...work,
		reviewer_ids: reviewers.data
			.filter((row) => row.obra_id === work.obra_id)
			.map((row) => row.revisor_id)
			.sort()
	}));
}
try {
	const roles = await admin
		.from('vocabularios')
		.select('termino_id,termino')
		.eq('categoria', 'role_editor');
	assert.ifError(roles.error);
	const email = `editor-manager-${suffix}@example.invalid`;
	const manager = await admin.auth.admin.createUser({ email, password, email_confirm: true });
	assert.ifError(manager.error);
	fixtures.users.push(manager.data.user.id);
	const inserted = await admin
		.from('editores')
		.insert({
			user_id: manager.data.user.id,
			nombre_completo: prefix,
			email,
			role: roles.data.find((role) => role.termino === 'admin').termino_id,
			activo: true
		});
	assert.ifError(inserted.error);
	const actor = await session(email);
	managerClient = actor.client;
	const editorEmail = `editor-new-${suffix}@example.invalid`;
	const profile = {
		nombre_completo: prefix + ' editor',
		email: editorEmail,
		institucion: 'Pruebas temporales',
		orcid: ''
	};
	const created = await success(await request(actor, '/api/editores', 'POST', profile), 201);
	console.log('Alta sin correo verificada.');
	const editorId = created.editor.user_id;
	fixtures.users.push(editorId);
	const account = await admin.auth.admin.getUserById(editorId);
	assert.ifError(account.error);
	assert.ok(
		!account.data.user.invited_at &&
			!account.data.user.email_confirmed_at &&
			!account.data.user.confirmation_sent_at &&
			!account.data.user.last_sign_in_at,
		'El alta no debe enviar correo ni activar la cuenta'
	);
	assert.equal(
		(await request(actor, '/api/editores', 'POST', profile)).status,
		409,
		'Correo duplicado'
	);
	const createdWorks = await success(
		await request(actor, '/api/obras/lote', 'POST', {
			titles: [prefix + ' uno', prefix + ' dos'],
			editor_asignado: editorId
		}),
		201
	);
	fixtures.works.push(...createdWorks.obras.map((work) => work.obra_id));
	assert.equal(createdWorks.obras.length, 2);
	assert.ok(createdWorks.obras.every((work) => work.editor_asignado === editorId));
	for (const path of [
		'/dashboard/editores',
		`/dashboard/editores/${editorId}`,
		'/dashboard/obras?scope=all'
	]) {
		const response = await request(actor, path);
		const html = await response.text();
		assert.equal(response.status, 200, `Render SSR de ${path}`);
		assert.ok(html.includes(prefix), `La pantalla ${path} no contiene los fixtures`);
	}
	console.log('Creación de obras y pantallas SSR verificadas.');
	const before = await snapshot();
	await success(
		await request(actor, '/api/obras/asignaciones-lote', 'POST', {
			operation: 'add_reviewer',
			target: manager.data.user.id,
			works: before
		})
	);
	await success(
		await request(actor, '/api/obras/asignaciones-lote', 'POST', {
			operation: 'editor',
			target: manager.data.user.id,
			works: await snapshot()
		})
	);
	const after = await snapshot();
	assert.ok(
		after.every(
			(work) => work.editor_asignado === manager.data.user.id && work.reviewer_ids.length === 0
		)
	);
	assert.equal(
		(
			await request(actor, '/api/obras/asignaciones-lote', 'POST', {
				operation: 'editor',
				target: editorId,
				works: before
			})
		).status,
		409
	);
	console.log('Reasignación y conflicto inmediato verificados.');
	await success(
		await request(actor, '/api/obras/asignaciones-lote', 'POST', {
			operation: 'editor',
			target: editorId,
			works: after
		})
	);

	// Simula la aceptación sin correo: no llama a inviteUserByEmail ni al SMTP.
	assert.ifError(
		(await admin.auth.admin.updateUserById(editorId, { password, email_confirm: true })).error
	);
	const editor = await session(editorEmail);
	editorClient = editor.client;
	assert.equal((await request(editor, '/api/editores', 'POST', profile)).status, 403);
	assert.equal((await request(editor, '/dashboard/editores')).status, 403);
	assert.equal(
		(await request(actor, `/api/editores/${editorId}/invitar`, 'POST')).status,
		409,
		'No se invita una cuenta activada'
	);
	await success(
		await request(actor, `/api/editores/${editorId}`, 'PATCH', {
			nombre_completo: profile.nombre_completo,
			institucion: profile.institucion,
			orcid: '',
			activo: false
		})
	);
	assert.equal((await request(editor, '/api/editores', 'POST', profile)).status, 403);
	const disabled = await request(editor, '/auth/pendiente');
	assert.equal(disabled.status, 200);
	assert.ok((await disabled.text()).includes('ACCESO DESHABILITADO'));
	console.log(
		'HTTP verificado: alta sin correo, duplicados, creación de obras, pantallas SSR, reparto, conflictos, permisos y deshabilitación.'
	);
} finally {
	await editorClient?.auth.signOut();
	await managerClient?.auth.signOut();
	// Solo los UUID devueltos por las altas de esta ejecución.
	if (fixtures.works.length)
		assert.ifError((await admin.from('obras').delete().in('obra_id', fixtures.works)).error);
	for (const id of [...fixtures.users].reverse())
		assert.ifError((await admin.auth.admin.deleteUser(id)).error);
	console.log('Cuentas y obras temporales eliminadas. No se ha enviado ningún correo.');
}
