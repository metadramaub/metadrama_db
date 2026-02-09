import { error, type RequestEvent } from '@sveltejs/kit';
import type { Tables } from '$lib/types/database.types';
import { canEditAssignedContent, canReadAllObras, normalizeRole } from '$lib/utils/permissions';
import type { EditorProfile } from '$lib/types/obra.types';
import { getEstadoTerm, getObraOrFail } from '$lib/server/obras';

type EventWithLocals = Pick<RequestEvent, 'locals'>;

export async function requireAuthenticated(event: EventWithLocals) {
	const { user } = await event.locals.safeGetSession();
	if (!user) {
		throw error(401, 'Sesión inválida o expirada');
	}
	return user;
}

export async function getEditorProfile(
	event: EventWithLocals,
	userId: string
): Promise<EditorProfile> {
	const { data: editor, error: editorError } = await event.locals.supabase
		.from('editores')
		.select('user_id,nombre_completo,role,activo')
		.eq('user_id', userId)
		.single();

	if (editorError || !editor) {
		throw error(403, 'No existe perfil de editor para este usuario');
	}

	const { data: role } = await event.locals.supabase
		.from('vocabularios')
		.select('termino')
		.eq('termino_id', editor.role)
		.single();

	return {
		userId: editor.user_id,
		nombreCompleto: editor.nombre_completo,
		roleId: editor.role,
		roleTerm: normalizeRole(role?.termino ?? 'editor'),
		activo: editor.activo ?? true
	};
}

export async function requireEditorProfile(event: EventWithLocals): Promise<EditorProfile> {
	const user = await requireAuthenticated(event);
	const profile = await getEditorProfile(event, user.id);
	if (!profile.activo) {
		throw error(403, 'Tu usuario está desactivado');
	}
	return profile;
}

export function assertReadAccess(
	profile: EditorProfile,
	obra: Pick<Tables<'obras'>, 'editor_asignado'>
) {
	if (canReadAllObras(profile.roleTerm)) {
		return;
	}
	if (obra.editor_asignado !== profile.userId) {
		throw error(403, 'No tienes acceso a esta obra');
	}
}

export function assertEditAccess(
	profile: EditorProfile,
	obra: Pick<Tables<'obras'>, 'editor_asignado' | 'estado'>,
	estadoTerm: string
) {
	if (profile.roleTerm === 'editor' && obra.editor_asignado !== profile.userId) {
		throw error(403, 'Solo puedes editar obras asignadas');
	}
	if (!canEditAssignedContent(profile.roleTerm)) {
		throw error(403, 'No tienes permisos de edición');
	}
	if (profile.roleTerm === 'editor' && !['borrador', 'pendiente'].includes(estadoTerm)) {
		throw error(403, 'No puedes editar obras en este estado');
	}
}

export async function getObraContext(
	event: EventWithLocals,
	obraId: string,
	options: { requireEdit?: boolean } = {}
) {
	const profile = await requireEditorProfile(event);
	const obra = await getObraOrFail(event.locals.supabase, obraId);
	const estadoTerm = await getEstadoTerm(event.locals.supabase, obra.estado);

	assertReadAccess(profile, obra);
	if (options.requireEdit) {
		assertEditAccess(profile, obra, estadoTerm);
	}

	return { profile, obra, estadoTerm };
}
