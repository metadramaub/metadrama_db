import { describe, expect, it } from 'vitest';
import {
	canViewPublishedObra,
	resolveObraScope,
	type PublicObraVisibility,
	type PublicViewerContext
} from './public-obras';

const EDITOR_ID = '00000000-0000-0000-0000-0000000000aa';
const OTHER_EDITOR_ID = '00000000-0000-0000-0000-0000000000bb';

function viewer(
	scope: PublicViewerContext['scope'],
	userId: string | null = null
): PublicViewerContext {
	return {
		scope,
		userId,
		roleTerm: scope === 'admin_ip' ? 'admin' : scope === 'authenticated' ? 'editor' : null,
		canSeeAllPublished: scope === 'admin_ip'
	};
}

function obra(
	overrides: Partial<PublicObraVisibility> = {}
): PublicObraVisibility {
	return {
		editor_asignado: null,
		visible_publico: false,
		...overrides
	};
}

describe('resolveObraScope', () => {
	it('admin/IP siempre resuelve admin_ip', () => {
		expect(resolveObraScope(viewer('admin_ip', EDITOR_ID), obra())).toBe('admin_ip');
		expect(
			resolveObraScope(viewer('admin_ip', EDITOR_ID), obra({ editor_asignado: OTHER_EDITOR_ID }))
		).toBe('admin_ip');
	});

	it('el editor asignado a SU obra la ve como admin_ip', () => {
		expect(
			resolveObraScope(viewer('authenticated', EDITOR_ID), obra({ editor_asignado: EDITOR_ID }))
		).toBe('admin_ip');
	});

	it('el editor en obra ajena conserva su scope base', () => {
		expect(
			resolveObraScope(
				viewer('authenticated', EDITOR_ID),
				obra({ editor_asignado: OTHER_EDITOR_ID })
			)
		).toBe('authenticated');
	});

	it('logueado sin asignación conserva authenticated', () => {
		expect(resolveObraScope(viewer('authenticated', EDITOR_ID), obra())).toBe('authenticated');
	});

	it('anónimo conserva anon aunque editor_asignado coincida con null', () => {
		expect(resolveObraScope(viewer('anon', null), obra())).toBe('anon');
	});
});

describe('canViewPublishedObra (obra ya publicada)', () => {
	it('obra visible: la ve cualquiera', () => {
		const visible = obra({ visible_publico: true });
		expect(canViewPublishedObra(viewer('anon', null), visible)).toBe(true);
		expect(canViewPublishedObra(viewer('authenticated', EDITOR_ID), visible)).toBe(true);
		expect(canViewPublishedObra(viewer('admin_ip', EDITOR_ID), visible)).toBe(true);
	});

	it('obra publicada NO visible: solo admin/IP y editor asignado', () => {
		const oculta = obra({ visible_publico: false, editor_asignado: EDITOR_ID });

		// anónimo: no
		expect(canViewPublishedObra(viewer('anon', null), oculta)).toBe(false);
		// editor asignado: sí
		expect(canViewPublishedObra(viewer('authenticated', EDITOR_ID), oculta)).toBe(true);
		// editor en obra ajena: no
		expect(
			canViewPublishedObra(
				viewer('authenticated', OTHER_EDITOR_ID),
				obra({ visible_publico: false, editor_asignado: EDITOR_ID })
			)
		).toBe(false);
		// admin/IP: sí
		expect(canViewPublishedObra(viewer('admin_ip', OTHER_EDITOR_ID), oculta)).toBe(true);
	});

	it('visible_publico null se trata como no visible', () => {
		const sinDato = obra({ visible_publico: null, editor_asignado: null });
		expect(canViewPublishedObra(viewer('anon', null), sinDato)).toBe(false);
		expect(canViewPublishedObra(viewer('admin_ip', null), sinDato)).toBe(true);
	});
});
