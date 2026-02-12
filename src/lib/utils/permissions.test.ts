import { describe, expect, it } from 'vitest';
import {
	canTransitionState,
	canTransitionReviewerWorkflow,
	canReadAllObras,
	canEditByState,
	canToggleVisibility,
	canDeleteObras,
	canManageReviewAssignments,
	canManageVocabularios,
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
		expect(canTransitionState('editor', 'borrador', 'pendiente')).toBe(true);
		expect(canTransitionState('editor', 'pendiente', 'borrador')).toBe(true);
		expect(canTransitionState('editor', 'pendiente', 'validado')).toBe(false);
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

	it('supports reviewer workflow helper for assigned reviewers', () => {
		expect(canTransitionReviewerWorkflow('pendiente', 'en_revision')).toBe(true);
		expect(canTransitionReviewerWorkflow('en_revision', 'validado')).toBe(true);
		expect(canTransitionReviewerWorkflow('validado', 'publicado')).toBe(false);
	});

	it('limits management actions to admin/IP', () => {
		expect(canManageReviewAssignments('admin')).toBe(true);
		expect(canManageReviewAssignments('ip')).toBe(true);
		expect(canManageReviewAssignments('editor')).toBe(false);

		expect(canManageVocabularios('admin')).toBe(true);
		expect(canManageVocabularios('revisor')).toBe(false);
	});

	it('protects immutable vocabulary categories', () => {
		expect(isProtectedVocabularyCategory('estado')).toBe(true);
		expect(isProtectedVocabularyCategory('role_editor')).toBe(true);
		expect(isProtectedVocabularyCategory('genero')).toBe(false);
	});
});
