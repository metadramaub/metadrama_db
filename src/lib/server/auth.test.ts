import { describe, expect, it } from 'vitest';
import { buildObraCapabilities } from './auth';
import type { EditorProfile } from '$lib/types/obra.types';

const baseProfile = {
	nombreCompleto: 'Test User',
	roleId: '00000000-0000-0000-0000-000000000000',
	activo: true
} as const;

function profile(roleTerm: string, userId = '00000000-0000-0000-0000-000000000001'): EditorProfile {
	return {
		...baseProfile,
		userId,
		roleTerm
	};
}

describe('buildObraCapabilities', () => {
	it('enables canDeleteObra for admin/ip', () => {
		const obra = { editor_asignado: '00000000-0000-0000-0000-000000000010' };
		expect(buildObraCapabilities(profile('admin'), obra, 'borrador', false).canDeleteObra).toBe(true);
		expect(buildObraCapabilities(profile('ip'), obra, 'borrador', false).canDeleteObra).toBe(true);
	});

	it('disables canDeleteObra for editor/reviewer scopes', () => {
		const editorId = '00000000-0000-0000-0000-000000000020';
		const obraAssigned = { editor_asignado: editorId };
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000030' };

		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false).canDeleteObra).toBe(false);
		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'borrador', true).canDeleteObra).toBe(false);
	});

	it('allows owner editor to change state only in the preview workflow', () => {
		const editorId = '00000000-0000-0000-0000-000000000040';
		const obraAssigned = { editor_asignado: editorId };

		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false).canChangeState).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'vista_previa', false).canChangeState).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'listo_para_publicar', false).canChangeState).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'publicado', false).canChangeState).toBe(false);
	});

	it('keeps assigned reviewers in read/comment-only workflow', () => {
		const editorId = '00000000-0000-0000-0000-000000000050';
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000060' };

		const vistaPreviaCaps = buildObraCapabilities(
			profile('editor', editorId),
			obraUnassigned,
			'vista_previa',
			true
		);
		const listoCaps = buildObraCapabilities(
			profile('editor', editorId),
			obraUnassigned,
			'listo_para_publicar',
			true
		);

		expect(vistaPreviaCaps.canRead).toBe(true);
		expect(vistaPreviaCaps.canChangeState).toBe(false);
		expect(vistaPreviaCaps.canEditContent).toBe(false);
		expect(listoCaps.canChangeState).toBe(false);
	});

	it('allows unassigned editors to read only published works', () => {
		const editorId = '00000000-0000-0000-0000-000000000070';
		const obraAssigned = { editor_asignado: editorId };
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000080' };

		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'publicado', false).canRead).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'borrador', false).canRead).toBe(false);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false).canRead).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'vista_previa', true).canRead).toBe(true);
	});

	it('flags public preview only for assigned editor or admin/ip in preview states', () => {
		const editorId = '00000000-0000-0000-0000-000000000090';
		const obraAssigned = { editor_asignado: editorId };
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000091' };

		expect(
			buildObraCapabilities(profile('editor', editorId), obraAssigned, 'vista_previa', false)
				.canPreviewPublicFicha
		).toBe(true);
		expect(
			buildObraCapabilities(profile('editor', editorId), obraAssigned, 'listo_para_publicar', false)
				.canPreviewPublicFicha
		).toBe(true);
		expect(
			buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false)
				.canPreviewPublicFicha
		).toBe(false);
		expect(
			buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'vista_previa', false)
				.canPreviewPublicFicha
		).toBe(false);
		expect(buildObraCapabilities(profile('admin'), obraUnassigned, 'vista_previa', false).canPreviewPublicFicha).toBe(true);
	});
});
