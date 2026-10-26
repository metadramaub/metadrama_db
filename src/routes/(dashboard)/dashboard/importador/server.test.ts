import { beforeEach, describe, expect, it, vi } from 'vitest';
import { actions, load } from './+page.server';
import { obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';
import type { ResultadoVistaPrevia } from '$lib/importador-metrico/types';

const { autorizar } = vi.hoisted(() => ({ autorizar: vi.fn() }));
vi.mock('$lib/server/importador-metrico/acceso', () => ({ requireImportadorPreview: autorizar }));

const piloto = obtenerPilotos()[0];
const metadatos = {
	titulo: 'Título revisado',
	autor_nombre: 'Nombre escrito a mano',
	genero: 'comedia_o_tragicomedia',
	edicion_base: 'Edición de prueba',
	fecha_inicio: '1580',
	fecha_fin: '1590',
	fuente_fecha: '',
	fundamento_autoria: ''
};
type Devuelto = {
	entrada: string;
	autorId: string;
	vista: ResultadoVistaPrevia;
	coincidencias: unknown[];
};

function entorno(
	campos: Record<string, string> = {},
	opciones: { autor?: unknown; longitud?: string; falloTabla?: string } = {}
) {
	const consultas: { tabla: string; metodo: string; args: unknown[] }[] = [];
	const from = vi.fn((tabla: string) => {
		const resultado = {
			data:
				tabla === 'autores'
					? [{ autor_id: 'id-vigente', nombre_completo: 'Autor del catálogo' }]
					: tabla === 'vocabularios'
						? [{ termino: 'comedia_o_tragicomedia', etiqueta: 'Comedia' }]
						: [{ obra_id: 'obra-existente', titulo: 'Mismo título', slug: 'mismo-titulo' }],
			error: opciones.falloTabla === tabla ? { message: 'fallo' } : null
		};
		const cadena: Record<string, unknown> = {};
		for (const metodo of ['select', 'eq', 'ilike']) {
			cadena[metodo] = (...args: unknown[]) => {
				consultas.push({ tabla, metodo, args });
				return cadena;
			};
		}
		for (const metodo of ['order', 'limit']) {
			cadena[metodo] = async (...args: unknown[]) => {
				consultas.push({ tabla, metodo, args });
				return resultado;
			};
		}
		cadena.maybeSingle = async () => ({
			data:
				'autor' in opciones
					? opciones.autor
					: { autor_id: 'id-vigente', nombre_completo: 'Autor vigente en DB' },
			error: resultado.error
		});
		return cadena;
	});
	const form = new FormData();
	for (const [clave, valor] of Object.entries({ entrada: piloto.entrada, ...campos }))
		form.set(clave, valor);
	const formData = vi.fn(async () => form);
	const event = {
		locals: { supabase: { from } },
		request: {
			headers: new Headers(opciones.longitud ? { 'content-length': opciones.longitud } : {}),
			formData
		}
	};
	return { event, from, formData, consultas };
}

beforeEach(() => {
	autorizar.mockReset();
	autorizar.mockResolvedValue({ roleTerm: 'admin' });
});

describe('acciones de la vista previa del importador', () => {
	it('resuelve el nombre del autor seleccionado desde DB e ignora el nombre del formulario', async () => {
		const e = entorno({ ...metadatos, autor_id: 'id-vigente' });
		const resultado = (await actions.comprobar!(e.event as never)) as Devuelto;
		expect(resultado.vista.errores).toEqual([]);
		expect(resultado.vista.datos?.metadatos.autor_nombre).toBe('Autor vigente en DB');
		expect(e.consultas).toContainEqual({
			tabla: 'autores',
			metodo: 'eq',
			args: ['autor_id', 'id-vigente']
		});
		expect(resultado.autorId).toBe('id-vigente');
	});
	it('rechaza un autor inexistente y conserva los datos editados para elegir otro', async () => {
		const e = entorno({ ...metadatos, autor_id: 'autor-borrado' }, { autor: null });
		const resultado = await actions.comprobar!(e.event as never);
		expect(resultado).toMatchObject({
			status: 400,
			data: {
				mensaje: expect.stringContaining('ya no está disponible'),
				entrada: piloto.entrada,
				autorId: '',
				coincidencias: [],
				vista: {
					persistido: false,
					metadatos: { titulo: metadatos.titulo, fuente_fecha: '' },
					datos: { metadatos: { titulo: metadatos.titulo, fuente_fecha: null } }
				}
			}
		});
		expect(e.from.mock.calls.map(([tabla]) => tabla)).toEqual(['autores']);
	});
	it('leer carga metadatos de la nueva entrada y descarta los campos viejos del formulario', async () => {
		const e = entorno({ ...metadatos, autor_id: 'id-obsoleto' });
		const resultado = (await actions.leer!(e.event as never)) as Devuelto;
		expect(resultado.vista.metadatos.titulo).toBe(piloto.titulo);
		expect(resultado.vista.metadatos.autor_nombre).toBe('Lope de Vega');
		expect(resultado.autorId).toBe('');
		expect(e.from).not.toHaveBeenCalledWith('autores');
	});
	it('comprobar permite borrar una fuente opcional y no obliga a fundamentar la autoría', async () => {
		const e = entorno(metadatos);
		const resultado = (await actions.comprobar!(e.event as never)) as Devuelto;
		expect(resultado.vista.errores).toEqual([]);
		expect(resultado.vista.datos?.metadatos.fuente_fecha).toBeNull();
		expect(resultado.vista.datos?.metadatos.fundamento_autoria).toBeNull();
	});
	it('escapa comodines y barras en la búsqueda ilike de títulos', async () => {
		const titulo = '  Obra 100%_\\final  ';
		const e = entorno({ ...metadatos, titulo });
		const resultado = (await actions.comprobar!(e.event as never)) as Devuelto;
		expect(e.consultas).toContainEqual({
			tabla: 'obras',
			metodo: 'ilike',
			args: ['titulo', 'Obra 100\\%\\_\\\\final']
		});
		expect(resultado.coincidencias).toHaveLength(1);
		expect(e.consultas).toContainEqual({ tabla: 'obras', metodo: 'limit', args: [20] });
	});
	it.each(['leer', 'comprobar'] as const)(
		'%s autoriza antes de leer el cuerpo o consultar DB',
		async (accion) => {
			const e = entorno();
			autorizar.mockRejectedValue({ status: 403, body: { message: 'Sin acceso' } });
			await expect(actions[accion]!(e.event as never)).rejects.toMatchObject({ status: 403 });
			expect(e.formData).not.toHaveBeenCalled();
			expect(e.from).not.toHaveBeenCalled();
		}
	);
	it.each(['leer', 'comprobar'] as const)(
		'%s limita el tamaño declarado antes de leer el cuerpo',
		async (accion) => {
			const e = entorno({}, { longitud: '3000001' });
			expect(await actions[accion]!(e.event as never)).toMatchObject({ status: 413 });
			expect(e.formData).not.toHaveBeenCalled();
			expect(e.from).not.toHaveBeenCalled();
		}
	);
	it('limita el tamaño real de la entrada aunque falte content-length', async () => {
		const e = entorno({ entrada: 'x'.repeat(2_000_001), autor_id: 'id-vigente' });
		expect(await actions.comprobar!(e.event as never)).toMatchObject({ status: 413 });
		expect(e.from).not.toHaveBeenCalled();
	});
	it('devuelve una vista con errores para JSON inválido sin consultar ni guardar', async () => {
		const e = entorno({ entrada: '{incompleto' });
		const resultado = (await actions.leer!(e.event as never)) as Devuelto;
		expect(resultado.vista.errores.length).toBeGreaterThan(0);
		expect(resultado.vista.persistido).toBe(false);
		expect(e.from).not.toHaveBeenCalled();
	});
	it('informa un fallo al resolver el autor en DB', async () => {
		const e = entorno({ ...metadatos, autor_id: 'id-vigente' }, { falloTabla: 'autores' });
		await expect(actions.comprobar!(e.event as never)).rejects.toMatchObject({ status: 500 });
	});
});

describe('load del importador', () => {
	it('carga autores y géneros vigentes más los pilotos de solo lectura', async () => {
		const e = entorno();
		const resultado = (await load(e.event as never)) as {
			autores: unknown[];
			generos: unknown[];
			pilotos: unknown[];
		};
		expect(resultado.autores).toHaveLength(1);
		expect(resultado.generos).toHaveLength(1);
		expect(resultado.pilotos).toHaveLength(4);
		expect(e.consultas).toContainEqual({
			tabla: 'vocabularios',
			metodo: 'eq',
			args: ['activo', true]
		});
		expect(e.from.mock.calls.map(([tabla]) => tabla)).toEqual(['autores', 'vocabularios']);
	});
	it('autoriza antes de cualquier lectura DB', async () => {
		const e = entorno();
		autorizar.mockRejectedValue({ status: 403, body: { message: 'Sin acceso' } });
		await expect(load(e.event as never)).rejects.toMatchObject({ status: 403 });
		expect(e.from).not.toHaveBeenCalled();
	});
	it('devuelve error si los vocabularios no se pueden cargar', async () => {
		const e = entorno({}, { falloTabla: 'vocabularios' });
		await expect(load(e.event as never)).rejects.toMatchObject({ status: 500 });
	});
});
