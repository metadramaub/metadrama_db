import { beforeEach, describe, expect, it, vi } from 'vitest';
// Sin registro de correspondencias: estas pruebas no tocan la tabla.
vi.mock('$lib/server/importador-metrico/correspondencias', async (original) => ({
	...(await original<typeof import('$lib/server/importador-metrico/correspondencias')>()),
	cargarCorrespondencias: vi.fn().mockResolvedValue([])
}));
import { actions } from './+page.server';
import type { SegmentoMinimo } from '$lib/importador-metrico/types';
import { analizarEntrada, obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';

vi.mock('$lib/server/importador-metrico/acceso', () => ({
	estadoImportador: vi.fn().mockResolvedValue({ guardadoDisponible: true })
}));
const autor = '00000000-0000-4000-8000-000000000001';
const importacion = '00000000-0000-4000-8000-000000000002';
const entrada = obtenerPilotos()[0].entrada;
const metadatos = analizarEntrada(entrada).metadatos;
let coincidencias: unknown[] = [];
const rpc = vi.fn();
function event(extra: Record<string, string> = {}) {
	const body = new FormData();
	for (const [key, value] of Object.entries({
		...metadatos,
		entrada,
		autor_id: autor,
		ediciones: '[]',
		peticion_id: importacion,
		...extra
	}))
		body.set(key, value);
	return {
		request: new Request('http://localhost/dashboard/importador', { method: 'POST', body }),
		locals: {
			supabase: {
				rpc,
				from: () => ({
					select: () => ({
						eq: () => ({
							maybeSingle: async () => ({
								data: { autor_id: autor, nombre_completo: metadatos.autor_nombre },
								error: null
							})
						})
					})
				})
			}
		}
	} as never;
}
beforeEach(() => {
	coincidencias = [];
	rpc.mockReset();
	rpc.mockImplementation(async (name: string) => ({
		data:
			name === 'coincidencias_importacion_metrica'
				? coincidencias
				: { obra_id: autor, importacion_id: importacion, repetida: false },
		error: null
	}));
});
async function comprobar() {
	const r = await actions.comprobar!(event());
	if (!r || !('huella' in r) || !r.huella) throw new Error('Vista previa no preparada');
	return r;
}
describe('acciones HTTP del importador', () => {
	it('prepara una básica con los metadatos de su obra de destino', async () => {
		rpc.mockImplementation(async (name: string) => ({
			data: name === 'destino_importacion_metrica'
				? { obra_id: importacion, titulo: 'Fuenteovejuna' }
				: [],
			error: null
		}));
		const solicitud = event({ obra_id: importacion }) as Parameters<typeof actions.leer>[0];
		vi.spyOn(solicitud.locals.supabase, 'from').mockImplementation((tabla: string) => ({
			select: () => ({
				eq: () => ({
					limit: async () => ({ data: [{ autor_id: autor }], error: null }),
					maybeSingle: async () => ({
						data: tabla === 'obras_editoriales'
							? {
								autores: ['Lope de Vega'],
								genero_id: importacion,
								dataciones: [{ clase: 'referencia', inicio: 1612, fin: 1614, fuente: 'Datación registrada' }]
							}
							: tabla === 'vocabularios'
								? { termino: 'comedia_o_tragicomedia' }
								: { autor_id: autor, nombre_completo: 'Lope de Vega' },
						error: null
					})
				})
			})
		}) as never);
		expect(await actions.leer!(solicitud)).toMatchObject({
			autorId: autor,
			vista: { metadatos: {
				titulo: 'Fuenteovejuna', autor_nombre: 'Lope de Vega', genero: 'comedia_o_tragicomedia',
				fecha_inicio: '1612', fecha_fin: '1614', fuente_fecha: 'Datación registrada'
			} }
		});
	});
	it('marca la comprobación terminada solo en comprobar, no al preparar el JSON', async () => {
		expect(await actions.comprobar!(event())).toMatchObject({comprobacion_realizada:true});
		expect(await actions.leer!(event())).toMatchObject({comprobacion_realizada:false});
	});
	it('prepara y guarda una datación con un solo límite exclusivo', async () => {
		const fechas = { fecha_inicio: '', fecha_fin: '1614', fin_inclusivo: 'false', fecha_aproximada: 'true' };
		const previa = await actions.comprobar!(event(fechas));
		expect(previa).toMatchObject({ huella: expect.any(String), vista: { errores: [] } });
		expect(previa && 'vista' in previa && previa.vista.filas.length).toBeGreaterThan(0);
		const huella = (previa as { huella: string }).huella;
		await expect(actions.confirmar!(event({ ...fechas, huella }))).rejects.toMatchObject({ status: 303 });
		expect(rpc).toHaveBeenCalledWith('guardar_ficha_basica', expect.objectContaining({
			p_datos: expect.objectContaining({ metadatos: expect.objectContaining({
				fecha_inicio: null, fecha_fin: 1614, fin_inclusivo: false, fecha_aproximada: true
			}) })
		}));
	});
	it('reconstruye la vista en servidor y redirige a la copia guardada', async () => {
		const previa = await comprobar();
		await expect(actions.confirmar!(event({ huella: previa.huella! }))).rejects.toMatchObject({
			status: 303,
			location: '/dashboard/obras/' + autor + '?tab=secuencias'
		});
		expect(rpc).toHaveBeenCalledWith(
			'guardar_ficha_basica',
			expect.objectContaining({
				p_peticion: importacion,
				p_entrada_original: JSON.parse(entrada),
				p_datos: {
					...previa.vista.datos,
					segmentos: previa.vista.datos!.segmentos.map((s: SegmentoMinimo) => ({
						...s,
						segmentacion: 'confirmada'
					}))
				}
			})
		);
	});
	it('un cambio posterior de título no guarda ni reutiliza la vista anterior', async () => {
		const previa = await comprobar();
		rpc.mockClear();
		const r = await actions.confirmar!(
			event({ huella: previa.huella!, titulo: 'Cambio posterior' })
		);
		expect(r).toMatchObject({ status: 409 });
		expect(rpc.mock.calls.some(([name]) => name === 'guardar_ficha_basica')).toBe(false);
	});
	it('una coincidencia nueva entre comprobar y guardar exige otra revisión', async () => {
		const previa = await comprobar();
		rpc.mockClear();
		coincidencias = [
			{
				obra_id: autor,
				titulo: metadatos.titulo,
				autores: [metadatos.autor_nombre],
				tipo_ficha: 'completa'
			}
		];
		const r = await actions.confirmar!(
			event({ huella: previa.huella!, decision_coincidencias: 'otra_obra' })
		);
		expect(r).toMatchObject({ status: 409 });
		expect(rpc.mock.calls.some(([name]) => name === 'guardar_ficha_basica')).toBe(false);
	});
});
