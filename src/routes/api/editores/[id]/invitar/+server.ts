import { error, json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';

export const POST: RequestHandler = async ({ locals, params, url }) => {
	await requireEditorManager(locals);
	if (!z.string().uuid().safeParse(params.id).success) throw error(404, 'Editor no encontrado.');
	const admin = getSupabaseAdmin();
	const editor = await admin
		.from('editores')
		.select('user_id,email,activo')
		.eq('user_id', params.id)
		.maybeSingle();
	if (editor.error) throw error(500, 'No se pudo consultar el editor.');
	if (!editor.data) throw error(404, 'Editor no encontrado.');
	if (editor.data.activo === false)
		throw error(422, 'Habilita al editor antes de enviarle una invitación.');
	const account = await admin.auth.admin.getUserById(params.id);
	if (account.error || !account.data.user)
		throw error(502, 'No se pudo comprobar la cuenta de acceso.');
	if (account.data.user.email?.toLowerCase() !== editor.data.email.toLowerCase()) {
		throw error(
			409,
			'El correo del perfil no coincide con la cuenta de acceso. Corrígelo en Supabase antes de invitar.'
		);
	}
	if (account.data.user.email_confirmed_at || account.data.user.last_sign_in_at) {
		throw error(
			409,
			'Esta cuenta ya ha activado su acceso. La invitación solo se utiliza para el primer acceso.'
		);
	}
	const invited = await admin.auth.admin.inviteUserByEmail(editor.data.email, {
		redirectTo: new URL('/auth/callback?type=invite', url.origin).href
	});
	if (invited.error) {
		throw error(
			invited.error.status === 429 ? 429 : 502,
			'No se pudo enviar la invitación. El perfil y sus obras siguen preparados; puedes reintentar el envío.'
		);
	}
	return json({ message: 'Invitación enviada.', invitedAt: invited.data.user?.invited_at });
};
