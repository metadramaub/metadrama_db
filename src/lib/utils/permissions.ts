export type EditorRole = 'editor' | 'admin' | 'ip' | string;

export type StateTransitionContext = {
	assignedEditor?: boolean;
	assignedReviewer?: boolean;
};

const workflowEditorOwner = new Set([
	'borrador:vista_previa',
	'vista_previa:borrador',
	'vista_previa:listo_para_publicar',
	'listo_para_publicar:borrador'
]);
const workflowEditorReviewer = new Set<string>();
const emptyWorkflow = new Set<string>();
const protectedVocabularyCategories = new Set(['role_editor', 'estado']);

function normalizeStateTerm(term: string): string {
	return term.trim().toLowerCase();
}

function getEditorWorkflow(context: StateTransitionContext): Set<string> {
	if (context.assignedEditor) return workflowEditorOwner;
	if (context.assignedReviewer) return workflowEditorReviewer;
	return emptyWorkflow;
}

export function normalizeRole(rawRole: string | null | undefined): EditorRole {
	if (!rawRole) {
		return 'editor';
	}
	const normalized = rawRole.trim().toLowerCase();
	if (normalized === 'ip') {
		return 'ip';
	}
	if (normalized === 'revisor') {
		return 'editor';
	}
	if (normalized === 'editor' || normalized === 'admin') {
		return normalized;
	}
	return normalized;
}

export function canReadAllObras(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canEditAssignedContent(role: EditorRole): boolean {
	return role === 'editor' || role === 'admin' || role === 'ip';
}

export function canToggleVisibility(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canDeleteObras(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canTransitionState(
	role: EditorRole,
	from: string,
	to: string,
	context: StateTransitionContext = {}
): boolean {
	const fromTerm = normalizeStateTerm(from);
	const toTerm = normalizeStateTerm(to);
	if (fromTerm === toTerm) {
		return true;
	}
	if (role === 'admin' || role === 'ip') {
		return true;
	}
	if (role !== 'editor') return false;
	const key = `${fromTerm}:${toTerm}`;
	return getEditorWorkflow(context).has(key);
}

export function hasStateTransitionFrom(
	role: EditorRole,
	from: string,
	context: StateTransitionContext = {}
): boolean {
	if (role === 'admin' || role === 'ip') return true;
	if (role !== 'editor') return false;
	const fromTerm = normalizeStateTerm(from);
	const prefix = `${fromTerm}:`;
	for (const key of getEditorWorkflow(context)) {
		if (key.startsWith(prefix)) {
			return true;
		}
	}
	return false;
}

export function canEditByState(role: EditorRole, estado: string): boolean {
	const current = estado.trim().toLowerCase();
	if (role === 'admin' || role === 'ip') {
		return true;
	}
	if (role === 'editor') {
		return current === 'borrador';
	}
	return false;
}

export function canPreviewPublicFicha(
	role: EditorRole,
	estado: string,
	context: StateTransitionContext = {}
): boolean {
	const current = estado.trim().toLowerCase();
	if (current !== 'vista_previa' && current !== 'listo_para_publicar') {
		return false;
	}
	if (role === 'admin' || role === 'ip') {
		return true;
	}
	return role === 'editor' && Boolean(context.assignedEditor);
}

export function canManageReviewAssignments(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canManageVocabularios(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canManagePublicacion(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canCreateAutores(role: EditorRole): boolean {
	return role === 'editor' || role === 'admin' || role === 'ip';
}

export function canManageAutores(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canManageAutoriaMetricProfile(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canDeleteAutores(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function isProtectedVocabularyCategory(category: string): boolean {
	return protectedVocabularyCategories.has(category.trim().toLowerCase());
}
