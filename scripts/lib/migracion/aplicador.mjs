/**
 * Qué hay que escribir para migrar una obra, dicho antes de escribir nada.
 *
 * **Puro**: recibe la obra tal como la monta `datos.mjs`, las respuestas del Excel ya leídas por
 * sus claves y el catálogo, y devuelve un plan. No consulta la base ni la toca; quien lo hace es
 * `scripts/aplicar-migracion.mjs`, y por eso `--simular` puede enseñar exactamente lo que se va a
 * hacer: es el mismo plan, sin ejecutar.
 *
 * El plan tiene tres partes y ese es su orden:
 *
 *   1. las **correcciones** a las tablas legadas —renumerar por una laguna que no se contó,
 *      arreglar un rango, fundir tramos—, que cambian los versos de los que todo lo demás habla;
 *   2. las **anotaciones** nuevas, una por secuencia superviviente, tal como las quiere
 *      `guardar_anotacion_metrica`;
 *   3. lo que queda **pendiente**: lo que el editor no contestó y lo que contestó en prosa, que no
 *      se aplica adivinando. Una secuencia pendiente no se anota, y se dice por qué.
 *
 * **Nada se aplica a medias.** Si una secuencia queda pendiente, las demás de la obra siguen
 * adelante: lo que no se puede es inventar una respuesta que falta.
 */

import {
	DESTINO_CARACTERIZACION,
	OPCIONES_CONFIRMACION,
	claveArquitectura,
	claveCierre,
	claveConfirmacion,
	claveDecision,
	claveDesviacion,
	claveFusion,
	claveRespuesta,
	claveRespuestaPorNombre,
	claveRespuestaUnidad,
	claveSinopsis,
	fundirIndicadores
} from './modelo.mjs';
import { realizacionesDe } from '../metrica/realizaciones.mjs';

// ---------------------------------------------------------------------------
// Lectura de lo que el editor escribió a mano
// ---------------------------------------------------------------------------

/** Sin acentos, sin mayúsculas y sin dobles espacios: para comparar lo que una persona escribió. */
export function normalizar(texto) {
	return String(texto ?? '')
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/\s+/g, ' ')
		.trim();
}

/** «1234–1250», «vv. 1234-1250», «del 1234 al 1250»: el rango que el editor da por bueno. */
export function leerRango(texto) {
	const limpio = String(texto ?? '').replace(/\s+/g, ' ');
	const match =
		limpio.match(/(\d{1,6})\s*[–—-]\s*(\d{1,6})/) ?? limpio.match(/(\d{1,6})\s+al\s+(\d{1,6})/i);
	if (!match) return null;
	const v_ini = Number(match[1]);
	const v_fin = Number(match[2]);
	if (!(v_ini > 0) || !(v_fin >= v_ini)) return null;
	return { v_ini, v_fin };
}

/**
 * Dónde está la laguna y cuántos versos faltan.
 *
 * El informe le pide al editor «en qué verso está y cuántos versos faltan», y contesta en prosa.
 * Se leen las dos cifras solo cuando la frase las nombra: **una renumeración mal leída desplaza la
 * obra entera**, así que ante la duda no se lee nada y la secuencia queda pendiente.
 */
export function leerLaguna(texto) {
	const limpio = normalizar(texto);
	if (!limpio) return null;
	const verso = limpio.match(/v(?:erso|\.)?\s*(\d{1,6})/) ?? limpio.match(/^(\d{1,6})\b/);
	const faltan =
		limpio.match(/faltan?\s+(\d{1,3})/) ??
		limpio.match(/(\d{1,3})\s+versos?\s+(?:que\s+)?faltan/) ??
		limpio.match(/laguna\s+de\s+(\d{1,3})/);
	if (!verso || !faltan) return null;
	const desde = Number(verso[1]);
	const cuantos = Number(faltan[1]);
	if (!(desde > 0) || !(cuantos > 0)) return null;
	return { desde, faltan: cuantos };
}

/**
 * «191–194: Cruzada · abab; 203–206: Cruzada · abab»: las estrofas que no siguen la respuesta
 * general. Una excepción sin rango o sin respuesta no se lee, y se dice cuál.
 */
export function leerExcepciones(texto) {
	const partes = String(texto ?? '')
		.split(/[;\n]/)
		.map((parte) => parte.trim())
		.filter(Boolean);
	const excepciones = [];
	const ilegibles = [];
	for (const parte of partes) {
		const corte = parte.indexOf(':');
		const rango = corte > 0 ? leerRango(parte.slice(0, corte)) : null;
		const respuesta = corte > 0 ? parte.slice(corte + 1).trim() : '';
		if (!rango || !respuesta) {
			ilegibles.push(parte);
			continue;
		}
		excepciones.push({ ...rango, respuesta });
	}
	return { excepciones, ilegibles };
}

