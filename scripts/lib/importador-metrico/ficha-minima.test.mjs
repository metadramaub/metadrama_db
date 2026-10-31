import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import {
	prepararFichaMinima,
	validarFichaMinima,
	crearCopiaConfirmada,
	resumirFichaMinima,
	huellaFichaMinima
} from './ficha-minima.mjs';

const read = (name) =>
	JSON.parse(
		readFileSync(
			new URL(`../../../docs/importador-metrico/piloto/${name}`, import.meta.url),
			'utf8'
		)
	);
const catalogo = {
	...read('catalogo-referencia.json'),
	generos: read('auditoria-flujo-2026-10-26.json')
		.vocabularios.filter((v) => v.categoria === 'genero')
		.map((v) => v.termino),
	metros: read('auditoria-campos-2026-10-22.json').metros_ejemplo.map((m) => m.slug),
	secciones: [
		...(read('catalogo-referencia.json').secciones ?? []),
		...read('auditoria-campos-2026-10-22.json').secciones_cancion
	]
};
const refs = [
	'el-molino',
	'el-verdadero-amante',
	'los-donaires-de-matico',
	'los-locos-de-valencia'
];
const preparar = (ref = 'el-verdadero-amante', opciones = {}) =>
	prepararFichaMinima(read(`normalizadas/${ref}.json`), {
		genero: 'comedia_o_tragicomedia',
		...opciones
	});
const actor = (extra = {}) => ({
	user_id: '00000000-0000-4000-8000-000000000001',
	rol: 'editor',
	activo: true,
	puede_importar_metrica: true,
	confirmado_en: '2026-10-26T12:00:00Z',
	...extra
});
const validar = (datos) => validarFichaMinima(datos, { catalogo });

