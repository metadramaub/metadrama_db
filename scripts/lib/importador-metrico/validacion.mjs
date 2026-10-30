/** Validación técnica del intercambio 0.1. Sin archivos, red, catálogo ni escrituras. */
import { z } from 'zod';

const texto = z.string().regex(/\S/, 'Debe contener texto');
const entero = z.number().int().positive().max(Number.MAX_SAFE_INTEGER);
const listaRefs = z.array(texto);
const fechaISO = z
	.string()
	.regex(/^\d{4}-\d{2}-\d{2}$/)
	.refine((value) => {
		const date = new Date(`${value}T00:00:00.000Z`);
		return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
	}, 'Fecha inexistente');

export const extraccionSchema = z
	.object({
		esquema: z.literal('versologia-extraccion/0.1'),
		obra_ref: texto,
		// Este intercambio es una extracción inicial. No define la futura promoción a gold.
		estado_revision: z.literal('borrador_ia'),
		revision_humana: z
			.object({
				responsable: z.null(),
				fecha: z.null(),
				resultado: z.literal('pendiente')
			})
			.strict(),
		procedencia: z
			.object({
				fecha: fechaISO.nullable(),
				procedimiento: z.enum(['lectura_visual_asistida', 'ejecucion_prompt']),
				generador: texto.nullable(),
				modelo: texto.nullable(),
				prompt_version: texto,
				ensayo_controlado: z.boolean()
			})
			.strict(),
		metadatos: z
			.object({
				titulo: texto.nullable(),
				autoria: texto.nullable(),
				genero_literal: texto.nullable(),
				fecha_inicio: entero.nullable(),
				fecha_fin: entero.nullable(),
				fuente_fecha: texto.nullable(),
				edicion_base: texto.nullable(),
				observaciones: z.array(texto),
				fuente_id: texto.nullable(),
				autoria_procedencia: texto.optional(),
				bloque_docx_literal: z.array(texto).optional()
			})
			.strict()
			.nullable(),
		jornadas: z.array(z.object({ numero: entero, rotulo_literal: texto.nullable() }).strict()),
		tramos: z.array(
			z
				.object({
					id: texto,
					jornada: entero.nullable(),
					v_ini: entero.nullable(),
					v_fin: entero.nullable(),
					denominacion_literal: texto.nullable(),
					n_versos_fuente: entero.nullable(),
					fuente_id: texto.nullable(),
					pagina: entero.nullable(),
					notas_ref: listaRefs
				})
				.strict()
		),
		notas: z.array(
			z
				.object({
					id: texto,
					marca: texto.nullable(),
					texto_literal: texto.nullable(),
					fuente_id: texto.nullable(),
					pagina: entero.nullable(),
					tramos_ref: listaRefs,
					v_ini: entero.nullable(),
					v_fin: entero.nullable()
				})
				.strict()
		),
		resumen_fuente: z.array(
			z
				.object({
					denominacion_literal: texto.nullable(),
					n_versos_fuente: entero.nullable(),
					porcentaje_literal: z
						.string()
						.regex(/^\d+(,\d+)?$/)
						.nullable(),
					fuente_id: texto.nullable(),
					pagina: entero.nullable()
				})
				.strict()
		),
		incidencias: z.array(
			z
				.object({
					tipo: texto,
					descripcion: texto,
					fuente_id: texto.nullable(),
					tramos_ref: listaRefs
				})
				.strict()
		)
	})
	.strict();

const manifiestoSchema = z
	.object({
		documento_metadatos: z.object({ id: texto }).passthrough(),
		fotografias: z.array(
			z
				.object({
					id: texto,
					obra_ref: texto,
					pagina_visible: entero.nullable()
				})
				.passthrough()
		)
	})
	.passthrough();

const opcionesSchema = z
	.object({
		fuentes: manifiestoSchema.optional(),
		resumenCompleto: z.boolean().optional(),
		rangoEsperado: z
			.object({ v_ini: entero, v_fin: entero })
			.strict()
			.refine((rango) => rango.v_ini <= rango.v_fin, 'Rango esperado invertido')
			.optional()
	})
	.strict();

function informeVacio() {
	return {
		esquema: 'versologia-validacion-tecnica/0.1',
		estructura_valida: false,
		alcance:
			'Comprobación técnica; no normaliza, no corrige y no certifica cotejo humano ni aptitud analítica.',
		errores: [],
		advertencias: [],
		pendientes: [],
		informacion: [],
		datos_calculados: null
	};
}