/** El número de sílabas de un verso, si el editor lo dio: «11», «11 sílabas»; «once» no. */
export function leerSilabas(texto) {
	const match = String(texto ?? '').match(/\d{1,2}/);
	if (!match) return null;
	const silabas = Number(match[0]);
	return silabas >= 2 && silabas <= 20 ? silabas : null;
}

const [CORRECTO, INCORRECTO] = OPCIONES_CONFIRMACION;

/** Si una confirmación dice que sí. Lo que no es un «sí» claro no se da por confirmado. */
export function confirma(fila) {
	if (!fila?.respuesta) return null;
	const dicho = normalizar(fila.respuesta);
	if (dicho === normalizar(CORRECTO) || dicho === 'si' || dicho === 'correcto') return true;
	if (dicho === normalizar(INCORRECTO) || dicho.startsWith('no')) return false;
	return null;
}

// ---------------------------------------------------------------------------
// Del texto del Excel al dato del catálogo
// ---------------------------------------------------------------------------

/** La opción de una pregunta que el editor eligió, buscada por su nombre. */
function opcionPorNombre(pregunta, texto) {
	const buscado = normalizar(texto);
	if (!buscado) return null;
	const opciones = pregunta.opciones ?? [];
	return (
		opciones.find((o) => normalizar(o.nombre) === buscado) ??
		// El nombre de una opción lleva a veces la variedad delante —«A2 · AbaBcC»— y el editor
		// puede haber copiado solo la parte que le importa.
		opciones.find((o) => normalizar(o.nombre).split(' · ').includes(buscado)) ??
		null
	);
}

/**
 * Los regímenes de rima que afirman las respuestas de una secuencia: las que ya traía la propuesta
 * y las que salen de lo contestado en el Excel.
 *
 * Una respuesta lo dice eligiendo una disposición del catálogo, que lleva su tipo de rima. Se miran
 * todas, las de la secuencia y las de cada estrofa: una tirada de pareados puede tener unos
 * consonantes y otros asonantes, y entonces la asonancia sigue teniendo su dato que declarar.
 */
export function tiposDeRimaAfirmados(respuestasPropuesta, elecciones, preguntas) {
	const tipoPorOpcion = new Map();
	for (const pregunta of preguntas ?? []) {
		for (const opcion of pregunta.opciones ?? []) {
			if (opcion.tipo_rima_id) tipoPorOpcion.set(opcion.opcion_eleccion_id, opcion.tipo_rima_id);
		}
	}
	const afirmados = new Set();
	for (const respuesta of respuestasPropuesta ?? []) {
		if (respuesta.tipo_rima_id) afirmados.add(String(respuesta.tipo_rima_id));
	}
	for (const eleccion of elecciones ?? []) {
		const tipo = tipoPorOpcion.get(eleccion.opcion_eleccion_id);
		if (tipo) afirmados.add(String(tipo));
	}
	return afirmados;
}

/** Si una pregunta condicionada aplica. **No saber no es saber que sí.** */
export function preguntaAplica(pregunta, afirmados) {
	if (!pregunta.solo_si_tipo_rima_id) return true;
	return afirmados.has(String(pregunta.solo_si_tipo_rima_id));
}

/** El metro de un número de sílabas, para la desviación de medida que trae cifra. */
export function metroDeSilabas(metros, silabas) {
	const candidatos = (metros ?? []).filter((m) => Number(m.silabas) === Number(silabas));
	if (candidatos.length === 0) return null;
	// Un «dodecasílabo compuesto 6 + 6» mide lo mismo que el dodecasílabo: sin más datos se toma el
	// simple, y si tampoco así se distingue, no se toma ninguno y la desviación va sin cifra.
	const simples = candidatos.filter((m) => !/compuesto/i.test(m.nombre));
	if (simples.length === 1) return simples[0];
	return candidatos.length === 1 ? candidatos[0] : null;
}

// ---------------------------------------------------------------------------
// Las elecciones de una secuencia
// ---------------------------------------------------------------------------

const raicesDe = (unidades) => unidades.filter((u) => u.realizacion_padre_id === null);

/**
 * Las realizaciones a las que toca una pregunta: **la unidad entera si no señala sección**, y si la
 * señala, las realizaciones de esa sección. Es la misma regla que aplica la base al contar si una
 * pregunta está respondida, y la que sigue quien siembra las obras de prueba.
 */
const destinosDe = (pregunta, unidades) =>
	unidades.filter((u) =>
		pregunta.seccion_id == null
			? u.realizacion_padre_id === null
			: u.seccion_id === pregunta.seccion_id
	);

/**
 * La unidad a la que pertenece una realización: su raíz, subiendo por los padres.
 *
 * **La clave del Excel habla de unidades.** Una pregunta que señala una sección —la primera
 * quintilla de una copla real— se responde una vez por unidad, y la fila lleva el verso en que
 * empieza la copla, no el de la quintilla. Sin esto, las respuestas de la segunda sección no
 * casarían con ninguna fila y la secuencia quedaría pendiente sin motivo.
 */
