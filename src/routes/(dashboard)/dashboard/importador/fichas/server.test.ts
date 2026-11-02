import { beforeEach, describe, expect, it, vi } from 'vitest';
import { actions, load } from './+page.server';
const { acceso } = vi.hoisted(() => ({ acceso: vi.fn() }));
vi.mock('$lib/server/importador-metrico/acceso', () => ({ estadoImportador: acceso }));
const id = '00000000-0000-4000-8000-000000000001';
function evento(campos: Record<string,string> = {}) {
	const form = new FormData(); for (const [k,v] of Object.entries(campos)) form.set(k,v);
	const rpc = vi.fn().mockResolvedValue({ data: { eliminada: true, obra_id: id }, error: null });
	return { rpc, event: { locals: { supabase: { rpc } }, request: { formData: async () => form }, url: new URL('https://example.test/dashboard/importador/fichas?pagina=2') } };
}
beforeEach(() => acceso.mockResolvedValue({ profile: { roleTerm: 'admin' }, guardadoDisponible: true }));
describe('gestión de fichas básicas', () => {
	it.each(['admin','ip'])('permite a %s solicitar el borrado confirmado y recarga el listado', async (rol) => {
		acceso.mockResolvedValue({ profile: { roleTerm: rol }, guardadoDisponible: true });
		const { event, rpc } = evento({ importacion_id: id, confirmacion: 'El molino' });
		await expect(actions.eliminar(event as never)).rejects.toMatchObject({ status: 303, location: '/dashboard/importador/fichas?pagina=2' });
		expect(rpc).toHaveBeenCalledWith('eliminar_ficha_basica', { p_importacion: id, p_confirmacion: 'El molino' });
	});
	it('rechaza a un editor autorizado para importar antes de llamar a la base', async () => {
		acceso.mockResolvedValue({ profile: { roleTerm: 'editor' }, guardadoDisponible: true });
		const { event, rpc } = evento({ importacion_id: id, confirmacion: 'El molino' });
		await expect(actions.eliminar(event as never)).rejects.toMatchObject({ status: 403 });
		expect(rpc).not.toHaveBeenCalled();
	});
	it('no solicita borrar un identificador inválido', async () => {
		const { event, rpc } = evento({ importacion_id: 'incorrecto', confirmacion: 'El molino' });
		expect(await actions.eliminar(event as never)).toMatchObject({ status: 400 });
		expect(rpc).not.toHaveBeenCalled();
	});
	it('muestra el error del servidor cuando ha cambiado la ficha o la confirmación', async () => {
		const { event, rpc } = evento({ importacion_id: id, confirmacion: 'El molino' });
		rpc.mockResolvedValue({ data: null, error: { code: '22023', message: 'Escribe el título de la obra para confirmar' } } as never);
		expect(await actions.eliminar(event as never)).toMatchObject({ status: 409, data: { importacion_id: id, mensaje: 'Escribe el título de la obra para confirmar' } });
	});
	it('mantiene paginación y solo ofrece eliminar al rol permitido', async () => {
		acceso.mockResolvedValue({ profile: { roleTerm: 'editor' }, guardadoDisponible: true });
		const { event, rpc } = evento(); rpc.mockResolvedValue({ data: [], error: null } as never);
		expect(await load(event as never)).toMatchObject({ pagina: 2, puedeEliminar: false, filas: [] });
		expect(rpc).toHaveBeenCalledWith('listar_fichas_basicas', { p_desde: 50 });
	});
});
