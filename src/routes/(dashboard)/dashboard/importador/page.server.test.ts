import { beforeEach, describe, expect, it, vi } from 'vitest';
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
	it('sin fechas prepara las filas, no emite huella y bloquea confirmar aunque se fuerce el POST', async () => {
		const previa = await actions.comprobar!(event({fecha_inicio:'',fecha_fin:''}));
		expect(previa).toMatchObject({huella:null,vista:{errores:[]}});
		expect(previa && 'vista' in previa && previa.vista.filas.length).toBeGreaterThan(0);
		const r = await actions.confirmar!(event({fecha_inicio:'',fecha_fin:'',huella:'forzada'}));
		expect(r).toMatchObject({status:400});
		expect(rpc.mock.calls.some(([name])=>name==='guardar_ficha_minima')).toBe(false);
	});
	it('reconstruye la vista en servidor y redirige a la copia guardada', async () => {
		const previa = await comprobar();
		await expect(actions.confirmar!(event({ huella: previa.huella! }))).rejects.toMatchObject({
			status: 303,
			location: '/dashboard/importador/fichas/' + importacion
		});
		expect(rpc).toHaveBeenCalledWith(
			'guardar_ficha_minima',
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
		expect(rpc.mock.calls.some(([name]) => name === 'guardar_ficha_minima')).toBe(false);
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
		expect(rpc.mock.calls.some(([name]) => name === 'guardar_ficha_minima')).toBe(false);
	});
});
