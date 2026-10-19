import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { editorCreateSchema } from '$lib/utils/editor-management';
import { validationErrorResponse } from '$lib/server/http';

export const POST: RequestHandler = async ({ locals, request }) => {
	await requireEditorManager(locals);
	const parsed = editorCreateSchema.safeParse(await request.json().catch(() => null));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const admin = getSupabaseAdmin();
	const roles = await loadInternalVocabulario(locals.supabase, ['role_editor']);
	const role = roles.find((row) => row.termino.toLowerCase() === 'editor');
	if (!role) throw error(500, 'No se encuentra el rol de editor.');
	// Sin contraseña y sin confirmar el correo: inviteUserByEmail podrá invitar esta misma cuenta.
	const created = await admin.auth.admin.createUser({
		email: parsed.data.email,
		email_confirm: false
	});
	if (created.error) {
		return json(
			{
				message:
					created.error.code === 'email_exists' || created.error.code === 'email_already_exists'
						? 'Ya existe una cuenta con ese correo. Revisa el listado de editores antes de continuar.'
						: 'No se pudo crear la cuenta de acceso. Comprueba si el correo ya está registrado.'
			},
			{ status: 409 }
		);
	}
	const inserted = await admin
		.from('editores')
		.insert({
			...parsed.data,
			user_id: created.data.user.id,
			role: role.termino_id,
			activo: true
		})
		.select('user_id')
		.single();
	if (inserted.error) {
		// Compensación: nunca dejar una cuenta nueva sin perfil tras un fallo de la segunda escritura.
		const cleanup = await admin.auth.admin.deleteUser(created.data.user.id);
		if (cleanup.error) {
			console.error('Alta incompleta de editor', {
				userId: created.data.user.id,
				code: cleanup.error.code
			});
			throw error(
				500,
				'La cuenta se creó, pero falló su perfil y no se pudo retirar. Hay que completar el perfil desde Supabase antes de reintentar.'
			);
		}
		throw error(
			500,
			'No se pudo guardar el perfil. El alta se ha cancelado y no se ha enviado ningún correo.'
		);
	}
	return json({ editor: inserted.data }, { status: 201 });
};
