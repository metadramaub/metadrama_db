import { describe, expect, it, vi } from 'vitest';
import {
	capacidadesImportador,
	guardarImportacion,
	huellaConfirmacion,
	extraccionOriginal,
	type ClienteImportador
} from './persistencia';
import { analizarEntrada, obtenerPilotos, vistaDeFichaGuardada } from './vista-previa';

const autorId = '00000000-0000-4000-8000-000000000001';
const peticionId = '00000000-0000-4000-8000-000000000002';
const piloto = obtenerPilotos()[0];
function caso() {
	const datos = analizarEntrada(piloto.entrada).datos!;
	return {
		datos,
		autorId,
		peticionId,
		entrada: piloto.entrada,
		coincidencias: [],
		otraObra: false,
		huella: huellaConfirmacion(datos, autorId, [])
	};
}
function db() {
	return {
		rpc: vi.fn().mockResolvedValue({
			data: { obra_id: autorId, importacion_id: peticionId, repetida: false },
			error: null
		})
	} satisfies ClienteImportador;
}
describe('confirmación de importación', () => {
	it('envía solo la copia revisada y la extracción original con una petición estable', async () => {
		const cliente = db(),
			p = caso();
		await guardarImportacion(cliente, p);
		expect(cliente.rpc).toHaveBeenCalledWith(
			'guardar_ficha_minima',
			expect.objectContaining({
				p_peticion: peticionId,
				p_datos: p.datos,
				p_entrada_original: JSON.parse(piloto.entrada),
				p_coincidencias_revisadas: []
			})
		);
	});
	it('no escribe si cambiaron los datos después de comprobarlos', async () => {
		const cliente = db(),
			p = caso();
		p.datos.metadatos.titulo += ' corregido';
		await expect(guardarImportacion(cliente, p)).rejects.toMatchObject({ status: 409 });
		expect(cliente.rpc).not.toHaveBeenCalled();
	});
	it('no escribe con una nueva coincidencia que no figuraba en la vista revisada', async () => {
		const cliente = db(),
			p = {
				...caso(),
				coincidencias: [
					{ obra_id: autorId, titulo: 'Otra', tipo_ficha: 'completa' as const, autores: ['Lope'] }
				],
				otraObra: true
			};
		await expect(guardarImportacion(cliente, p)).rejects.toMatchObject({ status: 409 });
		expect(cliente.rpc).not.toHaveBeenCalled();
	});
	it('requiere la decisión otra obra y conserva los IDs revisados', async () => {
		const cliente = db(),
			p = {
				...caso(),
				coincidencias: [
					{ obra_id: autorId, titulo: 'Otra', tipo_ficha: 'completa' as const, autores: ['Lope'] }
				]
			};
		p.huella = huellaConfirmacion(p.datos, autorId, p.coincidencias);
		await expect(guardarImportacion(cliente, p)).rejects.toMatchObject({ status: 409 });
		expect(cliente.rpc).not.toHaveBeenCalled();
		await guardarImportacion(cliente, { ...p, otraObra: true });
		expect(cliente.rpc).toHaveBeenCalledWith(
			'guardar_ficha_minima',
			expect.objectContaining({ p_coincidencias_revisadas: [autorId] })
		);
	});
	it('rechaza identificadores inválidos antes de llamar a la DB', async () => {
		const cliente = db();
		await expect(
			guardarImportacion(cliente, { ...caso(), peticionId: 'inválido' })
		).rejects.toMatchObject({ status: 400 });
		expect(cliente.rpc).not.toHaveBeenCalled();
	});
	it('un fallo de red no se confunde con ausencia de instalación', async () => {
		const cliente = db();
		cliente.rpc.mockResolvedValue({ data: null, error: { code: 'NETWORK' } } as never);
		await expect(capacidadesImportador(cliente)).rejects.toMatchObject({ status: 503 });
	});
	it('permite la vista previa de compatibilidad cuando falta la RPC', async () => {
		const cliente = db();
		cliente.rpc.mockResolvedValue({ data: null, error: { code: 'PGRST202' } } as never);
		expect(await capacidadesImportador(cliente)).toBeNull();
	});
	it('rechaza guardar una ficha preparada sin su extracción original', () => {
		expect(() => extraccionOriginal(JSON.stringify(caso().datos))).toThrow('extracción original');
	});
	it('consulta la copia fija sin reaplicar reglas ni perder notas originales', () => {
		const p = caso();
		p.datos.metadatos.titulo = 'Nombre guardado';
		const vista = vistaDeFichaGuardada(p.datos, JSON.parse(piloto.entrada), {
			obra_id: autorId,
			importacion_id: peticionId
		});
		expect(vista.persistido).toBe(true);
		expect(vista.datos).toEqual(p.datos);
		expect(vista.filas).toHaveLength(p.datos.segmentos.length);
		expect(vista.avisos).toEqual([]);
	});
});