describe('contrato local de la ficha mínima', () => {
	it('prepara las correspondencias de cuatro obras sin confirmarlas ni cambiar su entrada', () => {
		let total = 0,
			identificados = 0;
		for (const ref of refs) {
			const normalizada = read(`normalizadas/${ref}.json`);
			const antes = structuredClone(normalizada);
			const datos = prepararFichaMinima(normalizada, { genero: 'comedia_o_tragicomedia' });
			expect(normalizada).toEqual(antes);
			expect(validar(datos).errores).toEqual([]);
			const resumen = resumirFichaMinima(datos);
			total += resumen.extension;
			identificados += resumen.forma_identificada;
			expect(resumen.segmentacion_confirmada).toBe(false);
			expect(datos).not.toHaveProperty('confirmado_por');
		}
		expect(total).toBe(11754);
		expect(identificados).toBe(11473);
	});
	it('fecha y autor son obligatorios, sus fuentes no lo son', () => {
		const datos = preparar();
		delete datos.metadatos.fuente_fecha;
		delete datos.metadatos.fundamento_autoria;
		expect(validar(datos)).toMatchObject({
			errores: [],
			datos: {
				metadatos: {
					fuente_fecha: null,
					fundamento_autoria: null
				}
			}
		});
	});
	it.each(['titulo', 'autor_nombre', 'genero', 'edicion_base', 'fecha_inicio', 'fecha_fin'])(
		'rechaza el obligatorio ausente: %s',
		(campo) => {
			const datos = preparar();
			delete datos.metadatos[campo];
			expect(validar(datos).errores.length).toBeGreaterThan(0);
		}
	);
	it('no completa silenciosamente una fuente vacía con la edición', () => {
		const datos = preparar('el-verdadero-amante', { metadatos: { fuente_fecha: null } });
		expect(validar(datos).datos.metadatos.fuente_fecha).toBeNull();
	});
	it('no infiere género si no se ha seleccionado', () => {
		const datos = prepararFichaMinima(read('normalizadas/el-molino.json'));
		expect(validar(datos).errores.some((e) => e.ruta === 'metadatos.genero')).toBe(true);
	});
	it('comprueba géneros y metros, y conserva la asonancia declarada como rasgo del catálogo', () => {
		const datos = preparar('los-locos-de-valencia');
		datos.metadatos.genero = 'genero_inventado';
		datos.segmentos.find((s) => s.ref === 't13').desviaciones[0].metro_observado_slug =
			'metro_inventado';
		expect(validar(datos).errores.map((e) => e.codigo)).toEqual(
			expect.arrayContaining(['genero_desconocido', 'metro_desconocido'])
		);
		const asonancia = preparar()
			.segmentos.flatMap((s) => s.detalles_fuente)
			.find((d) => d.rasgo_slug === 'vocales_asonancia');
		expect(asonancia).toMatchObject({
			rasgo_slug: 'vocales_asonancia',
			valor_slug: 'i-o',
			literal: '-io'
		});
		expect(asonancia).not.toHaveProperty('estado');
		expect(asonancia).not.toHaveProperty('esquema_rima_id');
	});
	it.each(['estado', 'visible_publico', 'editor_asignado', 'confirmado_por', 'confianza'])(
		'no permite introducir un campo de otro recorrido: %s',
		(campo) => {
			const datos = preparar();
			datos[campo] = true;
			expect(validar(datos).errores.length).toBeGreaterThan(0);
		}
	);
	it('conserva Canción sin arquitectura y el remate declarado, sin crear unidades', () => {
		const datos = preparar();
		const s = datos.segmentos.find((s) => s.ref === 't02');
		expect(s.identificacion).toEqual({ forma_slug: 'cancion', arquitectura_slug: null });
		expect(s.detalles_fuente[0]).toMatchObject({
			tipo_seccion: 'remate',
			n_versos: 2,
			posicion: 'final'
		});
		expect(s).not.toHaveProperty('realizaciones');
		expect(validar(datos).errores).toEqual([]);
	});
	it('no convierte el remate en sección confirmada de una forma distinta', () => {
		const datos = preparar();
		datos.segmentos[1].identificacion.forma_slug = 'redondilla';
		expect(validar(datos).errores.some((e) => e.codigo === 'detalle_contexto')).toBe(true);
	});
	it('acepta el remate de un verso del terceto encadenado y rechaza convertirlo en cuatro', () => {
		const datos = preparar();
		const segmento = datos.segmentos.find((s) => s.ref === 't07');
		expect(segmento.identificacion).toEqual({
			forma_slug: 'terceto_encadenado',
			arquitectura_slug: null
		});
		expect(validar(datos).errores).toEqual([]);
		segmento.detalles_fuente[0].n_versos = 4;
		expect(validar(datos).errores.some((e) => e.codigo === 'detalle_contexto')).toBe(true);
	});
	it('los versos pendientes permanecen en el denominador del perfil', () => {
		const datos = preparar();
		datos.segmentos[0].identificacion = null;
		const resumen = resumirFichaMinima(datos);
		expect(resumen.forma_pendiente).toBe(220);
		expect(resumen.extension).toBe(2878);
		expect(resumen.perfil_formas.find((f) => f.forma_slug === 'cancion')).toEqual({
			forma_slug: 'cancion',
			versos: 67,
			proporcion_sobre_total: 67 / 2878
		});
		expect(resumen.perfil_formas.reduce((n, f) => n + f.versos, 0)).toBe(2658);
	});
	it('una letrilla con candidatas orientativas no se convierte en forma ni canto', () => {
		const datos = preparar('el-molino');
		const s = datos.segmentos.find((s) => s.origen.denominacion_literal === 'letrilla');
		expect(s.identificacion).toBeNull();
		expect(s.candidatas.length).toBeGreaterThan(1);
		expect(s).not.toHaveProperty('cantado');
		expect(resumirFichaMinima(datos).con_candidatas).toBeGreaterThan(0);
	});
	it('no exige aprobación por secuencia y rechaza una arquitectura ajena', () => {
		const datos = preparar();
		const s = datos.segmentos[1];
		expect(s).not.toHaveProperty('aprobacion');
		expect(validar(datos).errores).toEqual([]);
		s.identificacion.arquitectura_slug = 'arquitectura_inexistente';
		expect(validar(datos).errores.some((e) => e.codigo === 'arquitectura_ajena')).toBe(true);
	});
	it('permite candidatas de arquitectura sin perder la forma conocida', () => {
		const datos = preparar();
		const s = datos.segmentos[1];
		s.candidatas = [
			{
				forma_slug: 'cancion',
				arquitectura_slug: catalogo.formas.find((f) => f.slug === 'cancion').arquitecturas[0].slug
			}
		];
		expect(validar(datos).errores).toEqual([]);
		expect(resumirFichaMinima(datos).forma_identificada).toBe(2878);
		expect(resumirFichaMinima(datos).arquitectura_identificada).toBe(272);
	});
	it('rechaza conflictos, repeticiones y falsas candidatas de otra forma', () => {
		const datos = preparar();
		const s = datos.segmentos[1];
		s.candidatas = [datos.segmentos[0].identificacion, datos.segmentos[0].identificacion];
		const codigos = validar(datos).errores.map((e) => e.codigo);
		expect(codigos).toEqual(
			expect.arrayContaining(['candidata_repetida', 'candidatas_arquitectura'])
		);
	});
	it.each(['aprobacion', 'propuesta', 'exhaustividad', 'fundamento', 'confianza'])(
		'rechaza la categoría interna %s en una secuencia del contrato nuevo',
		(campo) => {
			const datos = preparar();
			datos.segmentos[0][campo] = 'inventado';
			expect(validar(datos).errores.length).toBeGreaterThan(0);
		}
	);
	it('conserva la nota particular sin copiar fundamentos generales ni aprobaciones', () => {
		const datos = preparar('los-locos-de-valencia');
		for (const s of datos.segmentos) {
			expect(s).not.toHaveProperty('fundamento');
			expect(s).not.toHaveProperty('aprobacion');
			expect(s.nota).toBeNull();
			for (const d of s.detalles_fuente) {
				expect(d).not.toHaveProperty('estado');
				expect(d).not.toHaveProperty('fundamento');
			}
		}
		const d = datos.segmentos.find((s) => s.ref === 't16').desviaciones[0];
		expect(d.nota).toBeTruthy();
		expect(d).not.toHaveProperty('fundamento');
	});
	it.each([
		[
			'hueco',
			(d) => {
				d.segmentos[1].v_ini += 1;
			}
		],
		[
			'solapamiento',
			(d) => {
				d.segmentos[1].v_ini -= 1;
			}
		],
		[
			'sin rango',
			(d) => {
				d.segmentos[1].v_ini = null;
			}
		],
		[
			'fuera de jornada',
			(d) => {
				d.segmentos[1].v_fin = 99999;
			}
		],
		[
			'identidad repetida',
			(d) => {
				d.segmentos[1].ref = d.segmentos[0].ref;
			}
		],
		[
			'fechas invertidas',
			(d) => {
				d.metadatos.fecha_fin = d.metadatos.fecha_inicio - 1;
			}
		],
		[
			'jornada repetida',
			(d) => {
				d.jornadas[1].numero = 1;
			}
		]
	])('rechaza %s antes de poder congelar la entrada', (_nombre, cambiar) => {
		const datos = preparar();
		cambiar(datos);
		expect(validar(datos).errores.length).toBeGreaterThan(0);
		expect(() => crearCopiaConfirmada(datos, actor(), { catalogo })).toThrow();
	});
	it('conserva las dos desviaciones sin descontar el verso añadido del pasaje', () => {
		const datos = preparar('los-locos-de-valencia');
		const redondillas = datos.segmentos.find((s) => s.ref === 't16');
		expect(redondillas.v_fin - redondillas.v_ini + 1).toBe(133);
		expect(redondillas.desviaciones[0]).toMatchObject({
			dimension: 'estructura',
			relacion_norma: 'sobra',
			v_ini: 2666,
			v_fin: 2666
		});
		expect(datos.segmentos.find((s) => s.ref === 't13').desviaciones[0]).toMatchObject({
			dimension: 'metro',
			metro_observado_slug: 'heptasilabo',
			v_ini: 2172
		});
		expect(resumirFichaMinima(datos).extension).toBe(3072);
	});
	it('rechaza desviación fuera de rango, sin nota y con relación de otra dimensión', () => {
		const datos = preparar('los-locos-de-valencia');
		const d = datos.segmentos.find((s) => s.ref === 't16').desviaciones[0];
		d.v_ini = 1;
		d.nota_ref = 'inventada';
		d.dimension = 'metro';
		expect(validar(datos).errores.map((e) => e.codigo)).toEqual(
			expect.arrayContaining(['desviacion_rango', 'desviacion_fuente', 'desviacion_dimension'])
		);
	});
});

