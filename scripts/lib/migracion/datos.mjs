/**
 * Lo que la migración necesita saber de cada obra, leído de la base enlazada y montado como el
 * modelo que consumen los escritores.
 *
 * **La equivalencia no se calcula aquí.** La resuelve la vista `propuesta_metrica_secuencia`, y
 * las respuestas que el término legado ya contenía, `propuesta_elecciones_secuencia`. Aquí solo se
 * leen, se cruzan con lo demás que la obra tiene anotado —subtipos, caracterizaciones, jornadas,
 * cuadros— y se calcula lo que solo se ve juntándolo: las unidades, lo que falta, el diagnóstico.
 *
 * **Solo las secuencias legadas.** Las que ya están anotadas con el editor V2 no declaran término
 * viejo y entran en la vista por la vía `sin_tipo`; no hay nada que migrar de ellas y no se
 * informan. Lo mismo las obras de prueba, que nacieron ya en el modelo nuevo.
 */

import { query } from '../consulta.mjs';
import { cargarCatalogo } from '../metrica/catalogo.mjs';
import { realizacionesDe } from '../metrica/realizaciones.mjs';
import { preguntaAplica, tiposDeRimaAfirmados } from './aplicador.mjs';
import {
	diagnosticar,
	filasDeFusion,
	filasDeSecuencia,
	tramosFundibles,
	unidadesDe
} from './modelo.mjs';

// --------------------------------------------------------------------------
// Consultas
// --------------------------------------------------------------------------

/** Una fila por secuencia legada, ya resuelta por la vista, con lo que la obra dice de ella. */
const SQL_SECUENCIAS = `
	select
		p.secuencia_id, p.obra_id, o.titulo as obra_titulo, o.slug as obra_slug,
		e.nombre_completo as editor,
		p.v_ini, p.v_fin, s.n_versos,
		p.termino_legado, p.forma_propuesta_id, p.forma_propuesta, p.arquitectura_propuesta_id,
		p.arquitectura_propuesta, p.via, p.detalle, p.heredado_de,
		p.longitud_compatible, p.motivo_revision,
		a.unidad_versos_min, a.unidad_versos_max,
		s.sinopsis, s.inaugura_espacio, s.versos_partidos, s.evento_sobrenatural,
		s.intervencion_personajes_femeninos, s.intervencion_figuras_donaire,
		s.intervencion_personajes_sobrenaturales,
		r.minimo_versos, r.modulo_versos, r.residuo_versos, r.desplazamientos, r.explicacion,
		r.origen as regla_origen
	from public.propuesta_metrica_secuencia p
	join public.secuencias_metricas s on s.secuencia_id = p.secuencia_id
	join public.obras o on o.obra_id = p.obra_id
	left join public.editores e on e.user_id = o.editor_asignado
	left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
	left join public.arquitecturas_reglas_longitud r on r.arquitectura_id = p.arquitectura_propuesta_id
	where p.via <> 'sin_tipo'
	order by o.titulo, p.v_ini
`;

const SQL_SUBTIPOS = `
	select sse.subtipo_secuencia_id, sse.secuencia_id, v.termino, sse.v_ini, sse.v_fin
	from public.secuencias_subtipos_estrofa sse
	join public.propuesta_metrica_secuencia p on p.secuencia_id = sse.secuencia_id and p.via <> 'sin_tipo'
	left join public.vocabularios v on v.termino_id = sse.subtipo_estrofa_id
	order by sse.v_ini
`;

const SQL_CARACTERIZACIONES = `
	select scr.caracterizacion_rango_id, scr.secuencia_id, v.termino, scr.v_ini, scr.v_fin,
		scr.observaciones
	from public.secuencias_caracterizaciones_rango scr
	join public.propuesta_metrica_secuencia p on p.secuencia_id = scr.secuencia_id and p.via <> 'sin_tipo'
	left join public.vocabularios v on v.termino_id = scr.tipo_caracterizacion_rango_id
	order by scr.v_ini
`;

