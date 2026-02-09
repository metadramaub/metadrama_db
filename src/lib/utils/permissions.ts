export type EditorRole = 'editor' | 'revisor' | 'admin' | 'ip' | string;

const workflowEditor = new Set(['borrador:pendiente', 'pendiente:borrador']);
const workflowRevisor = new Set([
	'pendiente:en_revision',
	'en_revision:pendiente',
	'en_revision:validado',
	'validado:en_revision'
]);

export function normalizeRole(rawRole: string | null | undefined): EditorRole {
	if (!rawRole) {
		return 'editor';
	}
	const normalized = rawRole.trim().toLowerCase();
	if (normalized === 'ip') {
		return 'ip';
	}
	if (normalized === 'editor' || normalized === 'revisor' || normalized === 'admin') {
		return normalized;
	}
	return normalized;
}

export function canReadAllObras(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip' || role === 'revisor';
}

export function canEditAssignedContent(role: EditorRole): boolean {
	return role === 'editor' || role === 'admin' || role === 'ip';
}

export function canToggleVisibility(role: EditorRole): boolean {
	return role === 'admin' || role === 'ip';
}

export function canTransitionState(role: EditorRole, from: string, to: string): boolean {
	const fromTerm = from.trim().toLowerCase();
	const toTerm = to.trim().toLowerCase();
	if (fromTerm === toTerm) {
		return true;
	}
	const key = `${fromTerm}:${toTerm}`;
	if (role === 'admin' || role === 'ip') {
		return true;
	}
	if (role === 'editor') {
		return workflowEditor.has(key);
	}
	if (role === 'revisor') {
		return workflowRevisor.has(key);
	}
	return false;
}

export function canEditByState(role: EditorRole, estado: string): boolean {
	const current = estado.trim().toLowerCase();
	if (role === 'admin' || role === 'ip') {
		return true;
	}
	if (role === 'editor') {
		return current === 'borrador' || current === 'pendiente';
	}
	return false;
}