describe('copia fija y contexto de confirmación', () => {
	it('la opción de vista previa nunca permite confirmar una copia incompleta', () => {
		const datos = preparar();
		datos.metadatos.fecha_inicio = null;
		expect(validarFichaMinima(datos, { catalogo, vistaPrevia: true }).errores).toEqual([]);
		expect(() => crearCopiaConfirmada(datos, actor(), { catalogo, vistaPrevia: true })).toThrow(
			/no confirmable/
		);
	});
	it('congela una copia independiente de las jornadas, secuencias y edición de trabajo', () => {
		const datos = preparar();
		const copia = crearCopiaConfirmada(datos, actor(), { catalogo });
		const antes = JSON.stringify(copia);
		datos.metadatos.edicion_base = 'Otra edición de prueba';
		datos.metadatos.fecha_inicio = 1600;
		datos.segmentos.splice(0);
		datos.jornadas.splice(0);
		expect(JSON.stringify(copia)).toBe(antes);
		expect(() => {
			copia.datos_confirmados.segmentos[0].v_fin = 1;
		}).toThrow();
		expect(copia.sha256_datos).toBe(huellaFichaMinima(copia.datos_confirmados));
	});
	it('la copia mantiene el mismo hash después de pasar por JSON y reordenar claves', () => {
		const copia = crearCopiaConfirmada(preparar(), actor(), { catalogo });
		const datos = JSON.parse(JSON.stringify(copia.datos_confirmados));
		const reordenados = Object.fromEntries(Object.entries(datos).reverse());
		expect(huellaFichaMinima(reordenados)).toBe(copia.sha256_datos);
		datos.metadatos.edicion_base += ' corregida';
		expect(huellaFichaMinima(datos)).not.toBe(copia.sha256_datos);
	});
	it.each(['admin', 'ip'])(
		'permite a %s sin necesitar la concesión específica de un editor',
		(rol) => {
			expect(
				crearCopiaConfirmada(preparar(), actor({ rol, puede_importar_metrica: false }), {
					catalogo
				}).confirmado_por
			).toBe(actor().user_id);
		}
	);
	it('permite al editor autorizado, sin asignación de obra ni acceso al laboratorio', () => {
		expect(crearCopiaConfirmada(preparar(), actor(), { catalogo })).toHaveProperty(
			'datos_confirmados'
		);
	});
	it.each([
		{ activo: false },
		{ puede_importar_metrica: false },
		{ rol: 'visitante' },
		{ user_id: 'inventado' }
	])('rechaza un contexto no autorizado o inválido: %j', (extra) => {
		expect(() => crearCopiaConfirmada(preparar(), actor(extra), { catalogo })).toThrow();
	});
	it('exige catálogo y no rellena una fecha de confirmación inexistente', () => {
		expect(() => crearCopiaConfirmada(preparar(), actor())).toThrow(/catálogo/);
		expect(() =>
			crearCopiaConfirmada(preparar(), actor({ confirmado_en: '2026-02-30T12:00:00Z' }), {
				catalogo
			})
		).toThrow();
	});
});

describe('CLI de preparación sin confirmación', () => {
	it.each([
		['--comprobar', 0],
		['--confirmar', 64],
		['--aplicar', 64]
	])('procesa %s sin activar una escritura en DB', (arg, codigo) => {
		const result = spawnSync(
			process.execPath,
			[
				fileURLToPath(new URL('../../importador-metrico/preparar-piloto.mjs', import.meta.url)),
				arg
			],
			{ encoding: 'utf8' }
		);
		expect(result.status, result.stderr).toBe(codigo);
		if (codigo === 0)
			expect(JSON.parse(result.stdout)).toMatchObject({
				obras: 4,
				posiciones_numeradas: 11754,
				forma_identificada: 11473,
				confirmaciones: 0
			});
	});
});
