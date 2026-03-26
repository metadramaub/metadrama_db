import { error, type RequestEvent } from '@sveltejs/kit';
import type { Tables } from '$lib/types/database.types';
import {
	canEditByState,
	canDeleteObras,
	hasStateTransitionFrom,
	canManageReviewAssignments,
	canToggleVisibility,
	normalizeRole
} from '$lib/utils/permissions';
import type { EditorProfile, ObraAccessFlags } from '$lib/types/obra.types';
import { getEstadoTerm, getObraOrFail } from '$lib/server/obras';

type EventWithLocals = Pick<RequestEvent, 'locals'>;

type ObraContextOptions = {
	requireEdit?: boolean;
	requireComment?: boolean;
	requireChangeState?: boolean;
	requireManageReviewers?: boolean;
	requireToggleVisibility?: boolean;
	requireDelete?: boolean;
	// Backward compatibility for existing handlers while refactoring.
	requireAssignment?: boolean;
};

export async function requireAuthenticated(event: EventWithLocals) {
	const { user } = await event.locals.safeGetSession();
	if (!user) {
		throw error(401, 'Sesion invalida o expirada');
	}
	return user;
}

export async function getEditorProfile(event: EventWithLocals, userId: string): Promise<EditorProfile> {
	const profile = await findEditorProfile(event, userId);
	if (!profile) {
		throw error(403, 'No existe perfil de editor para este usuario');
	}
	return profile;
}

export async function findEditorProfile(
	event: EventWithLocals,
	userId: string
): Promise<EditorProfile | null> {
	const { data: editor, error: editorError } = await event.locals.supabase
		.from('editores')
		.select('user_id,nombre_completo,role,activo')
		.eq('user_id', userId)
		.maybeSingle();

	if (editorError) {
		throw error(500, 'No se pudo cargar el perfil de editor');
	}

	if (!editor) {
		return null;
	}

	const { data: role, error: roleError } = await event.locals.supabase
		.from('vocabularios')
		.select('termino')
		.eq('termino_id', editor.role)
		.single();

	if (roleError) {
		throw error(500, 'No se pudo cargar el rol del editor');
	}

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
		throw error(403, 'Tu usuario esta desactivado');
	}
	return profile;
}

function isAdminOrIp(roleTerm: string): boolean {
	return roleTerm === 'admin' || roleTerm === 'ip';
}

export function canUseCustomAutoriaRanges(roleTerm: string): boolean {
	return roleTerm === 'admin';
}

export function buildObraCapabilities(
	profile: EditorProfile,
	obra: Pick<Tables<'obras'>, 'editor_asignado'>,
	estadoTerm: string,
	assignedReviewer: boolean
): ObraAccessFlags {
	const adminOrIp = isAdminOrIp(profile.roleTerm);
	const assignedEditor = obra.editor_asignado === profile.userId;
	const isPublished = estadoTerm.trim().toLowerCase() === 'publicado';

	// Admin/IP: full control for every work.
	if (adminOrIp) {
		return {
			canRead: true,
			canEditContent: true,
			canComment: true,
			canReview: true,
			canChangeState: true,
			canManageReviewers: canManageReviewAssignments(profile.roleTerm),
			canToggleVisibility: canToggleVisibility(profile.roleTerm),
			canDeleteObra: canDeleteObras(profile.roleTerm)
		};
	}

	// Owner editor: content edition + editor workflow.
	if (profile.roleTerm === 'editor' && assignedEditor) {
		const canEditInCurrentState = canEditByState(profile.roleTerm, estadoTerm);
		const canChangeStateInCurrentState = hasStateTransitionFrom(profile.roleTerm, estadoTerm, {
			assignedEditor: true,
			assignedReviewer: false
		});
		return {
			canRead: true,
			canEditContent: canEditInCurrentState,
			canComment: true,
			canReview: true,
			canChangeState: canChangeStateInCurrentState,
			canManageReviewers: false,
			canToggleVisibility: false,
			canDeleteObra: false
		};
	}

	// Assigned reviewer (including users with role "editor"): review only.
	if (assignedReviewer) {
		const canChangeStateInCurrentState = hasStateTransitionFrom(profile.roleTerm, estadoTerm, {
			assignedEditor: false,
			assignedReviewer: true
		});
		return {
			canRead: true,
			canEditContent: false,
			canComment: true,
			canReview: true,
			canChangeState: canChangeStateInCurrentState,
			canManageReviewers: false,
			canToggleVisibility: false,
			canDeleteObra: false
		};
	}

	// Unassigned editors can only read published works.
	if (profile.roleTerm === 'editor') {
		return {
			canRead: isPublished,
			canEditContent: false,
			canComment: false,
			canReview: false,
			canChangeState: false,
			canManageReviewers: false,
			canToggleVisibility: false,
			canDeleteObra: false
		};
	}

	// Any other active internal user can read works, but no review/edit actions.
	return {
		canRead: true,
		canEditContent: false,
		canComment: false,
		canReview: false,
		canChangeState: false,
		canManageReviewers: false,
		canToggleVisibility: false,
		canDeleteObra: false
	};
}

