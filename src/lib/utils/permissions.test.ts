import { describe, expect, it } from 'vitest';
import {
	canTransitionState,
	hasStateTransitionFrom,
	canReadAllObras,
	canEditByState,
	canToggleVisibility,
	canPreviewPublicFicha,
	canDeleteObras,
	canManageReviewAssignments,
	canManageVocabularios,
	canCreateAutores,
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
			canTransitionState('editor', 'borrador', 'vista_previa', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'vista_previa', 'borrador', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'vista_previa', 'listo_para_publicar', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'listo_para_publicar', 'borrador', { assignedEditor: true })
		).toBe(true);
		expect(
			canTransitionState('editor', 'listo_para_publicar', 'publicado', { assignedEditor: true })
		).toBe(false);
		expect(canTransitionState('editor', 'vista_previa', 'borrador')).toBe(false);
	});

	it('does not give assigned reviewers state transitions', () => {
		expect(
			canTransitionState('editor', 'vista_previa', 'listo_para_publicar', { assignedReviewer: true })
		).toBe(false);
		expect(
			canTransitionState('editor', 'vista_previa', 'borrador', { assignedReviewer: true })
		).toBe(false);
	});

	it('detects if there are transitions available from current state', () => {
		expect(hasStateTransitionFrom('editor', 'vista_previa', { assignedEditor: true })).toBe(true);
		expect(hasStateTransitionFrom('editor', 'vista_previa', { assignedReviewer: true })).toBe(false);
		expect(hasStateTransitionFrom('editor', 'publicado', { assignedEditor: true })).toBe(false);
	});

	it('allows admin/ip to transition any state', () => {
		expect(canTransitionState('admin', 'borrador', 'publicado')).toBe(true);
		expect(canTransitionState('ip', 'listo_para_publicar', 'borrador')).toBe(true);
	});

	it('enforces editable states for editor', () => {
		expect(canEditByState('editor', 'borrador')).toBe(true);
		expect(canEditByState('editor', 'vista_previa')).toBe(false);
		expect(canEditByState('editor', 'listo_para_publicar')).toBe(false);
	});

	it('allows public ficha preview only for admin/ip or assigned editor', () => {
		expect(canPreviewPublicFicha('admin', 'vista_previa')).toBe(true);
		expect(canPreviewPublicFicha('ip', 'listo_para_publicar')).toBe(true);
		expect(canPreviewPublicFicha('editor', 'vista_previa', { assignedEditor: true })).toBe(true);
		expect(canPreviewPublicFicha('editor', 'vista_previa', { assignedReviewer: true })).toBe(false);
		expect(canPreviewPublicFicha('editor', 'borrador', { assignedEditor: true })).toBe(false);
		expect(canPreviewPublicFicha('editor', 'publicado', { assignedEditor: true })).toBe(false);
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
		expect(canCreateAutores('admin')).toBe(true);
		expect(canCreateAutores('ip')).toBe(true);
		expect(canCreateAutores('editor')).toBe(true);
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