function unidadDe(unidades, realizacion) {
	let actual = realizacion;
	while (actual?.realizacion_padre_id) {
		const padre = unidades.find((u) => u.realizacion_id === actual.realizacion_padre_id);
		if (!padre) break;
		actual = padre;
	}
	return actual ?? realizacion;
}

/** La realización que cubre un verso: la unidad cuyo rango lo contiene. */
function unidadEn(unidades, verso) {
	return raicesDe(unidades).find((u) => u.v_ini <= verso && verso <= u.v_fin) ?? null;
}

function eleccionDeOpcion(pregunta, opcion, realizacionId) {
	return {
		realizacion_id: realizacionId,
		dimension: pregunta.dimension,
		seccion_tratada_id: pregunta.seccion_tratada_id ?? null,
		opcion_eleccion_id: opcion.opcion_eleccion_id,
		valor_texto: null,
		observaciones: null
	};
}

function eleccionDeTexto(pregunta, texto, realizacionId) {
	return {
		realizacion_id: realizacionId,
		dimension: pregunta.dimension,
		seccion_tratada_id: pregunta.seccion_tratada_id ?? null,
		opcion_eleccion_id: null,
		valor_texto: texto,
		observaciones: null
	};
}

/**
 * Las respuestas que la propuesta ya trae —lo anotado y lo derivado del término— convertidas en
 * elecciones. Las de unidad se colocan por el verso en el que empieza la estrofa.
 */
function eleccionesDeLaPropuesta(partes, unidades, preguntasPorGrupo, avisos) {
	const elecciones = [];
	for (const parte of partes) {
		for (const fila of parte.respuestas ?? []) {
			const pregunta = preguntasPorGrupo.get(fila.grupo_eleccion_id);
			if (!pregunta) {
				avisos.push(`La respuesta «${fila.pregunta}» no corresponde a ninguna pregunta activa.`);
				continue;
			}
			const realizacion =
				fila.alcance === 'secuencia' ? null : unidadEn(unidades, Number(fila.unidad_v_ini));
			if (fila.alcance !== 'secuencia' && !realizacion) {
				avisos.push(
					`La respuesta «${fila.pregunta}» habla del verso ${fila.unidad_v_ini}, que no cae en ninguna estrofa.`
				);
				continue;
			}
			elecciones.push(
				fila.opcion_eleccion_id
					? {
							realizacion_id: realizacion?.realizacion_id ?? null,
							dimension: pregunta.dimension,
							seccion_tratada_id: pregunta.seccion_tratada_id ?? null,
							opcion_eleccion_id: fila.opcion_eleccion_id,
							valor_texto: null,
							observaciones: null
						}
					: eleccionDeTexto(pregunta, fila.respuesta, realizacion?.realizacion_id ?? null)
			);
		}
	}
	return elecciones;
}

/**
 * Una medida escrita verso a verso —«7 11 7 7 11»— colocada en las opciones por posición.
 *
 * Las formas heterométricas no preguntan «qué metro» sino «qué metro en cada verso», y cada opción
 * lleva su posición dentro de la estrofa. El editor escribe las sílabas en orden, que es lo que el
 * informe le pide, y aquí se busca la opción de esa posición con ese metro.
 */
function eleccionesPorPosicion(pregunta, texto, realizacion, metros, pendientes, contexto) {
	const cifras = String(texto ?? '')
		.split(/[\s,]+/)
		.map((trozo) => Number(trozo))
		.filter((numero) => Number.isFinite(numero) && numero > 0);
	const posiciones = new Set((pregunta.opciones ?? []).map((o) => Number(o.posicion_unidad)));
	// **Se piden tantas medidas como versos tiene la realización**, no como posiciones ofrece la
	// pregunta: el remate de una canción admite hasta trece versos y puede tener seis. Una posición
	// que la realización no tiene no se responde, y la base rechaza que se responda.
	const esperadas = realizacion ? realizacion.v_fin - realizacion.v_ini + 1 : posiciones.size;
	if (cifras.length !== esperadas) {
		pendientes.push(
			`${contexto}: «${pregunta.nombre}» pide ${esperadas} medidas y se han escrito ${cifras.length} («${texto}»).`
		);
		return [];
	}
	const elecciones = [];
	cifras.forEach((silabas, indice) => {
		const metro = metroDeSilabas(metros, silabas);
		const opcion = (pregunta.opciones ?? []).find(
			(o) => Number(o.posicion_unidad) === indice + 1 && o.metro_id === metro?.metro_id
		);
		if (!opcion) {
			pendientes.push(
				`${contexto}: el verso ${indice + 1} se dice de ${silabas} sílabas y «${pregunta.nombre}» no ofrece esa medida ahí.`
			);
			return;
		}
		elecciones.push(eleccionDeOpcion(pregunta, opcion, realizacion?.realizacion_id ?? null));
	});
	return elecciones;
}

