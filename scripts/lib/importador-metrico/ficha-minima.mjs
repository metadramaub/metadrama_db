/** Contrato local de la ficha mínima. Sin DB, red, reloj ni escritura de archivos. */
import { createHash } from 'node:crypto';
import { z } from 'zod';

const texto = z.string().trim().min(1);
const entero = z.number().int().positive().max(2147483647);
const hash = z.string().regex(/^[a-f0-9]{64}$/);
const destino = z.object({ forma_slug: texto, arquitectura_slug: texto.nullable() }).strict();
const rango = { v_ini: entero, v_fin: entero };
const remate = z
	.object({
		literal: texto,
		dimension: z.literal('estructura'),
		tipo_seccion: z.literal('remate'),
		nombre: texto,
		n_versos: entero,
		posicion: z.literal('final')
	})
	.strict();
const detalleLiteral = z
	.object({
		literal: texto,
		dimension: z.literal('asonancia').optional()
	})
	.strict();
const rasgo = z.object({ literal: texto.optional(), rasgo_slug: texto, valor_slug: texto }).strict();
const detalle = z.union([remate, rasgo, detalleLiteral]);
const desviacion = z
	.object({
		...rango,
		dimension: z.enum(['metro', 'estructura']),
		relacion_norma: z.enum(['menor_que_norma', 'mayor_que_norma', 'sobra', 'falta', 'otra']),
		metro_observado_slug: texto.optional(),
		nota_ref: texto,
		texto_fuente: texto,
		nota: texto.nullable()
	})
	.strict();

/** Referencias nominales del piloto: todavía no resuelve UUID ni autorías de Supabase. */
export const fichaMinimaSchema = z
	.object({
		esquema: z.literal('versologia-ficha-minima/0.2'),
		obra_ref: texto,
		metadatos: z
			.object({
				titulo: texto,
				autor_nombre: texto,
				genero: texto,
				edicion_base: texto,
				fecha_inicio: entero,
				fecha_fin: entero,
				fuente_fecha: texto.nullable().default(null),
				fundamento_autoria: texto.nullable().default(null),
				observaciones: z.array(texto)
			})
			.strict(),
		jornadas: z
			.array(z.object({ numero: entero, ...rango, rotulo_literal: texto.nullable() }).strict())
			.min(1),
		segmentos: z
			.array(
				z
					.object({
						ref: texto,
						...rango,
						segmentacion: z.enum(['provisional', 'confirmada']),
						origen: z
							.object({
								tramo_ref: texto,
								denominacion_literal: texto.nullable(),
								fuente_id: texto,
								pagina: entero.nullable(),
								notas_ref: z.array(texto)
							})
							.strict(),
						identificacion: destino.nullable(),
						candidatas: z.array(destino),
						regla_id: texto.nullable(),
						nota: texto.nullable(),
						detalles_fuente: z.array(detalle),
						desviaciones: z.array(desviacion)
					})
					.strict()
			)
			.min(1),
		procedencia: z
			.object({
				reglas_version: texto,
				catalogo_revision: z.number().int().nonnegative(),
				extraccion_sha256: hash,
				entradas_sha256: z.record(texto, hash)
			})
			.strict()
	})
	.strict();

const error = (codigo, ruta, mensaje) => ({ codigo, ruta, mensaje });

