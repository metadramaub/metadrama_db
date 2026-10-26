import { beforeEach, describe, expect, it, vi } from 'vitest';
import { requireImportadorPreview } from './acceso';

const { perfil } = vi.hoisted(() => ({ perfil: vi.fn() }));
vi.mock('$lib/server/auth', () => ({ requireEditorProfile: perfil }));

beforeEach(() => {
	perfil.mockReset();
});

describe('acceso al ensayo del importador', () => {
	it.each(['admin', 'ip'])('admite un perfil activo %s', async (roleTerm) => {
		const editor = { roleTerm, activo: true };
		perfil.mockResolvedValue(editor);
		const event = { locals: {} } as never;
		expect(await requireImportadorPreview(event)).toBe(editor);
		expect(perfil).toHaveBeenCalledWith(event);
	});
	it('no concede el ensayo a un editor aunque declare una futura capacidad', async () => {
		perfil.mockResolvedValue({ roleTerm: 'editor', activo: true, puede_importar_metrica: true });
		await expect(requireImportadorPreview({ locals: {} } as never)).rejects.toMatchObject({
			status: 403
		});
	});
	it.each([401, 403])(
		'propaga la denegación %s del helper de autenticación o actividad',
		async (status) => {
			const denegacion = {
				status,
				body: { message: status === 403 ? 'Tu usuario está desactivado' : 'Sesión inválida' }
			};
			perfil.mockRejectedValue(denegacion);
			await expect(requireImportadorPreview({ locals: {} } as never)).rejects.toBe(denegacion);
		}
	);
});