/**
 * Una respuesta escrita, colocada en una realización: según lo que la pregunta admita, una medida
 * por posición, un texto libre o una o varias opciones del repertorio.
 *
 * **Lo usan los dos caminos**, el de la fila por estrofa y el de la respuesta que vale para todas:
 * una pregunta que admite dos respuestas —las dos medidas de un pareado— se contesta con punto y
 * coma se conteste donde se conteste.
 */
function colocarRespuesta(pregunta, texto, realizacion, metros, pendientes, contexto, donde = '') {
	const realizacionId = realizacion?.realizacion_id ?? null;
	if ((pregunta.opciones ?? []).some((o) => o.posicion_unidad != null)) {
		return eleccionesPorPosicion(pregunta, texto, realizacion, metros, pendientes, contexto);
	}
	if ((pregunta.opciones ?? []).length === 0) {
		return [eleccionDeTexto(pregunta, texto, realizacionId)];
	}
	const elecciones = [];
	// Una pregunta que admite varias respuestas se contesta separándolas con punto y coma.
	const trozos =
		Number(pregunta.selecciones_max ?? 1) > 1 ? texto.split(';').map((t) => t.trim()) : [texto];
	for (const trozo of trozos.filter(Boolean)) {
		const opcion = opcionPorNombre(pregunta, trozo);
		if (!opcion) {
			pendientes.push(
				`${contexto}: «${trozo}» no es una de las opciones de «${pregunta.nombre}»${donde}.`
			);
			continue;
		}
		elecciones.push(eleccionDeOpcion(pregunta, opcion, realizacionId));
	}
	return elecciones;
}

function eleccionesDeUnaRespuesta(pregunta, fila, unidades, metros, pendientes, avisos, contexto) {
	const elecciones = [];
	const destinos = destinosDe(pregunta, unidades);
	const colocar = (texto, realizacion, donde) =>
		elecciones.push(
			...colocarRespuesta(pregunta, texto, realizacion, metros, pendientes, contexto, donde)
		);

	const { excepciones, ilegibles } = leerExcepciones(fila.detalle);
	for (const ilegible of ilegibles) {
		pendientes.push(`${contexto}: no se entiende la excepción «${ilegible}».`);
	}

	if (pregunta.alcance === 'secuencia') {
		colocar(fila.respuesta, null, '');
		return elecciones;
	}

	if (destinos.length === 0) {
		// **Una parte que puede no estar no se exige.** El remate de una canción es opcional, y su
		// medida solo es obligatoria si el pasaje lo lleva: la base lo comprueba así —recorre las
		// realizaciones que existen— y aquí se hace igual. Lo que el pasaje no tiene se dice y se
		// sigue; lo que debería tener y no tiene, para.
		const opcional = pregunta.seccion_id && Number(pregunta.seccion_repeticiones_min) === 0;
		const aviso = `${contexto}: «${pregunta.nombre}» pregunta por una parte que este pasaje no tiene, según cómo se reparten sus versos.`;
		if (opcional) avisos.push(aviso);
		else pendientes.push(aviso);
		return elecciones;
	}

	for (const unidad of destinos) {
		const excepcion =
			excepciones.find((e) => e.v_ini <= unidad.v_ini && unidad.v_fin <= e.v_fin) ?? null;
		colocar(
			excepcion ? excepcion.respuesta : fila.respuesta,
			unidad,
			` (vv. ${unidad.v_ini}–${unidad.v_fin})`
		);
	}
	// Una excepción que no cae en ninguna estrofa es un error de quien la escribió, no un matiz.
	for (const excepcion of excepciones) {
		if (!destinos.some((u) => excepcion.v_ini <= u.v_ini && u.v_fin <= excepcion.v_fin)) {
			pendientes.push(
				`${contexto}: la excepción de ${excepcion.v_ini}–${excepcion.v_fin} no coincide con ninguna estrofa.`
			);
		}
	}
	return elecciones;
}

// ---------------------------------------------------------------------------
// Las desviaciones que salen de las caracterizaciones
// ---------------------------------------------------------------------------