function anotar(informe, nivel, codigo, ruta, mensaje, detalles) {
	informe[nivel].push({ codigo, ruta, mensaje, ...(detalles === undefined ? {} : { detalles }) });
}

function erroresDeEsquema(informe, resultado, prefijo = '') {
	for (const issue of resultado.error.issues)
		anotar(
			informe,
			'errores',
			'formato_invalido',
			[prefijo, ...issue.path.map(String)].filter(Boolean).join('.'),
			issue.code === 'invalid_type' && issue.expected === 'number'
				? issue.path.at(-1) === 'numero'
					? 'Debe ser un número entero sin comillas.'
					: 'Debe ser un número entero sin comillas, o null si no consta.'
				: issue.message
		);
}

function duplicados(informe, values, ruta) {
	const vistos = new Set();
	for (const value of values) {
		if (vistos.has(value))
			anotar(informe, 'errores', 'referencia_duplicada', ruta, `Referencia repetida: ${value}`, {
				referencia: value
			});
		vistos.add(value);
	}
}

function rangoValido(row) {
	return row.v_ini !== null && row.v_fin !== null && row.v_ini <= row.v_fin;
}

/** Intervalos inclusivos: unión y solapamiento se calculan sin enumerar versos. */
function intervalos(rows) {
	const ordenados = [...rows].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	const union = [];
	let suma = 0n;
	for (const row of ordenados) {
		suma += BigInt(row.v_fin) - BigInt(row.v_ini) + 1n;
		const ultimo = union.at(-1);
		if (ultimo && BigInt(row.v_ini) <= BigInt(ultimo.v_fin) + 1n) {
			ultimo.v_fin = Math.max(ultimo.v_fin, row.v_fin);
		} else union.push({ v_ini: row.v_ini, v_fin: row.v_fin });
	}
	const cubiertos = union.reduce((n, row) => n + BigInt(row.v_fin) - BigInt(row.v_ini) + 1n, 0n);
	const huecos = union
		.slice(1)
		.map((row, i) => ({ v_ini: union[i].v_fin + 1, v_fin: row.v_ini - 1 }));
	return { union, suma, cubiertos, repetidos: suma - cubiertos, huecos };
}

