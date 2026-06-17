import { describe, expect, it } from 'vitest';
import {
	canTransitionState,
	hasStateTransitionFrom,
	canReadAllObras,
	canEditByState,
	canToggleVisibility,
	canDeleteObras,
	canManageReviewAssignments,
	canManageVocabularios,
	canManageAutores,
	canManageAutoriaMetricProfile,
	canDeleteAutores,
	isProtectedVocabularyCategory,
	normalizeRole
} from './permissions';

describe('permissions', () => {
	it('normalizes role names', () => {
		expect(normalizeRole('IP')).toBe('ip');
		expect(normalizeRole(' admin ')).toBe('admin');
		expect(normalizeRole('revisor')).toBe('editor');
	});

	it('validates read access scope', () => {
		expect(canReadAllObras('admin')).toBe(true);
		expect(canReadAllObras('ip')).toBe(true);
		expect(canReadAllObras('revisor')).toBe(false);
		expect(canReadAllObras('editor')).toBe(false);
	});

	it('enforces editor state transitions', () => {
		expect(
			canTransitionState('editor', 'borrador', 'pendiente', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'pendiente', 'borrador', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'pendiente', 'validado', { assignedEditor: true })
		).toBe(false);
		expect(canTransitionState('editor', 'pendiente', 'borrador')).toBe(false);
	});

	it('enforces reviewer editor state transitions', () => {
		expect(
			canTransitionState('editor', 'pendiente', 'en_revision', { assignedReviewer: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'en_revision', 'validado', { assignedReviewer: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'pendiente', 'borrador', { assignedReviewer: true })
		).toBe(false);
		expect(
			canTransitionState('editor', 'en_revision', 'borrador', { assignedReviewer: true })
		).toBe(false);
	});

	it('detects if there are transitions available from current state', () => {
		expect(hasStateTransitionFrom('editor', 'pendiente', { assignedEditor: true })).toBe(true);
		expect(hasStateTransitionFrom('editor', 'pendiente', { assignedReviewer: true })).toBe(true);
		expect(hasStateTransitionFrom('editor', 'validado', { assignedReviewer: true })).toBe(false);
	});

	it('allows admin/ip to transition any state', () => {
		expect(canTransitionState('admin', 'borrador', 'publicado')).toBe(true);
		expect(canTransitionState('ip', 'en_revision', 'borrador')).toBe(true);
	});

	it('enforces editable states for editor', () => {
		expect(canEditByState('editor', 'borrador')).toBe(true);
		expect(canEditByState('editor', 'pendiente')).toBe(true);
		expect(canEditByState('editor', 'validado')).toBe(false);
	});

	it('limits visibility toggle to admin/IP', () => {
		expect(canToggleVisibility('admin')).toBe(true);
		expect(canToggleVisibility('ip')).toBe(true);
		expect(canToggleVisibility('editor')).toBe(false);
		expect(canToggleVisibility('revisor')).toBe(false);
	});

	it('limits obra deletion to admin/IP', () => {
		expect(canDeleteObras('admin')).toBe(true);
		expect(canDeleteObras('ip')).toBe(true);
		expect(canDeleteObras('editor')).toBe(false);
		expect(canDeleteObras('revisor')).toBe(false);
	});

	it('limits management actions to admin/IP', () => {
		expect(canManageReviewAssignments('admin')).toBe(true);
		expect(canManageReviewAssignments('ip')).toBe(true);
		expect(canManageReviewAssignments('editor')).toBe(false);

		expect(canManageVocabularios('admin')).toBe(true);
		expect(canManageVocabularios('revisor')).toBe(false);
		expect(canManageAutores('admin')).toBe(true);
		expect(canManageAutores('ip')).toBe(true);
		expect(canManageAutores('editor')).toBe(false);
		expect(canManageAutoriaMetricProfile('admin')).toBe(true);
		expect(canManageAutoriaMetricProfile('ip')).toBe(true);
		expect(canManageAutoriaMetricProfile('editor')).toBe(false);
		expect(canDeleteAutores('admin')).toBe(true);
		expect(canDeleteAutores('ip')).toBe(true);
		expect(canDeleteAutores('editor')).toBe(false);
	});

	it('protects immutable vocabulary categories', () => {
		expect(isProtectedVocabularyCategory('estado')).toBe(true);
		expect(isProtectedVocabularyCategory('role_editor')).toBe(true);
		expect(isProtectedVocabularyCategory('estado_revision')).toBe(false);
		expect(isProtectedVocabularyCategory('genero')).toBe(false);
	});
});