/** Comprueba la representación, no decide equivalencias ni acepta una transcripción. */
export function validarFichaMinima(input, { catalogo } = {}) {
	const parsed = fichaMinimaSchema.safeParse(input);
	if (!parsed.success)
		return {
			datos: null,
			errores: parsed.error.issues.map((i) => error('formato', i.path.join('.'), i.message)),
			avisos: []
		};
	const datos = parsed.data;
	const errores = [];
	const avisos = [];
	const add = (codigo, ruta, mensaje) => errores.push(error(codigo, ruta, mensaje));
	if (datos.metadatos.fecha_inicio > datos.metadatos.fecha_fin)
		add('fechas_invertidas', 'metadatos', 'La fecha inicial supera la final.');
	const revisarParticion = (rows, path) => {
		const ids = new Set();
		for (const [i, row] of rows.entries()) {
			const id = row.ref ?? row.numero;
			if (ids.has(id)) add('identidad_repetida', `${path}.${i}`, 'Identificador repetido.');
			ids.add(id);
			if (row.v_fin < row.v_ini) add('rango_invertido', `${path}.${i}`, 'Rango invertido.');
			if (i && row.v_ini !== rows[i - 1].v_fin + 1)
				add(
					'particion',
					`${path}.${i}`,
					'Los rangos deben estar ordenados, sin huecos ni solapamientos.'
				);
		}
	};
	revisarParticion(datos.jornadas, 'jornadas');
	revisarParticion(datos.segmentos, 'segmentos');
	for (const [i, j] of datos.jornadas.entries()) {
		if (j.numero !== i + 1)
			add('orden_jornadas', `jornadas.${i}.numero`, 'Jornadas numeradas desde 1 y en orden.');
	}
	if (
		datos.jornadas[0].v_ini !== datos.segmentos[0].v_ini ||
		datos.jornadas.at(-1).v_fin !== datos.segmentos.at(-1).v_fin
	)
		add('ambito', 'segmentos', 'Jornadas y segmentos deben cubrir el mismo ámbito numerado.');
	const formas = catalogo ? new Map(catalogo.formas.map((f) => [f.slug, f])) : null;
	if (!formas)
		avisos.push(
			error('catalogo_pendiente', '', 'Falta comprobar las referencias con un catálogo.')
		);
	if (catalogo?.generos && !catalogo.generos.includes(datos.metadatos.genero))
		add(
			'genero_desconocido',
			'metadatos.genero',
			'El género no pertenece al catálogo de referencia.'
		);
	const revisarDestino = (target, ruta) => {
		if (!target || !formas) return;
		const forma = formas.get(target.forma_slug);
		if (!forma) add('forma_desconocida', ruta, `Forma ajena al catálogo: ${target.forma_slug}.`);
		else if (
			target.arquitectura_slug &&
			!forma.arquitecturas.some((a) => a.slug === target.arquitectura_slug)
		)
			add('arquitectura_ajena', ruta, 'La arquitectura no pertenece a la forma.');
	};
	for (const [i, s] of datos.segmentos.entries()) {
		const ruta = `segmentos.${i}`;
		if (datos.jornadas.filter((j) => s.v_ini >= j.v_ini && s.v_fin <= j.v_fin).length !== 1)
			add('jornada', ruta, 'El segmento debe quedar dentro de una sola jornada.');
		const destinos = [s.identificacion, ...s.candidatas];
		destinos.forEach((d) => revisarDestino(d, ruta));
		const unicas = new Set(s.candidatas.map((c) => JSON.stringify(c)));
		if (unicas.size !== s.candidatas.length) add('candidata_repetida', ruta, 'Candidata repetida.');
		if (
			s.identificacion &&
			s.candidatas.some((c) => c.forma_slug !== s.identificacion.forma_slug || !c.arquitectura_slug)
		)
			add(
				'candidatas_arquitectura',
				ruta,
				'Con forma identificada, las candidatas deben ser arquitecturas de esa forma.'
			);
		if (s.identificacion?.arquitectura_slug && s.candidatas.length)
			add(
				'arquitectura_resuelta',
				ruta,
				'Una arquitectura ya identificada no mantiene candidatas.'
			);
		for (const [k, d] of s.detalles_fuente.entries()) {
			if (d.rasgo_slug && (s.v_fin - s.v_ini + 1 < (d.rasgo_slug === 'distico_final' ? 2 : 1) ||
				!s.identificacion || (catalogo?.rasgos && !catalogo.rasgos.some((r) =>
					r.slug === d.rasgo_slug && r.valores.some((v) => v.slug === d.valor_slug) &&
					r.contextos.some((c) => c.forma === s.identificacion.forma_slug && (!c.valor_slug || c.valor_slug === d.valor_slug) &&
						(!s.identificacion.arquitectura_slug || c.arquitectura === s.identificacion.arquitectura_slug))))))
				add('rasgo_contexto', `${ruta}.detalles_fuente.${k}`, 'El rasgo y su valor deben corresponder a la forma y arquitectura conocidas.');
			if (d.tipo_seccion === 'remate' && d.n_versos > s.v_fin - s.v_ini + 1)
				add(
					'detalle_extension',
					`${ruta}.detalles_fuente.${k}`,
					'El detalle no puede ser más largo que su pasaje.'
				);
			if (
				d.tipo_seccion === 'remate' &&
				(!s.identificacion ||
					(catalogo?.secciones &&
						!catalogo.secciones.some(
							(seccion) =>
								seccion.forma === s.identificacion.forma_slug &&
								seccion.tipo_seccion === d.tipo_seccion &&
								(seccion.versos_min == null || d.n_versos >= seccion.versos_min) &&
								(seccion.versos_max == null || d.n_versos <= seccion.versos_max) &&
								(!s.identificacion.arquitectura_slug ||
									seccion.arquitectura === s.identificacion.arquitectura_slug)
						)))
			)
				add(
					'detalle_contexto',
					`${ruta}.detalles_fuente.${k}`,
					'La sección debe corresponder a la forma y arquitectura conocidas.'
				);
		}
		for (const [k, d] of s.desviaciones.entries()) {
			if (d.v_ini > d.v_fin || d.v_ini < s.v_ini || d.v_fin > s.v_fin)
				add(
					'desviacion_rango',
					`${ruta}.desviaciones.${k}`,
					'Desviación fuera del rango o invertida.'
				);
			if (!s.origen.notas_ref.includes(d.nota_ref))
				add(
					'desviacion_fuente',
					`${ruta}.desviaciones.${k}`,
					'La nota de desviación no está vinculada a la fila.'
				);
			if (
				d.metro_observado_slug &&
				catalogo?.metros &&
				!catalogo.metros.includes(d.metro_observado_slug)
			)
				add('metro_desconocido', `${ruta}.desviaciones.${k}`, 'Metro observado ajeno al catálogo.');
			if (
				(d.dimension === 'metro' && ['sobra', 'falta'].includes(d.relacion_norma)) ||
				(d.dimension === 'estructura' &&
					['menor_que_norma', 'mayor_que_norma'].includes(d.relacion_norma))
			)
				add(
					'desviacion_dimension',
					`${ruta}.desviaciones.${k}`,
					'La relación no corresponde a esa dimensión.'
				);
		}
	}
	if (datos.segmentos.some((s) => s.segmentacion === 'provisional'))
		avisos.push(
			error(
				'segmentacion_provisional',
				'segmentos',
				'Los bloques no certifican aún el número de secuencias métricas ni las transiciones.'
			)
		);
	if (datos.segmentos.some((s) => !s.identificacion))
		avisos.push(
			error(
				'forma_pendiente',
				'segmentos',
				'Hay versos sin forma identificada; se conservan en el denominador.'
			)
		);
	return { datos, errores, avisos };
}