function desviacionesDe(partes, respuestas, metros, avisos, pendientes) {
	const desviaciones = [];
	const conservadas = [];
	for (const parte of partes) {
		for (const caracterizacion of parte.caracterizaciones ?? []) {
			const destino = DESTINO_CARACTERIZACION[caracterizacion.termino];
			const fila = respuestas.get(claveDesviacion(caracterizacion.caracterizacion_rango_id));
			const donde = `«${caracterizacion.termino}» de ${caracterizacion.v_ini}–${caracterizacion.v_fin}`;

			// **Lo que el editor no da por bueno no se escribe**, diga lo que diga la tabla: la
			// corrección viene en prosa y eso se mira a mano. Vale para las tres clases de fila,
			// también para las que solo se le enseñaban.
			if (confirma(fila) === false) {
				pendientes.push(
					`La caracterización ${donde} no queda como dice el informe, según el editor («${fila.detalle || fila.comentario || 'sin detalle'}»).`
				);
				continue;
			}
			if (!destino) {
				avisos.push(
					`La caracterización ${donde} no tiene traducción prevista y se queda como está.`
				);
				conservadas.push(caracterizacion);
				continue;
			}
			if (!destino.desviacion) {
				// Las enunciativas se quedan donde están, y lo que el catálogo ya recoge de otra
				// manera —la asonancia de un romance en «a»— no se escribe dos veces.
				conservadas.push(caracterizacion);
				continue;
			}
			const silabas = destino.pide === 'silabas' ? leerSilabas(fila?.silabas) : null;
			const metro = silabas ? metroDeSilabas(metros, silabas) : null;
			if (silabas && !metro) {
				avisos.push(
					`El verso ${caracterizacion.v_ini} se dice de ${silabas} sílabas y el catálogo no tiene ese metro: la desviación se registra sin cifra.`
				);
			}
			desviaciones.push({
				realizacion_id: null,
				dimension: destino.desviacion.dimension,
				relacion_norma: destino.desviacion.relacion_norma,
				v_ini: Number(caracterizacion.v_ini),
				v_fin: Number(caracterizacion.v_fin),
				observaciones: caracterizacion.observaciones ?? null,
				metro_observado_id: metro?.metro_id ?? null,
				esquema_rima_observado_id: null,
				seccion_observada_id: null,
				repeticion_observada_id: null,
				valor_rasgo_observado_id: null
			});
		}
	}
	return { desviaciones, conservadas };
}

// ---------------------------------------------------------------------------
// La obra, ya corregida
// ---------------------------------------------------------------------------

/**
 * La obra tal como queda **después** de las correcciones, para poder planificar sobre ella.
 *
 * Importa el orden: una renumeración mueve los versos de los que hablan todas las respuestas, y si
 * las estrofas se repartieran sobre la numeración vieja la anotación quedaría desplazada respecto
 * de la secuencia que la base va a tener. `guardar_anotacion_metrica` toma el rango de la secuencia
 * real, así que el reparto tiene que hacerse sobre el rango corregido.
 *
 * Las lagunas las localiza el editor en la numeración que él ve, la de hoy, así que una segunda
 * laguna se desplaza por lo que añadió la primera.
 */
export function corregirLaObra(obra, correcciones) {
	const rangos = correcciones.filter((c) => c.tipo === 'rango');
	const renumeraciones = [...correcciones.filter((c) => c.tipo === 'renumerar')].sort(
		(a, b) => a.desde - b.desde
	);
	if (rangos.length === 0 && renumeraciones.length === 0) return obra;

	let acumulado = 0;
	const saltos = renumeraciones.map((correccion) => {
		const desde = correccion.desde + acumulado;
		acumulado += correccion.faltan;
		// El verso que el editor nombró, ya en la numeración que tendrá la obra cuando le toque el
		// turno a esta laguna: es el que hay que escribir en la base.
		correccion.desde_efectivo = desde;
		return { desde, faltan: correccion.faltan };
	});

	// Un verso se desplaza por cada laguna que quede detrás de él. Así, un rango que empieza
	// después del salto se mueve entero, y uno que lo contiene crece por el final: que es lo que
	// significa contar los versos de la laguna.
	const desplazar = (verso) =>
		saltos.reduce(
			(total, salto) => (verso >= salto.desde ? total + salto.faltan : total),
			Number(verso)
		);

	const porRango = new Map(rangos.map((c) => [c.secuencia_id, c]));
	const mover = (fila) => ({
		...fila,
		v_ini: desplazar(Number(fila.v_ini)),
		v_fin: desplazar(Number(fila.v_fin))
	});

	const corregidas = obra.secuencias.map((secuencia) => {
		const corregida = porRango.get(secuencia.secuencia_id);
		const v_ini = corregida ? corregida.v_ini : desplazar(Number(secuencia.v_ini));
		const v_fin = corregida ? corregida.v_fin : desplazar(Number(secuencia.v_fin));
		return {
			...secuencia,
			v_ini,
			v_fin,
			n_versos: v_fin - v_ini + 1,
			subtipos: (secuencia.subtipos ?? []).map(mover),
			caracterizaciones: (secuencia.caracterizaciones ?? []).map(mover),
			respuestas: (secuencia.respuestas ?? []).map((respuesta) =>
				respuesta.unidad_v_ini == null
					? respuesta
					: {
							...respuesta,
							unidad_v_ini: desplazar(Number(respuesta.unidad_v_ini)),
							unidad_v_fin: desplazar(Number(respuesta.unidad_v_fin))
						}
			)
		};
	});

	// Los tramos fundibles apuntan a las filas de antes: se rehacen con las corregidas, para que
	// una fusión hable de las mismas respuestas y de los mismos versos que todo lo demás.
	const porId = new Map(corregidas.map((secuencia) => [secuencia.secuencia_id, secuencia]));
	return {
		...obra,
		secuencias: corregidas,
		fundibles: (obra.fundibles ?? []).map((tramo) =>
			tramo.map((parte) => porId.get(parte.secuencia_id) ?? mover(parte))
		)
	};
}