/** Analiza un objeto ya parseado. Nunca modifica el objeto recibido. */
export function validarExtraccion(entrada, opciones = {}) {
	const informe = informeVacio();
	const parsed = extraccionSchema.safeParse(entrada);
	if (!parsed.success) {
		erroresDeEsquema(informe, parsed);
		return informe;
	}
	informe.estructura_valida = true;
	const contexto = opcionesSchema.safeParse(opciones);
	if (!contexto.success) {
		erroresDeEsquema(informe, contexto, 'opciones');
		return informe;
	}
	const obra = parsed.data;
	const { fuentes, resumenCompleto = false, rangoEsperado } = contexto.data;
	const add = (nivel, codigo, ruta, mensaje, detalles) =>
		anotar(informe, nivel, codigo, ruta, mensaje, detalles);
	add(
		'pendientes',
		'cotejo_humano_pendiente',
		'revision_humana',
		'Los controles técnicos no sustituyen el cotejo de la extracción.'
	);
	if (!fuentes)
		add(
			'pendientes',
			'fuentes_no_contrastadas',
			'fuente_id',
			'No se ha aportado un manifiesto para contrastar identificadores y páginas.'
		);
	const fotos = new Map(fuentes?.fotografias.map((foto) => [foto.id, foto]) ?? []);
	if (fuentes)
		duplicados(
			informe,
			[fuentes.documento_metadatos.id, ...fuentes.fotografias.map((foto) => foto.id)],
			'opciones.fuentes'
		);
	function comprobarFoto(id, pagina, ruta) {
		if (id === null) {
			add(
				'pendientes',
				'fuente_no_identificada',
				`${ruta}.fuente_id`,
				'Falta identificar la fotografía de procedencia.'
			);
			return;
		}
		if (!fuentes) return;
		const foto = fotos.get(id);
		if (!foto)
			add('errores', 'fuente_desconocida', `${ruta}.fuente_id`, `Fotografía no registrada: ${id}`);
		else if (foto.obra_ref !== obra.obra_ref)
			add(
				'errores',
				'fuente_de_otra_obra',
				`${ruta}.fuente_id`,
				`La fotografía pertenece a ${foto.obra_ref}.`
			);
		else if (pagina !== null && foto.pagina_visible !== null && pagina !== foto.pagina_visible) {
			add(
				'advertencias',
				'pagina_discrepante',
				`${ruta}.pagina`,
				'La página difiere de la registrada en el manifiesto.',
				{ transcrita: pagina, manifiesto: foto.pagina_visible }
			);
		}
	}
	const meta = obra.metadatos;
	if (!meta)
		add('pendientes', 'metadatos_ausentes', 'metadatos', 'Faltan los metadatos de la obra.');
	else {
		for (const key of [
			'titulo',
			'autoria',
			'fecha_inicio',
			'fecha_fin',
			'fuente_fecha',
			'edicion_base',
			'fuente_id'
		]) {
			if (meta[key] === null)
				add(
					'pendientes',
					'metadato_pendiente',
					`metadatos.${key}`,
					'Dato mínimo no aportado; no se completa por conjetura.'
				);
		}
		if (
			meta.fecha_inicio !== null &&
			meta.fecha_fin !== null &&
			meta.fecha_inicio > meta.fecha_fin
		) {
			add(
				'advertencias',
				'fechas_invertidas',
				'metadatos',
				'La fecha inicial es posterior a la final. Se conservan ambas.'
			);
		}
		if (fuentes && meta.fuente_id !== null && meta.fuente_id !== fuentes.documento_metadatos.id) {
			add(
				'errores',
				'fuente_metadatos_desconocida',
				'metadatos.fuente_id',
				'El documento de metadatos no coincide con el manifiesto.'
			);
		}
	}
	duplicados(
		informe,
		obra.jornadas.map((row) => row.numero),
		'jornadas'
	);
	duplicados(
		informe,
		obra.tramos.map((row) => row.id),
		'tramos'
	);
	duplicados(
		informe,
		obra.notas.map((row) => row.id),
		'notas'
	);
	const jornadas = new Set(obra.jornadas.map((row) => row.numero));
	const tramos = new Map(obra.tramos.map((row) => [row.id, row]));
	const notas = new Map(obra.notas.map((row) => [row.id, row]));
	if (!obra.tramos.length)
		add('pendientes', 'sin_tramos', 'tramos', 'No hay filas métricas transcritas.');
	if (!obra.jornadas.length)
		add('pendientes', 'sin_jornadas', 'jornadas', 'No hay jornadas identificadas.');
	obra.jornadas.forEach((row, i) => {
		if (!obra.tramos.some((tramo) => tramo.jornada === row.numero))
			add(
				'pendientes',
				'jornada_sin_tramos',
				`jornadas.${i}`,
				'No se han vinculado filas a esta jornada.'
			);
		if (row.rotulo_literal === null)
			add(
				'pendientes',
				'encabezamiento_pendiente',
				`jornadas.${i}.rotulo_literal`,
				'Encabezamiento no transcrito.'
			);
	});
	obra.tramos.forEach((row, i) => {
		const ruta = `tramos.${i}`;
		comprobarFoto(row.fuente_id, row.pagina, ruta);
		if (row.jornada === null)
			add(
				'pendientes',
				'jornada_pendiente',
				`${ruta}.jornada`,
				'No se ha identificado la jornada de esta fila.'
			);
		else if (!jornadas.has(row.jornada))
			add(
				'errores',
				'jornada_desconocida',
				`${ruta}.jornada`,
				'La jornada no tiene encabezamiento registrado.'
			);
		if (row.denominacion_literal === null || row.denominacion_literal?.includes('[ilegible]')) {
			add(
				'pendientes',
				'denominacion_pendiente',
				`${ruta}.denominacion_literal`,
				'Denominación no transcrita por completo.'
			);
		}
		if (row.v_ini === null || row.v_fin === null)
			add(
				'pendientes',
				'rango_pendiente',
				ruta,
				'Falta un extremo del rango; la cobertura global no puede cerrarse.'
			);
		else if (!rangoValido(row))
			add(
				'advertencias',
				'rango_invertido',
				ruta,
				'El rango termina antes de empezar; no se intercambian sus extremos.'
			);
		if (row.n_versos_fuente === null)
			add(
				'informacion',
				'recuento_no_aportado',
				`${ruta}.n_versos_fuente`,
				'No hay recuento declarado. Un rango legible sigue permitiendo calcular su extensión.'
			);
		else if (rangoValido(row) && row.v_fin - row.v_ini + 1 !== row.n_versos_fuente) {
			add(
				'advertencias',
				'recuento_discrepante',
				`${ruta}.n_versos_fuente`,
				'El recuento declarado difiere del rango inclusivo.',
				{ declarado: row.n_versos_fuente, calculado: row.v_fin - row.v_ini + 1 }
			);
		}
		duplicados(informe, row.notas_ref, `${ruta}.notas_ref`);
		for (const id of row.notas_ref) {
			if (!notas.has(id))
				add('errores', 'nota_desconocida', `${ruta}.notas_ref`, `No existe la nota ${id}.`);
			else if (!notas.get(id).tramos_ref.includes(row.id))
				add(
					'errores',
					'enlace_nota_no_reciproco',
					`${ruta}.notas_ref`,
					`La nota ${id} no enlaza esta fila.`
				);
		}
		const prev = obra.tramos[i - 1];
		if (
			prev &&
			((prev.v_ini !== null && row.v_ini !== null && prev.v_ini > row.v_ini) ||
				(prev.jornada !== null && row.jornada !== null && prev.jornada > row.jornada))
		) {
			add(
				'advertencias',
				'orden_discrepante',
				ruta,
				'El orden transcrito retrocede en versos o jornadas; se conserva para cotejarlo.'
			);
		}
	});
	obra.notas.forEach((row, i) => {
		const ruta = `notas.${i}`;
		comprobarFoto(row.fuente_id, row.pagina, ruta);
		duplicados(informe, row.tramos_ref, `${ruta}.tramos_ref`);
		if (!row.tramos_ref.length)
			add(
				'pendientes',
				'nota_sin_tramos',
				ruta,
				'La nota todavía no se ha vinculado con ninguna fila.'
			);
		if (row.texto_literal === null || row.texto_literal?.includes('[ilegible]'))
			add(
				'pendientes',
				'nota_ilegible',
				`${ruta}.texto_literal`,
				'La nota no está transcrita por completo.'
			);
		for (const id of row.tramos_ref) {
			if (!tramos.has(id))
				add('errores', 'tramo_desconocido', `${ruta}.tramos_ref`, `No existe la fila ${id}.`);
			else if (!tramos.get(id).notas_ref.includes(row.id))
				add(
					'errores',
					'enlace_tramo_no_reciproco',
					`${ruta}.tramos_ref`,
					`La fila ${id} no enlaza esta nota.`
				);
		}
		if ((row.v_ini === null) !== (row.v_fin === null))
			add('pendientes', 'rango_nota_parcial', ruta, 'Localizador de nota parcialmente transcrito.');
		else if (row.v_ini !== null && !rangoValido(row))
			add(
				'advertencias',
				'rango_nota_invertido',
				ruta,
				'El localizador de la nota está invertido.'
			);
		else if (row.v_ini !== null) {
			const ligados = row.tramos_ref
				.map((id) => tramos.get(id))
				.filter((tramo) => tramo && rangoValido(tramo));
			const cobertura = intervalos(ligados).union;
			if (
				ligados.length === row.tramos_ref.length &&
				row.tramos_ref.length &&
				!cobertura.some((rango) => rango.v_ini <= row.v_ini && rango.v_fin >= row.v_fin)
			) {
				add(
					'advertencias',
					'nota_fuera_de_tramos',
					ruta,
					'El localizador de la nota no está cubierto por los tramos enlazados.'
				);
			}
		}
	});
	obra.incidencias.forEach((row, i) => {
		if (row.fuente_id !== null) comprobarFoto(row.fuente_id, null, `incidencias.${i}`);
		for (const id of row.tramos_ref)
			if (!tramos.has(id))
				add(
					'errores',
					'tramo_desconocido',
					`incidencias.${i}.tramos_ref`,
					`No existe la fila ${id}.`
				);
	});
	const validos = obra.tramos.filter(rangoValido);
	const conocidos = intervalos(validos);
	const todosLosRangos = obra.tramos.length > 0 && validos.length === obra.tramos.length;
	const numeroSeguro = (value) => {
		if (value <= BigInt(Number.MAX_SAFE_INTEGER)) return Number(value);
		add(
			'errores',
			'conteo_fuera_de_limite',
			'tramos',
			'El agregado excede el rango de enteros exactos; no se devuelve una cifra imprecisa.'
		);
		return null;
	};
	const cubiertos = numeroSeguro(conocidos.cubiertos);
	const suma = numeroSeguro(conocidos.suma);
	const repetidos = numeroSeguro(conocidos.repetidos);
	if (conocidos.repetidos > 0n)
		add(
			'advertencias',
			'solapamiento',
			'tramos',
			'Hay versos cubiertos más de una vez entre los rangos conocidos.',
			{ versos_repetidos: repetidos }
		);
	for (const hueco of conocidos.huecos)
		add(
			'advertencias',
			todosLosRangos ? 'hueco' : 'hueco_entre_rangos_conocidos',
			'tramos',
			todosLosRangos
				? 'Hay un hueco entre rangos transcritos.'
				: 'Hay un hueco entre rangos conocidos; podría estar cubierto por filas cuyo rango falta.',
			hueco
		);
	if (rangoEsperado && todosLosRangos) {
		if (
			conocidos.union.some(
				(row) => row.v_ini < rangoEsperado.v_ini || row.v_fin > rangoEsperado.v_fin
			)
		) {
			add(
				'advertencias',
				'rango_fuera_del_esperado',
				'tramos',
				'Hay versos fuera del intervalo esperado, que no se recortan.'
			);
		}
		if (
			conocidos.union[0].v_ini !== rangoEsperado.v_ini ||
			conocidos.union.at(-1).v_fin !== rangoEsperado.v_fin
		) {
			add(
				'advertencias',
				'extremos_incompletos',
				'tramos',
				'Los extremos conocidos no coinciden con el rango esperado.'
			);
		}
	}
	if (!rangoEsperado)
		add(
			'informacion',
			'extremos_no_contrastados',
			'tramos',
			'Sin rango esperado no se puede detectar la falta de versos al principio o al final de las fotos.'
		);
	obra.resumen_fuente.forEach((row, i) => {
		comprobarFoto(row.fuente_id, row.pagina, `resumen_fuente.${i}`);
		if (row.porcentaje_literal !== null && Number(row.porcentaje_literal.replace(',', '.')) > 100) {
			add(
				'advertencias',
				'porcentaje_fuera_de_rango',
				`resumen_fuente.${i}.porcentaje_literal`,
				'El porcentaje impreso es mayor que 100; se conserva.'
			);
		}
	});
	let totalResumen = null;
	if (
		obra.resumen_fuente.length &&
		obra.resumen_fuente.every((row) => row.n_versos_fuente !== null)
	) {
		totalResumen = numeroSeguro(
			obra.resumen_fuente.reduce((n, row) => n + BigInt(row.n_versos_fuente), 0n)
		);
	}
	if (resumenCompleto) {
		if (!obra.resumen_fuente.length || totalResumen === null)
			add(
				'pendientes',
				'resumen_incompleto',
				'resumen_fuente',
				'Se pidió contrastar un resumen completo, pero faltan filas o recuentos.'
			);
		else if (!todosLosRangos || conocidos.repetidos > 0n || conocidos.huecos.length)
			add(
				'pendientes',
				'resumen_no_comparable',
				'resumen_fuente',
				'Los rangos no permiten contrastar una extensión completa sin duplicados ni huecos.'
			);
		else if (totalResumen !== cubiertos)
			add(
				'advertencias',
				'total_resumen_discrepante',
				'resumen_fuente',
				'El resumen declarado completo difiere de la cobertura de los rangos.',
				{ resumen: totalResumen, rangos: cubiertos }
			);
	} else if (obra.resumen_fuente.length)
		add(
			'informacion',
			'alcance_resumen_no_declarado',
			'resumen_fuente',
			'No se presupone que las filas de resumen aportadas cubran toda la obra. No se agrupan etiquetas por conjetura.'
		);
	informe.datos_calculados = {
		tramos: obra.tramos.length,
		tramos_con_rango_valido: validos.length,
		todos_los_rangos_transcritos: todosLosRangos,
		versos_union_conocida: cubiertos,
		versos_suma_rangos_conocidos: suma,
		versos_repetidos_conocidos: repetidos,
		huecos_entre_rangos_conocidos: conocidos.huecos,
		extremos: conocidos.union.length
			? { v_ini: conocidos.union[0].v_ini, v_fin: conocidos.union.at(-1).v_fin }
			: null,
		extremos_contrastados: Boolean(rangoEsperado && todosLosRangos),
		total_resumen_aportado: totalResumen,
		manifiesto_aportado: Boolean(fuentes)
	};
	return informe;
}

export function validarTextoExtraccion(textoEntrada, opciones = {}) {
	let entrada;
	try {
		if (typeof textoEntrada !== 'string') throw new Error('Se esperaba texto JSON');
		// Se tolera BOM UTF-8, pero no se extrae un JSON escondido entre prosa o bloques de código.
		entrada = JSON.parse(textoEntrada.replace(/^\uFEFF/, ''));
	} catch {
		const informe = informeVacio();
		anotar(
			informe,
			'errores',
			'json_invalido',
			'',
			'No es un JSON válido. Pega solo el objeto, sin prosa ni cercas de Markdown.'
		);
		return informe;
	}
	return validarExtraccion(entrada, opciones);
}

export function codigoSalida(informe) {
	return informe.errores.length ? 1 : informe.advertencias.length ? 2 : 0;
}
