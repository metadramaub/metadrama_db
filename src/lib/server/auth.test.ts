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

	it('allows owner editor to change state only in borrador/pendiente workflow', () => {
		const editorId = '00000000-0000-0000-0000-000000000040';
		const obraAssigned = { editor_asignado: editorId };

		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false).canChangeState).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'pendiente', false).canChangeState).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'validado', false).canChangeState).toBe(false);
	});

	it('allows assigned reviewer to change state only in pendiente/en_revision workflow', () => {
		const editorId = '00000000-0000-0000-0000-000000000050';
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000060' };

		const pendienteCaps = buildObraCapabilities(
			profile('editor', editorId),
			obraUnassigned,
			'pendiente',
			true
		);
		const enRevisionCaps = buildObraCapabilities(
			profile('editor', editorId),
			obraUnassigned,
			'en_revision',
			true
		);
		const validadoCaps = buildObraCapabilities(
			profile('editor', editorId),
			obraUnassigned,
			'validado',
			true
		);

		expect(pendienteCaps.canChangeState).toBe(true);
		expect(enRevisionCaps.canChangeState).toBe(true);
		expect(validadoCaps.canChangeState).toBe(false);
		expect(pendienteCaps.canEditContent).toBe(false);
	});

	it('allows unassigned editors to read only published works', () => {
		const editorId = '00000000-0000-0000-0000-000000000070';
		const obraAssigned = { editor_asignado: editorId };
		const obraUnassigned = { editor_asignado: '00000000-0000-0000-0000-000000000080' };

		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'publicado', false).canRead).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'borrador', false).canRead).toBe(false);
		expect(buildObraCapabilities(profile('editor', editorId), obraAssigned, 'borrador', false).canRead).toBe(true);
		expect(buildObraCapabilities(profile('editor', editorId), obraUnassigned, 'pendiente', true).canRead).toBe(true);
	});
});