const SQL_JORNADAS = `select obra_id, jornada_num, v_ini, v_fin from public.jornadas order by obra_id, v_ini`;

const SQL_CUADROS = `
	select j.obra_id, j.jornada_num, c.cuadro_num, c.v_ini, c.v_fin
	from public.cuadros c
	join public.jornadas j on j.jornada_id = c.jornada_id
	order by j.obra_id, c.v_ini
`;

/**
 * Todas las preguntas activas de las arquitecturas propuestas, con sus opciones y **con la parte
 * que señalan**: hay preguntas obligatorias sobre partes que pueden no estar —la medida del remate
 * de una canción—, y solo se preguntan si el pasaje lleva esa parte.
 */
const SQL_PREGUNTAS = `
	select g.arquitectura_id, g.grupo_eleccion_id, g.nombre, g.alcance, g.dimension,
		g.seccion_id, g.seccion_tratada_id, g.selecciones_min, g.selecciones_max, g.orden,
		g.solo_si_tipo_rima_id, tr.termino as solo_si_tipo_rima,
		sec.nombre as seccion_nombre, sec.repeticiones_min as seccion_repeticiones_min
	from public.grupos_eleccion_metrica_resueltos g
	left join public.estructuras_secciones sec on sec.seccion_id = g.seccion_id
	left join public.vocabularios tr on tr.termino_id = g.solo_si_tipo_rima_id
	where g.activo and g.arquitectura_id in (
		select distinct p.arquitectura_propuesta_id from public.propuesta_metrica_secuencia p
		where p.via <> 'sin_tipo' and p.arquitectura_propuesta_id is not null
	)
	order by g.arquitectura_id, g.orden
`;

/** Las arquitecturas activas de cada forma, para cuando el término viejo no dice cuál. */
const SQL_ARQUITECTURAS = `
	select a.forma_id, a.arquitectura_id, a.nombre, a.principal, a.orden
	from public.arquitecturas_forma a
	where a.activo
	order by a.forma_id, a.principal desc, a.orden
`;

const SQL_OPCIONES = `
	select o.opcion_eleccion_id, o.grupo_eleccion_id, o.nombre, o.orden, o.posicion_unidad,
		e.tipo_rima_id
	from public.opciones_eleccion_metrica o
	left join public.esquemas_rima e on e.esquema_rima_id = o.esquema_rima_id
	where o.activo and o.grupo_eleccion_id in (
		select g.grupo_eleccion_id from public.grupos_eleccion_metrica_resueltos g
		where g.activo and g.arquitectura_id in (
			select distinct p.arquitectura_propuesta_id from public.propuesta_metrica_secuencia p
			where p.via <> 'sin_tipo' and p.arquitectura_propuesta_id is not null
		)
	)
	order by o.grupo_eleccion_id, o.orden, o.nombre
`;

/**
 * Lo que la migración ya sabe responder, y de dónde lo saca: `anotada` es lo que alguien miró
 * verso a verso y se traslada; `derivada` se deduce del término legado y se enseña para confirmar.
 */
const SQL_RESPUESTAS = `
	select r.secuencia_id, r.grupo_eleccion_id, r.pregunta, r.opcion_eleccion_id, r.respuesta,
		r.alcance, r.unidad_v_ini, r.unidad_v_fin, r.origen,
		e.tipo_rima_id
	from public.propuesta_elecciones_secuencia r
	join public.propuesta_metrica_secuencia p on p.secuencia_id = r.secuencia_id and p.via <> 'sin_tipo'
	left join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
	left join public.esquemas_rima e on e.esquema_rima_id = o.esquema_rima_id
	order by r.secuencia_id, r.unidad_v_ini
`;

// --------------------------------------------------------------------------
// Montaje
// --------------------------------------------------------------------------

export function slugify(texto) {
	return String(texto)
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.slice(0, 80);
}

const agrupar = (filas, clave) => {
	const grupos = new Map();
	for (const fila of filas) {
		const lista = grupos.get(fila[clave]) ?? [];
		lista.push(fila);
		grupos.set(fila[clave], lista);
	}
	return grupos;
};