function assertCanRead(capabilities: ObraAccessFlags) {
	if (!capabilities.canRead) {
		throw error(403, 'No tienes acceso a esta obra');
	}
}

function assertCanEditContent(capabilities: ObraAccessFlags) {
	if (!capabilities.canEditContent) {
		throw error(403, 'No tienes permisos para editar el contenido de esta obra');
	}
}

function assertCanComment(capabilities: ObraAccessFlags) {
	if (!capabilities.canComment) {
		throw error(403, 'No tienes permisos para comentar en esta obra');
	}
}

function assertCanChangeState(capabilities: ObraAccessFlags) {
	if (!capabilities.canChangeState) {
		throw error(403, 'No tienes permisos para cambiar el estado de esta obra');
	}
}

function assertCanManageReviewers(capabilities: ObraAccessFlags) {
	if (!capabilities.canManageReviewers) {
		throw error(403, 'No tienes permisos para gestionar revisores');
	}
}

function assertCanToggleVisibility(capabilities: ObraAccessFlags) {
	if (!capabilities.canToggleVisibility) {
		throw error(403, 'No tienes permisos para cambiar la visibilidad');
	}
}

function assertCanDelete(capabilities: ObraAccessFlags) {
	if (!capabilities.canDeleteObra) {
		throw error(403, 'No tienes permisos para eliminar esta obra');
	}
}

export async function getObraContext(
	event: EventWithLocals,
	obraId: string,
	options: ObraContextOptions = {}
) {
	const profile = await requireEditorProfile(event);
	const obra = await getObraOrFail(event.locals.supabase, obraId);
	const estadoTerm = await getEstadoTerm(event.locals.supabase, obra.estado);
	const reviewerAssignResp = await event.locals.supabase
		.from('obras_revisores')
		.select('revisor_id')
		.eq('obra_id', obra.obra_id)
		.eq('revisor_id', profile.userId)
		.maybeSingle();
	const assignedReviewer = Boolean(reviewerAssignResp.data);
	const assignedEditor = obra.editor_asignado === profile.userId;
	const isAssigned = assignedEditor || assignedReviewer;
	const capabilities = buildObraCapabilities(profile, obra, estadoTerm, assignedReviewer);

	assertCanRead(capabilities);
	if (options.requireAssignment && !isAssigned && !isAdminOrIp(profile.roleTerm)) {
		throw error(403, 'Esta accion requiere que la obra este asignada');
	}
	if (options.requireEdit) {
		assertCanEditContent(capabilities);
	}
	if (options.requireComment) {
		assertCanComment(capabilities);
	}
	if (options.requireChangeState) {
		assertCanChangeState(capabilities);
	}
	if (options.requireManageReviewers) {
		assertCanManageReviewers(capabilities);
	}
	if (options.requireToggleVisibility) {
		assertCanToggleVisibility(capabilities);
	}
	if (options.requireDelete) {
		assertCanDelete(capabilities);
	}

	return {
		profile,
		obra,
		estadoTerm,
		assignedReviewer,
		assignedEditor,
		isAssigned,
		capabilities
	};
}
