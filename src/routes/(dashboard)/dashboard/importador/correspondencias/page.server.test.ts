import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render } from 'svelte/server';
import { requireEditorProfile } from '$lib/server/auth';
import { actions, load } from './+page.server';
import Correspondencias from './+page.svelte';

vi.mock('$lib/server/auth', () => ({ requireEditorProfile: vi.fn() }));
const perfil = vi.mocked(requireEditorProfile);
const usuario = '00000000-0000-4000-8000-000000000001';
const id = '00000000-0000-4000-8000-000000000002';
const consulta = {
	select: vi.fn().mockReturnThis(),
	order: vi.fn().mockReturnThis(),
	range: vi.fn(),
	in: vi.fn(),
	update: vi.fn().mockReturnThis(),
	delete: vi.fn().mockReturnThis(),
	eq: vi.fn().mockReturnThis(),
	is: vi.fn().mockReturnThis(),
	maybeSingle: vi.fn()
};
const from = vi.fn(() => consulta);

function evento(extras = '') {
	const body = new FormData();
	body.set('id', id);
	const url = new URL('http://localhost/dashboard/importador/correspondencias' + extras);
	return { url, request: new Request(url, { method: 'POST', body }), locals: { supabase: { from } } } as never;
}

function rol(roleTerm: 'admin' | 'ip' | 'editor') {
	perfil.mockResolvedValue({
		userId: usuario, roleId: usuario, roleTerm, nombreCompleto: 'Editora de prueba', activo: true
	});
}

beforeEach(() => {
	vi.clearAllMocks();
	rol('admin');
	consulta.range.mockResolvedValue({ data: [], error: null });
	consulta.maybeSingle.mockResolvedValue({ data: { id }, error: null });
});

describe('revisión de correspondencias del importador', () => {
	it('impide a un editor consultar, revisar y retirar desde la pantalla de gestión', async () => {
		rol('editor');
		for (const accion of [load, actions.revisar!, actions.retirar!]) {
			await expect(accion(evento())).rejects.toMatchObject({ status: 403 });
		}
		expect(from).not.toHaveBeenCalled();
	});

	it('muestra procedencia y autor a IP y traduce el destino del catálogo', async () => {
		rol('ip');
		consulta.range.mockResolvedValue({ data: [{
			id, literal: 'sonetos', forma: 'soneto', arquitectura: null,
			creado_por: usuario, creado_en: '2026-11-19T15:00:00Z', revisado_por: null, revisado_en: null,
			procedencia: { obra: 'Obra de prueba', pagina: 37 }
		}], error: null });
		consulta.in.mockResolvedValue({ data: [{ user_id: usuario, nombre_completo: 'Editora de prueba' }], error: null });
		const datos = await load(evento());
		expect(datos).toMatchObject({
			pagina: 1,
			haySiguiente: false,
			correspondencias: [{ id, literal: 'sonetos', forma: 'Soneto', autor: 'Editora de prueba', obra: 'Obra de prueba', paginaFuente: 37 }]
		});
		const { body } = render(Correspondencias, { props: { data: datos, form: null } });
		expect(body).toContain('Editora de prueba');
		expect(body).toContain('Marcar revisada');
		expect(body).toContain('Retirar');
	});

	it('rechaza números de página fraccionarios antes de consultar el registro', async () => {
		await expect(load(evento('?pagina=1.5'))).rejects.toMatchObject({ status: 400 });
		expect(from).not.toHaveBeenCalled();
	});

	it('anota quién revisa sin sobrescribir la revisión de otra persona', async () => {
		await expect(actions.revisar!(evento())).resolves.toEqual({ exito: 'Correspondencia revisada.' });
		expect(consulta.update).toHaveBeenCalledWith({ revisado_por: usuario, revisado_en: expect.any(String) });
		expect(consulta.is).toHaveBeenCalledWith('revisado_en', null);
		consulta.maybeSingle.mockResolvedValue({ data: null, error: null });
		await expect(actions.revisar!(evento())).resolves.toMatchObject({ status: 409 });
	});

	it('retira únicamente la correspondencia seleccionada', async () => {
		await expect(actions.retirar!(evento())).resolves.toEqual({ exito: 'Correspondencia retirada.' });
		expect(consulta.delete).toHaveBeenCalledOnce();
		expect(consulta.eq).toHaveBeenCalledWith('id', id);
	});
});