/**
 * Lee la base y devuelve una lista de obras, cada una con sus secuencias ya completas: unidades,
 * preguntas, respuestas, diagnóstico y las filas del cuestionario.
 */
export function cargarObras() {
	const secuencias = query(SQL_SECUENCIAS);
	const subtipos = query(SQL_SUBTIPOS);
	const caracterizaciones = query(SQL_CARACTERIZACIONES);
	const jornadas = query(SQL_JORNADAS);
	const cuadros = query(SQL_CUADROS);
	const preguntas = query(SQL_PREGUNTAS);
	const opciones = query(SQL_OPCIONES);
	const respuestas = query(SQL_RESPUESTAS);
	const arquitecturas = query(SQL_ARQUITECTURAS);
	const arquitecturasPorForma = agrupar(arquitecturas, 'forma_id');
	const { porId: catalogoPorId } = cargarCatalogo();

	const opcionesPorGrupo = agrupar(opciones, 'grupo_eleccion_id');
	const preguntasPorArquitectura = new Map();
	for (const fila of preguntas) {
		const lista = preguntasPorArquitectura.get(fila.arquitectura_id) ?? [];
		lista.push({ ...fila, opciones: opcionesPorGrupo.get(fila.grupo_eleccion_id) ?? [] });
		preguntasPorArquitectura.set(fila.arquitectura_id, lista);
	}
	const subtiposPorSecuencia = agrupar(subtipos, 'secuencia_id');
	const caracterizacionesPorSecuencia = agrupar(caracterizaciones, 'secuencia_id');
	const respuestasPorSecuencia = agrupar(respuestas, 'secuencia_id');
	const jornadasPorObra = agrupar(jornadas, 'obra_id');
	const cuadrosPorObra = agrupar(cuadros, 'obra_id');

	for (const s of secuencias) {
		s.v_ini = Number(s.v_ini);
		s.v_fin = Number(s.v_fin);
		s.n_versos = Number(s.n_versos);
		s.subtipos = subtiposPorSecuencia.get(s.secuencia_id) ?? [];
		s.caracterizaciones = caracterizacionesPorSecuencia.get(s.secuencia_id) ?? [];
		s.respuestas = respuestasPorSecuencia.get(s.secuencia_id) ?? [];
		s.preguntas = preguntasPorArquitectura.get(s.arquitectura_propuesta_id) ?? [];
		// Sin arquitectura propuesta —el término escueto `irregular`— hay que preguntar cuál es, y
		// de paso lo que todas las arquitecturas de la forma preguntan por igual, por nombre.
		if (!s.arquitectura_propuesta_id && s.forma_propuesta_id) {
			s.arquitecturas_de_forma = arquitecturasPorForma.get(s.forma_propuesta_id) ?? [];
			const listas = s.arquitecturas_de_forma.map(
				(a) => preguntasPorArquitectura.get(a.arquitectura_id) ?? []
			);
			s.preguntas_comunes = (listas[0] ?? []).filter(
				(p) =>
					Number(p.selecciones_min) >= 1 &&
					listas.every((l) => l.some((q) => q.nombre === p.nombre))
			);
		}
		s.regla =
			s.modulo_versos != null
				? {
						minimo_versos: Number(s.minimo_versos),
						modulo_versos: Number(s.modulo_versos),
						residuo_versos: Number(s.residuo_versos),
						desplazamientos: s.desplazamientos ?? null,
						explicacion: s.explicacion,
						origen: s.regla_origen
					}
				: null;
		s.unidades = unidadesDe(s);
		s.diagnostico = diagnosticar(s);
		// **Lo que no se puede repartir en sus partes tampoco se puede anotar.** Una canción de
		// veintiséis versos son dos estancias completas y la forma pide tres: el total encaja con la
		// medida de la estancia, así que ninguna regla de longitud lo ve, y solo aparece al intentar
		// repartirlo. Se pregunta como se pregunta un rango que no cuadra.
		const arquitectura = catalogoPorId.get(s.arquitectura_propuesta_id);
		s.reparto_problema = arquitectura
			? (realizacionesDe(arquitectura, s.v_ini, s.v_fin).problema ?? null)
			: null;

		// Lo que el catálogo obliga a responder y la migración no sabe: nombre a nombre.
		const respondidas = new Set(s.respuestas.map((r) => r.grupo_eleccion_id));
		// Una pregunta sobre una parte que puede no estar no cuenta como hueco: si el pasaje no la
		// lleva, no hay nada que responder. Tampoco la que depende de un régimen de rima que la
		// secuencia no tiene: las vocales de la asonancia de un pasaje consonante no existen.
		const afirmados = tiposDeRimaAfirmados(s.respuestas, [], s.preguntas);
		s.faltan = s.preguntas
			.filter(
				(p) =>
					Number(p.selecciones_min) >= 1 &&
					!respondidas.has(p.grupo_eleccion_id) &&
					!(p.seccion_id && Number(p.seccion_repeticiones_min) === 0) &&
					!(p.solo_si_tipo_rima_id && afirmados.size > 0 && !preguntaAplica(p, afirmados))
			)
			.map((p) => p.nombre);
		s.anotadas = s.respuestas.filter((r) => r.origen === 'anotada').length;
		s.derivadas = s.respuestas.filter((r) => r.origen === 'derivada').length;
		s.estado = !s.arquitectura_propuesta_id
			? 'sin arquitectura'
			: s.reparto_problema
				? 'no se reparte en sus partes'
				: s.faltan.length > 0
					? 'incompleta'
					: s.anotadas > 0
						? 'lista · con anotación'
						: 'lista';
	}

	const obras = [];
	for (const [obraId, filas] of agrupar(secuencias, 'obra_id')) {
		const jornadasObra = jornadasPorObra.get(obraId) ?? [];
		const cuadrosObra = cuadrosPorObra.get(obraId) ?? [];
		const cortes = [...jornadasObra, ...cuadrosObra].map((x) => Number(x.v_fin));
		const fundibles = tramosFundibles(filas, cortes);

		const cuestionario = { responder: [], confirmar: [], desviaciones: [] };
		for (const s of filas) {
			const de = filasDeSecuencia(s);
			cuestionario.responder.push(...de.responder);
			cuestionario.confirmar.push(...de.confirmar);
			cuestionario.desviaciones.push(...de.desviaciones);
		}
		for (const tramo of fundibles) {
			// Fundir se enseña resuelto y se confirma; lo que se escribe es la sinopsis del pasaje.
			const filas = filasDeFusion(tramo);
			cuestionario.confirmar.push(...filas.confirmar);
			cuestionario.responder.push(...filas.responder);

			// **Las partes de un tramo que se funde ya no son secuencias: son sus estrofas.** Sus
			// variedades se conservan, cada una en las suyas, y por eso se siguen confirmando; pero
			// si la fila no dice de qué pasaje forman parte, parecen cuatro secuencias que siguen ahí.
			const desde = Number(tramo[0].v_ini);
			const hasta = Number(tramo[tramo.length - 1].v_fin);
			const partes = new Set(tramo.map((p) => p.secuencia_id));
			for (const fila of cuestionario.confirmar) {
				if (!partes.has(fila.secuencia_id)) continue;
				if (fila.clave.startsWith('F|')) continue;
				fila.asunto = `${fila.asunto} · dentro del pasaje ${desde}–${hasta}`;
			}
		}

		obras.push({
			obra_id: obraId,
			titulo: filas[0].obra_titulo,
			// Las obras antiguas pueden no tener slug: el fichero se llama como el título.
			slug: filas[0].obra_slug || slugify(filas[0].obra_titulo),
			editor: filas[0].editor ?? null,
			secuencias: filas,
			subtipos: filas.flatMap((s) => s.subtipos),
			caracterizaciones: filas.flatMap((s) => s.caracterizaciones),
			jornadas: jornadasObra,
			cuadros: cuadrosObra,
			fundibles,
			cuestionario
		});
	}
	return obras;
}
