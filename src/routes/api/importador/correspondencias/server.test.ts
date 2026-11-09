import { beforeEach, describe, expect, it, vi } from 'vitest';
vi.mock('$lib/server/importador-metrico/acceso', () => ({ estadoImportador: vi.fn() }));
import { estadoImportador } from '$lib/server/importador-metrico/acceso';
import { POST } from './+server';

const cuerpo = {
	literal: 'seguidilla',
	forma: 'seguidilla',
	arquitectura: null,
	procedencia: { edicion: 'Edición de prueba', obra: 'Obra', fila: 't01', foto: 'foto-01', pagina: 10 }
};

function evento(input: unknown = cuerpo) {
	const insert = vi.fn().mockResolvedValue({ error: null });
	const from = vi.fn(() => ({ insert }));
	return {
		request: new Request('http://localhost/api/importador/correspondencias', {
			method: 'POST',
			body: typeof input === 'string' ? input : JSON.stringify(input)
		}),
		locals: { supabase: { from }, safeGetSession: vi.fn().mockResolvedValue({ user: { id: 'actor' } }) },
		insert,
		from
	};
}
const post = (e: ReturnType<typeof evento>) => POST(e as never);

beforeEach(() => {
	vi.mocked(estadoImportador).mockReset().mockResolvedValue({} as never);
});

describe('registro de correspondencias', () => {
	it('registra con la identidad de la sesión', async () => {
		const e = evento();
		expect((await post(e)).status).toBe(201);
		expect(e.insert).toHaveBeenCalledWith({ ...cuerpo, creado_por: 'actor' });
	});
	it('normaliza los espacios del literal sin tocar mayúsculas', async () => {
		const e = evento({ ...cuerpo, literal: ' Seguidilla   simple ' });
		await post(e);
		expect(e.insert.mock.calls[0][0].literal).toBe('Seguidilla simple');
	});
	it('rechaza una autoría enviada por el navegador', async () => {
		const e = evento({ ...cuerpo, creado_por: 'otro' });
		await expect(post(e)).rejects.toMatchObject({ status: 400 });
		expect(e.from).not.toHaveBeenCalled();
	});
	it('rechaza una arquitectura ajena a la forma', async () => {
		await expect(post(evento({ ...cuerpo, arquitectura: 'inventada' }))).rejects.toMatchObject({ status: 400 });
	});
	it('exige permiso de importación', async () => {
		vi.mocked(estadoImportador).mockRejectedValue(Object.assign(new Error('Sin permiso'), { status: 403 }));
		const e = evento();
		await expect(post(e)).rejects.toMatchObject({ status: 403 });
		expect(e.from).not.toHaveBeenCalled();
	});
	it('rechaza una sesión caducada', async () => {
		const e = evento();
		e.locals.safeGetSession.mockResolvedValue({ user: null } as never);
		await expect(post(e)).rejects.toMatchObject({ status: 401 });
	});
	it('avisa si la correspondencia ya existía', async () => {
		const e = evento();
		e.insert.mockResolvedValue({ error: { code: '23505' } });
		await expect(post(e)).rejects.toMatchObject({ status: 409 });
	});
	it('rechaza JSON truncado', async () => {
		await expect(post(evento('{'))).rejects.toMatchObject({ status: 400 });
	});
});
