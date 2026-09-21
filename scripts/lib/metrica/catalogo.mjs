/**
 * El catálogo métrico tal como lo necesita quien escribe una anotación: cada arquitectura activa
 * con su forma, la extensión de su unidad, sus secciones y sus preguntas con opciones.
 *
 * Lo comparten la siembra de las obras de prueba y la migración de las anotadas. Se devuelve por
 * dos llaves: por nombre —`forma/arquitectura`, que es como habla un guion— y por identificador,
 * que es como habla la propuesta de migración.
 */

import { query } from '../consulta.mjs';

export function cargarCatalogo() {
	const arquitecturas = query(`
		select
			a.arquitectura_id, a.slug as arquitectura, a.unidad_versos_min, a.unidad_versos_max,
			f.forma_id, f.slug as forma, r.modulo_versos
		from public.arquitecturas_forma a
		join public.formas_metricas f using (forma_id)
		left join public.arquitecturas_reglas_longitud r using (arquitectura_id)
		where a.activo and f.activo
	`);

	const secciones = query(`
		select
			s.seccion_id, s.arquitectura_id, s.seccion_padre_id, s.slug, s.nombre, s.orden,
			s.repeticiones_min, s.repeticiones_max, s.versos_min, s.versos_max
		from public.estructuras_secciones s
		order by s.arquitectura_id, s.orden
	`);

	const grupos = query(`
		select
			g.grupo_eleccion_id, g.arquitectura_id, g.nombre, g.dimension, g.alcance,
			g.seccion_id, g.seccion_tratada_id, g.selecciones_min, g.selecciones_max,
			g.solo_si_tipo_rima_id,
			sec.nombre as seccion_nombre, sec.repeticiones_min as seccion_repeticiones_min
		from public.grupos_eleccion_metrica_resueltos g
		left join public.estructuras_secciones sec on sec.seccion_id = g.seccion_id
		where g.activo
		order by g.arquitectura_id, g.orden
	`);

	// El régimen de cada disposición viaja con la opción: es lo que decide si una pregunta
	// condicionada —hoy las vocales de la asonancia— llega a hacerse.
	const opciones = query(`
		select
			o.opcion_eleccion_id, o.grupo_eleccion_id, o.nombre, o.orden, o.posicion_unidad,
			er.tipo_rima_id
		from public.opciones_eleccion_metrica o
		left join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		where o.activo
		order by o.grupo_eleccion_id, o.orden, o.nombre
	`);

	const porId = new Map();
	for (const a of arquitecturas) porId.set(a.arquitectura_id, { ...a, secciones: [], grupos: [] });
	for (const s of secciones) porId.get(s.arquitectura_id)?.secciones.push(s);
	const porGrupo = new Map();
	for (const g of grupos) {
		const a = porId.get(g.arquitectura_id);
		if (!a) continue;
		const entrada = { ...g, opciones: [] };
		a.grupos.push(entrada);
		porGrupo.set(g.grupo_eleccion_id, entrada);
	}
	for (const o of opciones) porGrupo.get(o.grupo_eleccion_id)?.opciones.push(o);

	const porNombre = new Map();
	for (const a of porId.values()) porNombre.set(`${a.forma}/${a.arquitectura}`, a);
	return { porNombre, porId };
}
