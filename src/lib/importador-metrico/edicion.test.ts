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
			remate: null
		},
		{
			v_ini: 101,
			v_fin: 200,
			identificacion: { forma_slug: 'romance', arquitectura_slug: null },
			nota: 'Cambio de forma en la fila.',
			remate: null
		},
		{
			v_ini: 201,
			v_fin: 532,
			identificacion: { forma_slug: 'redondilla', arquitectura_slug: null },
			nota: null,
			remate: null
		}
	]
});

describe('edición de las secuencias preparadas', () => {
	it.each([
		['el-verdadero-amante', 'romance en -io', 'i-o', '-io'],
		['los-locos-de-valencia', 'romance en á-e', 'a-e', 'á-e']
	])('convierte la asonancia explícita de %s en su valor de catálogo y permite corregirla', (obra, denominacion, valor, literal) => {
		const texto = entrada(obra);
		const vista = analizarEntrada(texto);
		expect(vista.errores).toEqual([]);
		const s = vista.datos!.segmentos.find((s) => s.origen.denominacion_literal === denominacion)!;
		expect(s.detalles_fuente).toContainEqual({literal, rasgo_slug: 'vocales_asonancia', valor_slug: valor});
		expect(s.detalles_fuente.some((d) => d.dimension === 'asonancia')).toBe(false);
		const parte = {v_ini: s.v_ini, v_fin: s.v_fin, identificacion: s.identificacion, nota: null, remate: null, rasgos: [{rasgo_slug: 'vocales_asonancia', valor_slug: 'e-o'}]};
		const corregida = analizarEntrada(texto, {}, [{tramo_ref: s.origen.tramo_ref, partes: [parte]}]);
		expect(corregida.errores).toEqual([]);
		expect(corregida.datos!.segmentos.find((n) => n.origen.tramo_ref === s.origen.tramo_ref)!.detalles_fuente).toEqual([{rasgo_slug: 'vocales_asonancia', valor_slug: 'e-o'}]);
		expect(s.origen.denominacion_literal).toBe(denominacion);
	});
	it('registra el pareado final como Dístico final / Presente y lo conserva solo al final al dividir', () => {
		const datos = analizarEntrada(entrada('el-verdadero-amante')).datos!;
		const s = datos.segmentos.find((s) => s.detalles_fuente.some((d) => d.rasgo_slug === 'distico_final'))!;
		expect(s).toBeDefined();
		expect(s.detalles_fuente).toContainEqual({literal: 'pareado final', rasgo_slug: 'distico_final', valor_slug: 'presente'});
		expect(s.detalles_fuente.some((d) => d.tipo_seccion === 'remate')).toBe(false);
		const p = {identificacion: s.identificacion, nota: null, remate: null};
		const editada = aplicarEdiciones(datos, [{tramo_ref: s.origen.tramo_ref, partes: [
			{...p, v_ini: s.v_ini, v_fin: s.v_ini + 2}, {...p, v_ini: s.v_ini + 3, v_fin: s.v_fin}
		]}]);
		expect(editada.segmentos.filter((n) => n.origen.tramo_ref === s.origen.tramo_ref).map((n) => n.detalles_fuente.filter((d) => d.rasgo_slug === 'distico_final').length)).toEqual([0, 1]);
	});
	it('permite añadir, editar y quitar una desviación documentada sin aceptar texto de fuente inventado', () => {
		const original = JSON.parse(entrada('los-locos-de-valencia'));
		// Al cambiar el original, no se heredan las decisiones particulares del piloto.
		original.metadatos.titulo += ' (prueba)';
		const datos = analizarEntrada(JSON.stringify(original)).datos!;
		const s = datos.segmentos.find((s) => s.ref === 't16')!;
		expect(s.desviaciones).toEqual([]);
		const p = {v_ini: s.v_ini, v_fin: s.v_fin, identificacion: s.identificacion, remate: null, nota: null, desviaciones: [{v_ini: 2666, v_fin: 2666, dimension: 'estructura', relacion_norma: 'sobra', nota_ref: 'n02', nota: null}]};
		const texto = JSON.stringify(original);
		const vista = analizarEntrada(texto, {}, [{tramo_ref: 't16', partes: [p]}]);
		expect(vista.errores).toEqual([]);
		expect(vista.datos!.segmentos.find((s) => s.ref === 't16')!.desviaciones[0]).toMatchObject({texto_fuente: original.notas.find((n: {id: string}) => n.id === 'n02').texto_literal, v_ini: 2666});
		for (const d of [{...p.desviaciones[0], nota_ref: 'n01'}, {...p.desviaciones[0], v_ini: 1}, {...p.desviaciones[0], texto_fuente: 'Inventado'}]) {
			expect(analizarEntrada(texto, {}, [{tramo_ref: 't16', partes: [{...p, desviaciones: [d]}]}]).errores.some((e) => e.codigo === 'edicion')).toBe(true);
		}
		expect(analizarEntrada(texto, {}, [{tramo_ref: 't16', partes: [{...p, desviaciones: []}]}]).datos!.segmentos.find((s) => s.ref === 't16')!.desviaciones).toEqual([]);
	});
	it('rechaza un rasgo o valor incompatible con la forma aunque llegue del cliente', () => {
		const c = cambio();
		c.partes[0].rasgos = [{rasgo_slug: 'distico_final', valor_slug: 'presente'}];
		expect(analizarEntrada(entrada('el-molino'), {}, [c]).errores.some((e) => e.codigo === 'edicion')).toBe(true);
	});
	it('permite añadir y retirar un rasgo, exige el valor admitido y conserva la extracción', () => {
		const texto = entrada('el-verdadero-amante');
		const s = analizarEntrada(texto).datos!.segmentos.find((s) => s.ref === 't15')!;
		const p = {v_ini: s.v_ini, v_fin: s.v_fin, identificacion: s.identificacion, nota: null, remate: null, rasgos: [{rasgo_slug: 'distico_final', valor_slug: 'presente'}]};
		const vista = analizarEntrada(texto, {}, [{tramo_ref: 't15', partes: [p]}]);
		expect(vista.errores).toEqual([]);
		expect(vista.datos!.segmentos.find((s) => s.ref === 't15')!.detalles_fuente[0]).toMatchObject(p.rasgos[0]);
		expect(analizarEntrada(texto, {}, [{tramo_ref: 't15', partes: [{...p, rasgos: [{rasgo_slug: 'distico_final', valor_slug: 'ausente'}]}]}]).errores.some((e) => e.codigo === 'edicion')).toBe(true);
		expect(analizarEntrada(texto, {}, [{tramo_ref: 't15', partes: [{...p, rasgos: []}]}]).datos!.segmentos.find((s) => s.ref === 't15')!.detalles_fuente).toEqual([]);
		expect(analizarEntrada(texto).datos!.segmentos.find((s) => s.ref === 't15')!.detalles_fuente).toEqual([]);
	});
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
		const parte = { identificacion: s.identificacion, nota: null, remate: null };
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
		const parte: {
			identificacion: typeof s.identificacion;
			nota: null;
			remate: { n_versos: number } | null;
		} = { identificacion: s.identificacion, nota: null, remate: { n_versos: 2 } };
		const c = {
			tramo_ref: 't02',
			partes: [
				{ ...parte, v_ini: 221, v_fin: 250, remate: null },
				{ ...parte, v_ini: 251, v_fin: 287 }
			]
		};
		expect(
			aplicarEdiciones(datos, [c])
				.segmentos.filter((s) => s.origen.tramo_ref === 't02')
				.map((s) => s.detalles_fuente.length)
		).toEqual([0, 1]);
		c.partes[1].remate = null;
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
	it('añade un remate ausente y permite cambiarlo sin alterar la cita literal de la edición', () => {
		const datos = analizarEntrada(entrada('el-verdadero-amante')).datos!;
		const s = datos.segmentos.find((s) => s.ref === 't07')!;
		s.detalles_fuente = [];
		const c: EdicionFila = {
			tramo_ref: 't07',
			partes: [
				{
					v_ini: s.v_ini,
					v_fin: s.v_fin,
					identificacion: s.identificacion,
					nota: null,
					remate: { n_versos: 1 }
				}
			]
		};
		expect(
			aplicarEdiciones(datos, [c]).segmentos.find((s) => s.ref === 't07')!.detalles_fuente[0]
		).toMatchObject({ tipo_seccion: 'remate', n_versos: 1 });
		const cancion = datos.segmentos[1];
		const modificada = aplicarEdiciones(datos, [
			{
				tramo_ref: 't02',
				partes: [
					{
						v_ini: 221,
						v_fin: 287,
						identificacion: cancion.identificacion,
						nota: null,
						remate: { n_versos: 3 }
					}
				]
			}
		]);
		expect(modificada.segmentos[1].detalles_fuente[0].literal).toBe('remate final');
		expect(cancion.detalles_fuente[0].literal).toBe('pareado final');
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
