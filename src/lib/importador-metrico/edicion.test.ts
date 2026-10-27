import { describe, expect, it } from 'vitest';
import { analizarEntrada, obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';
import { aplicarEdiciones, type EdicionFila } from './edicion';

const entrada = (id: string) => obtenerPilotos().find((p) => p.id === id)!.entrada;
const base = () => analizarEntrada(entrada('el-molino')).datos!;
const cambio = (): EdicionFila => ({
	tramo_ref: 't01',
	partes: [
		{
			v_ini: 1,
			v_fin: 100,
			identificacion: { forma_slug: 'redondilla', arquitectura_slug: null },
			nota: null,
			conservar_remate: false
		},
		{
			v_ini: 101,
			v_fin: 200,
			identificacion: { forma_slug: 'romance', arquitectura_slug: null },
			nota: 'Cambio de forma en la fila.',
			conservar_remate: false
		},
		{
			v_ini: 201,
			v_fin: 532,
			identificacion: { forma_slug: 'redondilla', arquitectura_slug: null },
			nota: null,
			conservar_remate: false
		}
	]
});

describe('edición de las secuencias preparadas', () => {
	it('representa A → B → A como tres secuencias con el mismo origen, sin cambiar el original', () => {
		const datos = base();
		datos.segmentos[0].identificacion = { arquitectura_slug: null, forma_slug: 'redondilla' };
		const original = structuredClone(datos);
		const resultado = aplicarEdiciones(datos, [cambio()]);
		expect(datos).toEqual(original);
		expect(resultado.segmentos).toHaveLength(datos.segmentos.length + 2);
		const partes = resultado.segmentos.slice(0, 3);
		expect(partes.map((s) => s.identificacion?.forma_slug)).toEqual([
			'redondilla',
			'romance',
			'redondilla'
		]);
		expect(partes.map((s) => s.origen)).toEqual([
			datos.segmentos[0].origen,
			datos.segmentos[0].origen,
			datos.segmentos[0].origen
		]);
		expect(new Set(resultado.segmentos.map((s) => s.ref)).size).toBe(resultado.segmentos.length);
		expect(partes[1].regla_id).toBeNull();
		expect(partes[0].regla_id).toBe(datos.segmentos[0].regla_id);
		expect(partes[1].nota).toBe('Cambio de forma en la fila.');
		expect(partes[0].nota).toBeNull();
		expect(partes[2].nota).toBeNull();
	});
	it.each(['hueco', 'solapamiento', 'inicio', 'final', 'inversion'])(
		'rechaza límites con %s',
		(caso) => {
			const c = cambio();
			if (caso === 'hueco') c.partes[1].v_ini++;
			if (caso === 'solapamiento') c.partes[1].v_ini--;
			if (caso === 'inicio') c.partes[0].v_ini++;
			if (caso === 'final') c.partes[2].v_fin++;
			if (caso === 'inversion') c.partes[0].v_fin = 0;
			expect(() => aplicarEdiciones(base(), [c])).toThrow();
		}
	);
	it('rechaza campos imprevistos, filas inexistentes y cambios repetidos', () => {
		expect(() => aplicarEdiciones(base(), [{ ...cambio(), origen: {} }])).toThrow(/formato/);
		expect(() => aplicarEdiciones(base(), [{ ...cambio(), tramo_ref: 'inexistente' }])).toThrow(
			/no existe/
		);
		expect(() => aplicarEdiciones(base(), [cambio(), cambio()])).toThrow(/repetidos/);
	});
	it('conserva cada desviación en su parte y rechaza cortarla por la mitad', () => {
		const datos = analizarEntrada(entrada('los-locos-de-valencia')).datos!;
		const s = datos.segmentos.find((s) => s.ref === 't16')!;
		const parte = { identificacion: s.identificacion, nota: null, conservar_remate: false };
		const c = {
			tramo_ref: 't16',
			partes: [
				{ ...parte, v_ini: 2622, v_fin: 2665 },
				{ ...parte, v_ini: 2666, v_fin: 2754 }
			]
		};
		const resultado = aplicarEdiciones(datos, [c]);
		const divididas = resultado.segmentos.filter((s) => s.origen.tramo_ref === 't16');
		expect(divididas.map((s) => s.desviaciones.length)).toEqual([0, 1]);
		expect(resultado.segmentos.flatMap((s) => s.desviaciones)).toHaveLength(2);
		s.desviaciones[0].v_ini = 2665;
		expect(() => aplicarEdiciones(datos, [c])).toThrow(/atraviesa una desviación/);
	});
	it('mantiene un remate solo en la parte final y permite retirarlo expresamente', () => {
		const datos = analizarEntrada(entrada('el-verdadero-amante')).datos!;
		const s = datos.segmentos[1];
		const parte = { identificacion: s.identificacion, nota: null, conservar_remate: true };
		const c = {
			tramo_ref: 't02',
			partes: [
				{ ...parte, v_ini: 221, v_fin: 250 },
				{ ...parte, v_ini: 251, v_fin: 287 }
			]
		};
		expect(
			aplicarEdiciones(datos, [c])
				.segmentos.filter((s) => s.origen.tramo_ref === 't02')
				.map((s) => s.detalles_fuente.length)
		).toEqual([0, 1]);
		c.partes[1].conservar_remate = false;
		expect(
			aplicarEdiciones(datos, [c])
				.segmentos.filter((s) => s.origen.tramo_ref === 't02')
				.flatMap((s) => s.detalles_fuente)
		).toEqual([]);
	});
	it('valida el catálogo en servidor y conserva una vista corregible cuando se rechaza el cambio', () => {
		const c = cambio();
		c.partes[1].identificacion!.forma_slug = 'forma_inventada';
		const vista = analizarEntrada(entrada('el-molino'), {}, [c]);
		expect(vista.errores.some((e) => e.codigo === 'edicion')).toBe(true);
		expect(vista.datos).toEqual(base());
		expect(vista.filas).toHaveLength(base().segmentos.length);
	});
	it('aplica el cambio en servidor sin confirmar ni alterar la huella, y restablece desde la entrada', () => {
		const inicial = analizarEntrada(entrada('el-molino'));
		const editada = analizarEntrada(entrada('el-molino'), {}, [cambio()]);
		expect(editada.errores).toEqual([]);
		expect(editada.datos!.procedencia).toEqual(inicial.datos!.procedencia);
		expect(editada.resumen!.extension).toBe(inicial.resumen!.extension);
		expect(editada.persistido).toBe(false);
		expect(editada.confirmacion).toBeNull();
		expect(analizarEntrada(entrada('el-molino'), {}, []).datos).toEqual(inicial.datos);
	});
});
