/** Cotejo de respuestas sin corregirlas. No puntúa interpretaciones métricas ni estima probabilidades. */
import { extraccionSchema, validarTextoExtraccion } from './validacion.mjs';
const normalizar = (v) =>
	typeof v === 'string' ? v.normalize('NFC').replace(/\s+/gu, ' ').trim() : v;
const igual = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const camposNumericos = new Set([
	'fecha_inicio',
	'fecha_fin',
	'numero',
	'jornada',
	'v_ini',
	'v_fin',
	'n_versos_fuente',
	'pagina'
]);
const comparar = (esperada, obtenida, campos, ruta, diferencias, diferenciasFormato) => {
	for (const campo of campos)
		if (!igual(normalizar(esperada?.[campo]), normalizar(obtenida?.[campo]))) {
			const soloTipo =
				camposNumericos.has(campo) &&
				typeof esperada?.[campo] === 'number' &&
				typeof obtenida?.[campo] === 'string' &&
				/^\d+$/.test(obtenida[campo]) &&
				Number(obtenida[campo]) === esperada[campo];
			(soloTipo ? diferenciasFormato : diferencias).push({
				ruta: `${ruta}.${campo}`,
				esperado: esperada?.[campo] ?? null,
				obtenido: obtenida?.[campo] ?? null
			});
		}
};
export function evaluarRespuestaModelo(texto, gold) {
	const limpio = texto.trim();
	const bloque = /^```(?:json)?\s*\n([\s\S]*?)\n```$/i.exec(limpio);
	let respuesta;
	try {
		respuesta = JSON.parse(bloque ? bloque[1] : limpio);
	} catch {
		return {
			json_valido: false,
			estructura_valida: false,
			lista_para_importar_sin_corregir: false,
			motivo: 'json_no_interpretable'
		};
	}
	const schema = extraccionSchema.safeParse(respuesta);
	const diferencias = [];
	const diferenciasFormato = [];
	comparar(
		gold.metadatos,
		respuesta.metadatos,
		[
			'titulo',
			'autoria',
			'genero_literal',
			'fecha_inicio',
			'fecha_fin',
			'fuente_fecha',
			'edicion_base',
			'observaciones',
			'fuente_id',
			'autoria_procedencia',
			'bloque_docx_literal'
		],
		'metadatos',
		diferencias,
		diferenciasFormato
	);
	const tablas = [
		['jornadas', ['numero', 'rotulo_literal']],
		[
			'tramos',
			[
				'jornada',
				'v_ini',
				'v_fin',
				'denominacion_literal',
				'n_versos_fuente',
				'fuente_id',
				'pagina'
			]
		],
		[
			'resumen_fuente',
			['denominacion_literal', 'n_versos_fuente', 'porcentaje_literal', 'fuente_id', 'pagina']
		]
	];
	for (const [tabla, campos] of tablas) {
		const esperadas = gold[tabla] ?? [],
			obtenidas = Array.isArray(respuesta?.[tabla]) ? respuesta[tabla] : [];
		if (esperadas.length !== obtenidas.length)
			diferencias.push({
				ruta: `${tabla}.longitud`,
				esperado: esperadas.length,
				obtenido: obtenidas.length
			});
		for (let i = 0; i < Math.max(esperadas.length, obtenidas.length); i++)
			comparar(
				esperadas[i],
				obtenidas[i],
				campos,
				`${tabla}.${i}`,
				diferencias,
				diferenciasFormato
			);
	}
	// Los identificadores pueden cambiar sin alterar el texto ni los vínculos de las notas.
	const notas = (doc) =>
		(Array.isArray(doc.notas) ? doc.notas : []).map((n) => ({
			marca: normalizar(n.marca),
			texto: normalizar(n.texto_literal),
			fuente: n.fuente_id,
			pagina: n.pagina,
			v_ini: n.v_ini,
			v_fin: n.v_fin
		}));
	const notasGold = notas(gold),
		notasRespuesta = notas(respuesta ?? {});
	if (notasGold.length !== notasRespuesta.length)
		diferencias.push({ ruta: 'notas', esperado: notasGold, obtenido: notasRespuesta });
	else
		for (let i = 0; i < notasGold.length; i++)
			comparar(
				notasGold[i],
				notasRespuesta[i],
				['marca', 'texto', 'fuente', 'pagina', 'v_ini', 'v_fin'],
				`notas.${i}`,
				diferencias,
				diferenciasFormato
			);
	const enlaces = (doc, t) =>
		[
			...new Set(
				(t?.notas_ref ?? []).map((id) =>
					normalizar(
						doc.notas?.find((n) => n.id === id)?.texto_literal ?? `NOTA_NO_ENCONTRADA:${id}`
					)
				)
			)
		].sort();
	for (let i = 0; i < (gold.tramos?.length ?? 0); i++) {
		const a = enlaces(gold, gold.tramos[i]),
			b = enlaces(respuesta, respuesta.tramos?.[i]);
		if (!igual(a, b)) diferencias.push({ ruta: `tramos.${i}.notas_ref`, esperado: a, obtenido: b });
	}
	// Las incidencias son texto libre: una redacción distinta requiere cotejo, no una
	// declaración automática de error ni de equivalencia semántica.
	const incidenciasGold = gold.incidencias ?? [];
	const incidenciasRespuesta = respuesta.incidencias ?? [];
	const revisionIncidencias = !igual(incidenciasGold, incidenciasRespuesta);
	return {
		json_valido: true,
		formato: bloque ? 'bloque_json' : 'json_directo',
		estructura_valida: schema.success,
		errores_estructura: schema.success
			? []
			: schema.error.issues.map((i) => ({ ruta: i.path.join('.'), mensaje: i.message })),
		tramos_esperados: gold.tramos.length,
		tramos_obtenidos: Array.isArray(respuesta?.tramos) ? respuesta.tramos.length : 0,
		diferencias,
		diferencias_formato: diferenciasFormato,
		incidencias_para_cotejo: { referencia: incidenciasGold, respuesta: incidenciasRespuesta },
		requiere_cotejo_incidencias: revisionIncidencias,
		lista_para_importar_sin_corregir:
			schema.success && diferencias.length === 0 && !revisionIncidencias,
		validacion_tecnica: validarTextoExtraccion(bloque ? bloque[1] : texto),
		criterio:
			'Cotejo literal con transcripción aceptada. Diferencias por fila y campo; no son tasas independientes ni un ranking de modelos.'
	};
}