/** Prepara correspondencias para revisar. No confirma la importación ni revisa las reglas generales. */
export function prepararFichaMinima(normalizada, { genero, metadatos = {} } = {}) {
	if (normalizada.esquema !== 'versologia-normalizacion-local/0.1')
		throw new Error('Formato de normalización no admitido');
	const m = normalizada.metadatos ?? {};
	return {
		esquema: 'versologia-ficha-minima/0.2',
		obra_ref: normalizada.obra_ref,
		metadatos: {
			titulo: m.titulo,
			autor_nombre: m.autoria,
			genero,
			edicion_base: m.edicion_base,
			fecha_inicio: m.fecha_inicio,
			fecha_fin: m.fecha_fin,
			fuente_fecha: m.fuente_fecha ?? null,
			fundamento_autoria: null,
			observaciones: structuredClone(m.observaciones ?? []),
			...metadatos
		},
		jornadas: normalizada.jornadas.map((j) => ({
			numero: j.numero,
			v_ini: j.v_ini,
			v_fin: j.v_fin,
			rotulo_literal: j.rotulo_literal
		})),
		segmentos: normalizada.segmentos.map((s) => ({
			ref: s.id,
			v_ini: s.v_ini,
			v_fin: s.v_fin,
			segmentacion: 'provisional',
			origen: {
				tramo_ref: s.fuente.id,
				denominacion_literal: s.fuente.denominacion_literal,
				fuente_id: s.fuente.fuente_id,
				pagina: s.fuente.pagina,
				notas_ref: structuredClone(s.fuente.notas_ref)
			},
			identificacion: structuredClone(s.identificacion_revisada ?? s.propuesta),
			candidatas: structuredClone(s.candidatas),
			regla_id: s.regla_id,
			nota: null,
			detalles_fuente: s.detalles_fuente.map((d) =>
				d.tipo_seccion === 'remate'
					? {
							literal: d.literal,
							dimension: d.dimension,
							tipo_seccion: d.tipo_seccion,
							nombre: d.nombre,
							n_versos: d.n_versos,
							posicion: d.posicion
						}
					: d.rasgo_slug
						? { literal: d.literal, rasgo_slug: d.rasgo_slug, valor_slug: d.valor_slug }
						: { literal: d.literal, ...(d.dimension ? { dimension: d.dimension } : {}) }
			),
			desviaciones: s.desviaciones.map(({ fundamento, ...d }) => ({
				...structuredClone(d),
				nota: fundamento ?? null
			}))
		})),
		procedencia: {
			reglas_version: normalizada.reglas_version,
			catalogo_revision: normalizada.catalogo_referencia.estado.revision,
			extraccion_sha256: normalizada.revision_transcripcion?.sha256,
			entradas_sha256: structuredClone(normalizada.entradas_sha256)
		}
	};
}