// ---------------------------------------------------------------------------
// El plan de una obra
// ---------------------------------------------------------------------------

/**
 * Los tramos que se funden.
 *
 * **Fundir es la regla, no una decisión**: el tramo es contiguo, de la misma arquitectura y no
 * cruza jornada ni cuadro, así que el pasaje es uno solo y el vocabulario anterior lo partía. Por
 * eso se funde salvo que el editor diga que no; si no contestó, se funde y se deja dicho en el
 * guion, como cualquier otra respuesta que se enseñó rellena y nadie corrigió.
 */
function fusionesConfirmadas(obra, respuestas) {
	return (obra.fundibles ?? []).map((tramo) => {
		const primera = tramo[0];
		const ultima = tramo[tramo.length - 1];
		const fila = respuestas.get(claveFusion(primera.secuencia_id, ultima.secuencia_id));
		if (confirma(fila) === false) return { tramo, funde: false, dicho: fila };
		return {
			tramo,
			funde: true,
			confirmada: confirma(fila) === true,
			sinopsis: respuestas.get(claveSinopsis(primera.secuencia_id))?.respuesta ?? ''
		};
	});
}

/** La decisión sobre un rango que no cuadra, convertida en corrección o en un motivo para parar. */
function decidirSobreElRango(secuencia, respuestas, correcciones) {
	const fila = respuestas.get(claveDecision(secuencia.secuencia_id));
	const dicho = normalizar(fila?.respuesta);
	const donde = `vv. ${secuencia.v_ini}–${secuencia.v_fin}`;
	const escrito = fila ? fila.detalle || fila.comentario || '' : '';

	if (!dicho) return `${donde}: sin respuesta a lo que no cuadra.`;

	if (dicho.startsWith('hay una laguna')) {
		const laguna = leerLaguna(escrito);
		if (!laguna) {
			return `${donde}: dice que hay una laguna que no se contó, pero no se leen el verso y cuántos faltan en «${escrito}».`;
		}
		correcciones.push({
			tipo: 'renumerar',
			secuencia_id: secuencia.secuencia_id,
			desde: laguna.desde,
			faltan: laguna.faltan,
			descripcion: `Renumerar la obra desde el verso ${laguna.desde}: se añaden los ${laguna.faltan} versos que la laguna no contó.`
		});
		return null;
	}

	if (dicho.startsWith('el rango esta mal')) {
		const rango = leerRango(escrito);
		if (!rango)
			return `${donde}: dice que el rango está mal y no se lee el correcto en «${escrito}».`;
		correcciones.push({
			tipo: 'rango',
			secuencia_id: secuencia.secuencia_id,
			...rango,
			descripcion: `Corregir el rango de ${donde} a ${rango.v_ini}–${rango.v_fin}.`
		});
		return null;
	}

	return `${donde}: contesta «${fila.respuesta}», que se resuelve a mano.`;
}

/**
 * El plan entero de una obra.
 *
 * `catalogo` es un mapa `arquitectura_id -> { forma_id, unidad_versos_min, unidad_versos_max,
 * secciones }`, y `metros` la tabla de metros. Los dos se leen de la base antes de llamar aquí.
 */
