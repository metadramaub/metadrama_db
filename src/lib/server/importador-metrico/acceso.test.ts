import { beforeEach, describe, expect, it, vi } from 'vitest';
import { requireImportadorPreview, estadoImportador } from './acceso';

const { perfil } = vi.hoisted(() => ({ perfil: vi.fn() }));
const event = () =>
	({
		locals: {
			supabase: { rpc: vi.fn().mockResolvedValue({ data: null, error: { code: 'PGRST202' } }) }
		}
	}) as never;
vi.mock('$lib/server/auth', () => ({ requireEditorProfile: perfil }));

beforeEach(() => {
	perfil.mockReset();
});

describe('acceso al ensayo del importador', () => {
	it('admite un editor habilitado por la sesión de DB, sin deducir permiso del formulario', async () => {
		perfil.mockResolvedValue({ roleTerm: 'editor', activo: true });
		const evento = {
			locals: {
				supabase: {
					rpc: vi
						.fn()
						.mockResolvedValue({
							data: { puede_importar: true, guardado_disponible: true },
							error: null
						})
				}
			}
		} as never;
		expect((await estadoImportador(evento)).guardadoDisponible).toBe(true);
	});
	it('una respuesta de permiso negativo bloquea también un administrador', async () => {
		perfil.mockResolvedValue({ roleTerm: 'admin', activo: true });
		const evento = {
			locals: {
				supabase: {
					rpc: vi
						.fn()
						.mockResolvedValue({
							data: { puede_importar: false, guardado_disponible: false },
							error: null
						})
				}
			}
		} as never;
		await expect(estadoImportador(evento)).rejects.toMatchObject({ status: 403 });
	});
	it.each(['admin', 'ip'])('admite un perfil activo %s', async (roleTerm) => {
		const editor = { roleTerm, activo: true };
		perfil.mockResolvedValue(editor);
		const evento = event();
		expect(await requireImportadorPreview(evento)).toBe(editor);
		expect(perfil).toHaveBeenCalledWith(evento);
	});
	it('no concede el ensayo a un editor aunque declare una futura capacidad', async () => {
		perfil.mockResolvedValue({ roleTerm: 'editor', activo: true, puede_importar_metrica: true });
		await expect(requireImportadorPreview(event())).rejects.toMatchObject({
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