/** Orden de claves estable también después de almacenar el documento como JSONB. */
export function serializarCanonico(value) {
	if (Array.isArray(value)) return `[${value.map(serializarCanonico).join(',')}]`;
	if (value !== null && typeof value === 'object')
		return `{${Object.keys(value)
			.filter((key) => value[key] !== undefined)
			.sort()
			.map((key) => `${JSON.stringify(key)}:${serializarCanonico(value[key])}`)
			.join(',')}}`;
	return JSON.stringify(value);
}
export const huellaFichaMinima = (datos) =>
	createHash('sha256').update(serializarCanonico(datos)).digest('hex');

function congelar(value) {
	if (value !== null && typeof value === 'object') {
		Object.values(value).forEach(congelar);
		Object.freeze(value);
	}
	return value;
}

/** El contexto se obtendrá de la sesión en el servidor, nunca del JSON pegado por la persona. */
export function crearCopiaConfirmada(input, contexto, opciones = {}) {
	const actor = z
		.object({
			user_id: z.uuid(),
			rol: z.enum(['admin', 'ip', 'editor']),
			activo: z.boolean(),
			puede_importar_metrica: z.boolean(),
			confirmado_en: z.iso.datetime({ offset: true })
		})
		.strict()
		.parse(contexto);
	if (!actor.activo || (actor.rol === 'editor' && !actor.puede_importar_metrica))
		throw new Error('La sesión no tiene permiso de importación');
	if (!opciones.catalogo) throw new Error('Es necesario comprobar las referencias del catálogo');
	if (!opciones.catalogo.generos) throw new Error('Falta el catálogo de géneros');
	const result = validarFichaMinima(input, opciones);
	if (result.errores.length)
		throw new Error(`Ficha mínima no confirmable: ${JSON.stringify(result.errores)}`);
	if (
		!opciones.catalogo.metros &&
		result.datos.segmentos.some((s) => s.desviaciones.some((d) => d.metro_observado_slug))
	)
		throw new Error('Falta el catálogo de metros observados');
	if (
		!opciones.catalogo.secciones &&
		result.datos.segmentos.some((s) => s.detalles_fuente.some((d) => d.tipo_seccion === 'remate'))
	)
		throw new Error('Falta el catálogo de secciones declaradas');
	if (!opciones.catalogo.rasgos && result.datos.segmentos.some((s) => s.detalles_fuente.some((d) => d.rasgo_slug)))
		throw new Error('Falta el catálogo de rasgos declarados');
	const datos = JSON.parse(JSON.stringify(result.datos));
	return congelar({
		esquema: 'versologia-copia-minima/0.2',
		datos_confirmados: datos,
		sha256_datos: huellaFichaMinima(datos),
		confirmado_por: actor.user_id,
		confirmado_en: actor.confirmado_en
	});
}

/** Perfil del resultado preparado o confirmado; solo una confirmación habilita su uso en el corpus. */
export function resumirFichaMinima(input) {
	const result = validarFichaMinima(input);
	if (result.errores.length) throw new Error('No se resumen datos con errores estructurales');
	const datos = result.datos;
	const total = datos.segmentos.reduce((n, s) => n + s.v_fin - s.v_ini + 1, 0);
	const formas = new Map();
	let forma = 0,
		arquitectura = 0,
		candidatas = 0;
	for (const s of datos.segmentos) {
		const n = s.v_fin - s.v_ini + 1;
		if (s.identificacion) {
			forma += n;
			if (s.identificacion.arquitectura_slug) arquitectura += n;
			const slug = s.identificacion.forma_slug;
			formas.set(slug, (formas.get(slug) ?? 0) + n);
		} else if (s.candidatas.length) candidatas += n;
	}
	return {
		denominador: 'posiciones_numeradas',
		extension: total,
		jornadas: datos.jornadas.length,
		bloques: datos.segmentos.length,
		segmentacion_confirmada: datos.segmentos.every((s) => s.segmentacion === 'confirmada'),
		forma_identificada: forma,
		arquitectura_identificada: arquitectura,
		forma_pendiente: total - forma,
		con_candidatas: candidatas,
		sin_identificacion: total - forma - candidatas,
		perfil_formas: [...formas]
			.sort(([a], [b]) => a.localeCompare(b))
			.map(([forma_slug, versos]) => ({
				forma_slug,
				versos,
				proporcion_sobre_total: versos / total
			}))
	};
}