export function planificarObra(obra, respuestas, catalogo, metros) {
	const correcciones = [];
	const pendientesObra = [];
	const anotaciones = [];
	const bloqueadas = new Map();

	// --- 1 · Lo que el editor decidió sobre los rangos que no cuadran.
	for (const secuencia of obra.secuencias) {
		if (!secuencia.diagnostico) continue;
		const motivo = decidirSobreElRango(secuencia, respuestas, correcciones);
		if (motivo) bloqueadas.set(secuencia.secuencia_id, motivo);
	}

	// --- 2 · La obra, ya con esas correcciones puestas: todo lo que sigue habla de los versos que
	// la base va a tener, no de los que tiene ahora.
	const corregida = corregirLaObra(obra, correcciones);

	// --- 3 · Las fusiones, que deciden qué secuencias quedan.
	const absorbidas = new Map();
	const funde = new Map();
	for (const fusion of fusionesConfirmadas(corregida, respuestas)) {
		const primera = fusion.tramo[0];
		const ultima = fusion.tramo[fusion.tramo.length - 1];
		if (!fusion.funde) {
			pendientesObra.push(
				`El tramo ${primera.v_ini}–${ultima.v_fin} no se funde: el editor dice que son pasajes distintos${fusion.dicho?.detalle ? ` («${fusion.dicho.detalle}»)` : ''}. Sus secuencias se anotan por separado.`
			);
			continue;
		}
		if (!fusion.confirmada) {
			pendientesObra.push(
				`El tramo ${primera.v_ini}–${ultima.v_fin} se funde sin que el editor lo haya confirmado: dejó esa fila en blanco.`
			);
		}
		funde.set(primera.secuencia_id, fusion);
		for (const parte of fusion.tramo.slice(1)) {
			absorbidas.set(parte.secuencia_id, primera.secuencia_id);
		}
		correcciones.push({
			tipo: 'fusion',
			secuencia_id: primera.secuencia_id,
			absorbidas: fusion.tramo.slice(1).map((parte) => ({
				secuencia_id: parte.secuencia_id,
				v_ini: Number(parte.v_ini),
				v_fin: Number(parte.v_fin),
				termino_legado: parte.termino_legado
			})),
			v_ini: Number(primera.v_ini),
			v_fin: Number(ultima.v_fin),
			indicadores: fundirIndicadores(fusion.tramo),
			sinopsis: fusion.sinopsis,
			descripcion: `Fundir ${fusion.tramo.length} secuencias en una sola, ${primera.v_ini}–${ultima.v_fin}.`
		});
		if (!fusion.sinopsis) {
			pendientesObra.push(
				`El tramo fundido ${primera.v_ini}–${ultima.v_fin} se queda con las sinopsis de sus partes, una detrás de otra: el editor no escribió la nueva.`
			);
		}
	}

	// --- 4 · Una anotación por secuencia superviviente.
	for (const original of corregida.secuencias) {
		if (absorbidas.has(original.secuencia_id)) continue;

		const bloqueo = bloqueadas.get(original.secuencia_id);
		if (bloqueo) {
			anotaciones.push({ secuencia: original, resultado: 'pendiente', motivos: [bloqueo] });
			continue;
		}

		const fusion = funde.get(original.secuencia_id) ?? null;
		const partes = fusion ? fusion.tramo : [original];
		const vIni = Number(original.v_ini);
		const vFin = Number(partes[partes.length - 1].v_fin);
		const contexto = `vv. ${vIni}–${vFin}`;

		let secuencia = original;
		if (!secuencia.arquitectura_propuesta_id) {
			// Sin arquitectura propuesta —el `irregular` escueto—, la dijo el editor en el Excel.
			const fila = respuestas.get(claveArquitectura(secuencia.secuencia_id));
			const elegida = (secuencia.arquitecturas_de_forma ?? []).find(
				(a) => normalizar(a.nombre) === normalizar(fila?.respuesta)
			);
			if (!elegida) {
				anotaciones.push({
					secuencia: original,
					resultado: 'pendiente',
					motivos: [
						`${contexto}: el término «${secuencia.termino_legado}» no dice la arquitectura, y la respuesta del Excel${fila?.respuesta ? ` («${fila.respuesta}»)` : ''} no nombra ninguna.`
					]
				});
				continue;
			}
			secuencia = { ...secuencia, arquitectura_propuesta_id: elegida.arquitectura_id };
		}

		const arquitectura = catalogo.get(secuencia.arquitectura_propuesta_id);
		if (!arquitectura) {
			anotaciones.push({
				secuencia: original,
				resultado: 'pendiente',
				motivos: [`${contexto}: su arquitectura ya no está activa en el catálogo.`]
			});
			continue;
		}

		const { unidades, problema } = realizacionesDe(arquitectura, vIni, vFin);
		if (problema || unidades.length === 0) {
			anotaciones.push({
				secuencia: original,
				resultado: 'pendiente',
				motivos: [
					`${contexto}: no se pueden repartir las estrofas — ${problema ?? 'sin unidades'}.`
				]
			});
			continue;
		}

		const pendientes = [];
		const avisos = [];
		// **Las preguntas salen del catálogo, no de la propuesta.** Cuando la arquitectura la elige
		// el editor en el Excel, la propuesta no trae ninguna: preguntaría por la que no es.
		const preguntas = arquitectura.grupos ?? [];
		const preguntasPorGrupo = new Map(
			preguntas.map((pregunta) => [pregunta.grupo_eleccion_id, pregunta])
		);
		const elecciones = eleccionesDeLaPropuesta(partes, unidades, preguntasPorGrupo, avisos);

		// Lo derivado que el editor no da por bueno no se escribe: lo que dijo está en prosa.
		const confirmacion = respuestas.get(claveConfirmacion(secuencia.secuencia_id));
		if (confirma(confirmacion) === false) {
			pendientes.push(
				`${contexto}: el editor corrige lo que se había rellenado («${confirmacion.detalle || confirmacion.comentario || 'sin detalle'}»).`
			);
		}
		const cierre = respuestas.get(claveCierre(secuencia.secuencia_id));
		if (confirma(cierre) === false) {
			pendientes.push(
				`${contexto}: el editor no da por bueno el cierre de la serie («${cierre.detalle || cierre.comentario || 'sin detalle'}»).`
			);
		}

		// Lo que faltaba por responder, pregunta a pregunta.
		const respondidas = new Set(
			partes.flatMap((parte) => (parte.respuestas ?? []).map((r) => r.grupo_eleccion_id))
		);
		/**
		 * Lo que hay que resolver de una pregunta, para poder hacerlo en dos vueltas.
		 *
		 * Las preguntas condicionadas al régimen de la rima —las vocales de la asonancia— se
		 * resuelven después, cuando la rima ya está contestada: si se miraran a la vez, la condición
		 * se evaluaría contra lo que aún no se ha leído.
		 */
		const resolverPregunta = (pregunta) => {
			// **Una parte que el pasaje no tiene no se pregunta.** El remate de una canción puede no
			// estar, y entonces su medida no falta: no existe. La base lo mira igual, recorriendo las
			// realizaciones que hay.
			if (
				destinosDe(pregunta, unidades).length === 0 &&
				pregunta.seccion_id &&
				Number(pregunta.seccion_repeticiones_min) === 0
			) {
				avisos.push(
					`${contexto}: no lleva ${String(pregunta.seccion_nombre ?? 'esa parte').toLowerCase()}, así que «${pregunta.nombre}» no se pregunta.`
				);
				return;
			}

			const porUnidad = destinosDe(pregunta, unidades)
				.map((unidad) => ({
					unidad,
					fila: respuestas.get(
						claveRespuestaUnidad(
							secuencia.secuencia_id,
							pregunta.grupo_eleccion_id,
							unidadDe(unidades, unidad).v_ini
						)
					)
				}))
				.filter((entrada) => entrada.fila?.respuesta);

			if (porUnidad.length > 0) {
				for (const { unidad, fila } of porUnidad) {
					elecciones.push(
						...colocarRespuesta(
							pregunta,
							fila.respuesta,
							unidad,
							metros,
							pendientes,
							contexto,
							` (vv. ${unidad.v_ini}–${unidad.v_fin})`
						)
					);
				}
				const sinContestar = destinosDe(pregunta, unidades).length - porUnidad.length;
				if (sinContestar > 0) {
					pendientes.push(
						`${contexto}: «${pregunta.nombre}» se preguntaba estrofa a estrofa y quedan ${sinContestar} sin contestar.`
					);
				}
				return;
			}

			const fila =
				respuestas.get(claveRespuesta(secuencia.secuencia_id, pregunta.grupo_eleccion_id)) ??
				respuestas.get(claveRespuestaPorNombre(secuencia.secuencia_id, pregunta.nombre));
			if (!fila?.respuesta) {
				pendientes.push(`${contexto}: falta la respuesta a «${pregunta.nombre}».`);
				return;
			}
			elecciones.push(
				...eleccionesDeUnaRespuesta(pregunta, fila, unidades, metros, pendientes, avisos, contexto)
			);
		};

		const aplicables = preguntas.filter(
			(pregunta) =>
				!respondidas.has(pregunta.grupo_eleccion_id) && Number(pregunta.selecciones_min) >= 1
		);
		for (const pregunta of aplicables.filter((p) => !p.solo_si_tipo_rima_id)) {
			resolverPregunta(pregunta);
		}

		// **Una pregunta condicionada se mide contra la rima que se haya afirmado**, venga de la
		// propuesta o de lo que el editor acaba de contestar. No saber no es saber que sí: si la
		// condición no se cumple, la respuesta sobra y la base la rechaza.
		const afirmados = tiposDeRimaAfirmados(
			partes.flatMap((parte) => parte.respuestas ?? []),
			elecciones,
			preguntas
		);
		for (const pregunta of aplicables.filter((p) => p.solo_si_tipo_rima_id)) {
			if (!preguntaAplica(pregunta, afirmados)) {
				avisos.push(
					`${contexto}: «${pregunta.nombre}» solo se pregunta cuando la rima lo pide, y aquí no.`
				);
				continue;
			}
			resolverPregunta(pregunta);
		}

		const { desviaciones, conservadas } = desviacionesDe(
			partes,
			respuestas,
			metros,
			avisos,
			pendientes
		);

		if (pendientes.length > 0) {
			anotaciones.push({
				secuencia: original,
				resultado: 'pendiente',
				motivos: pendientes,
				avisos
			});
			continue;
		}

		anotaciones.push({
			secuencia: original,
			resultado: fusion ? 'fundida' : 'anotada',
			avisos,
			conservadas,
			datos: {
				anotacion_id: null,
				escenario_id: null,
				secuencia_id: secuencia.secuencia_id,
				orden: 1,
				v_ini: vIni,
				v_fin: vFin,
				forma_id: arquitectura.forma_id,
				arquitectura_id: secuencia.arquitectura_propuesta_id,
				observaciones: null,
				unidades,
				elecciones,
				desviaciones
			}
		});
	}

	return { correcciones, anotaciones, pendientes: pendientesObra };
}
