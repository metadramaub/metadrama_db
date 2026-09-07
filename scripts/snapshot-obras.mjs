/**
 * Foto fija de lo que hoy hay anotado, obra por obra.
 *
 * Un `pg_dump` sirve para restaurar y no sirve para mirar: son ochenta mil líneas de `insert`
 * con identificadores en crudo. Esto es lo otro: **un JSON por obra, legible y comparable**,
 * con todos los campos de todo lo que cuelga de ella y con los términos del vocabulario ya
 * resueltos a su nombre. Se hace antes de una migración que toque datos anotados, para poder
 * responder después a «¿qué decía esta secuencia el 7 de septiembre?» sin levantar una copia.
 *
 * No sustituye a la copia de seguridad: la acompaña. La copia se restaura; esto se lee y se
 * compara.
 *
 * Uso:
 *   node scripts/snapshot-obras.mjs
 *   node scripts/snapshot-obras.mjs --salida backups/obras/20260907
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ_POR_DEFECTO = fileURLToPath(new URL('../backups/obras', import.meta.url));

function parseArguments(argv) {
	const options = { salida: null };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--salida') options.salida = argv[index + 1] ?? null;
	}
	return options;
}

/** Marca de tiempo con el mismo formato que las copias de `backups/supabase`. */
function marcaDeTiempo() {
	const ahora = new Date();
	const dos = (valor) => String(valor).padStart(2, '0');
	return (
		`${ahora.getFullYear()}${dos(ahora.getMonth() + 1)}${dos(ahora.getDate())}` +
		`-${dos(ahora.getHours())}${dos(ahora.getMinutes())}${dos(ahora.getSeconds())}`
	);
}

// --------------------------------------------------------------------------
// La consulta
// --------------------------------------------------------------------------

/**
 * Una fila por obra, con todo lo suyo dentro.
 *
 * Cada bloque lleva **la fila entera** —`to_jsonb(t)`, no una lista de columnas— para que una
 * columna nueva entre sola en la foto y no haya que acordarse de este script al añadirla. Los
 * términos del vocabulario se añaden al lado, sin quitar el identificador: el nombre es para
 * leer y el identificador es para comparar.
 */
const SQL = `
with caracterizaciones as (
	select
		c.secuencia_id,
		jsonb_agg(
			to_jsonb(c) || jsonb_build_object('tipo', v.termino, 'tipo_etiqueta', v.etiqueta)
			order by c.v_ini, v.termino
		) as filas
	from public.secuencias_caracterizaciones_rango c
	left join public.vocabularios v on v.termino_id = c.tipo_caracterizacion_rango_id
	group by c.secuencia_id
),
subtipos as (
	select
		s.secuencia_id,
		jsonb_agg(
			to_jsonb(s) || jsonb_build_object('subtipo', v.termino)
			order by s.v_ini, v.termino
		) as filas
	from public.secuencias_subtipos_estrofa s
	left join public.vocabularios v on v.termino_id = s.subtipo_estrofa_id
	group by s.secuencia_id
),
anotaciones as (
	select
		a.secuencia_id,
		jsonb_agg(
			to_jsonb(a)
			|| jsonb_build_object(
				'forma', f.nombre,
				'arquitectura', arq.nombre,
				'realizaciones', coalesce((
					select jsonb_agg(to_jsonb(r) order by r.orden)
					from public.anotacion_realizaciones r
					where r.anotacion_id = a.anotacion_id
				), '[]'::jsonb),
				'elecciones', coalesce((
					select jsonb_agg(to_jsonb(e))
					from public.anotacion_elecciones e
					where e.anotacion_id = a.anotacion_id
				), '[]'::jsonb),
				'desviaciones', coalesce((
					select jsonb_agg(to_jsonb(d) order by d.v_ini)
					from public.anotacion_desviaciones d
					where d.anotacion_id = a.anotacion_id
				), '[]'::jsonb)
			)
			order by a.orden, a.v_ini
		) as filas
	from public.anotaciones_metricas a
	left join public.formas_metricas f on f.forma_id = a.forma_id
	left join public.arquitecturas_forma arq on arq.arquitectura_id = a.arquitectura_id
	where a.secuencia_id is not null
	group by a.secuencia_id
),
secuencias as (
	select
		sm.obra_id,
		jsonb_agg(
			to_jsonb(sm)
			|| jsonb_build_object(
				'estrofa_tipo', est.termino,
				'caracterizaciones_rango', coalesce(c.filas, '[]'::jsonb),
				'subtipos_estrofa', coalesce(sub.filas, '[]'::jsonb),
				'anotacion_v2', coalesce(an.filas, '[]'::jsonb)
			)
			order by sm.v_ini
		) as filas
	from public.secuencias_metricas sm
	left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
	left join caracterizaciones c on c.secuencia_id = sm.secuencia_id
	left join subtipos sub on sub.secuencia_id = sm.secuencia_id
	left join anotaciones an on an.secuencia_id = sm.secuencia_id
	group by sm.obra_id
),
atribuciones as (
	select
		a.obra_id,
		jsonb_agg(
			to_jsonb(a)
			|| jsonb_build_object(
				'autores', coalesce((
					select jsonb_agg(jsonb_build_object('autor', au.nombre_completo, 'orden', aa.orden) order by aa.orden)
					from public.atribucion_autores aa
					join public.autores au on au.autor_id = aa.autor_id
					where aa.atribucion_id = a.atribucion_id
				), '[]'::jsonb),
				'evidencias', coalesce((
					select jsonb_agg(to_jsonb(ev) order by ev.orden)
					from public.atribucion_evidencias ev
					where ev.atribucion_id = a.atribucion_id
				), '[]'::jsonb)
			)
		) as filas
	from public.atribuciones a
	group by a.obra_id
)
select
	o.obra_id,
	o.slug,
	o.titulo,
	to_jsonb(o)
	|| jsonb_build_object(
		'estado', estado.termino,
		'genero', genero.termino,
		'editor_asignado_nombre', ed.nombre_completo,
		'jornadas', coalesce((
			select jsonb_agg(
				to_jsonb(j) || jsonb_build_object('cuadros', coalesce((
					select jsonb_agg(to_jsonb(cu) order by cu.cuadro_num)
					from public.cuadros cu where cu.jornada_id = j.jornada_id
				), '[]'::jsonb))
				order by j.jornada_num
			)
			from public.jornadas j where j.obra_id = o.obra_id
		), '[]'::jsonb),
		'secuencias', coalesce(s.filas, '[]'::jsonb),
		'atribuciones', coalesce(atr.filas, '[]'::jsonb),
		'comentarios_internos', coalesce((
			select jsonb_agg(to_jsonb(ci) order by ci.created_at)
			from public.comentarios_internos ci where ci.obra_id = o.obra_id
		), '[]'::jsonb),
		'revisores', coalesce((
			select jsonb_agg(to_jsonb(orv))
			from public.obras_revisores orv where orv.obra_id = o.obra_id
		), '[]'::jsonb),
		'resumen_publico', (
			select to_jsonb(r) from public.obras_resumen r where r.obra_id = o.obra_id
		)
	) as documento
from public.obras o
left join public.vocabularios estado on estado.termino_id = o.estado
left join public.vocabularios genero on genero.termino_id = o.genero_id
left join public.editores ed on ed.user_id = o.editor_asignado
left join secuencias s on s.obra_id = o.obra_id
left join atribuciones atr on atr.obra_id = o.obra_id
order by o.titulo
`;

// --------------------------------------------------------------------------
// Escritura
// --------------------------------------------------------------------------

const options = parseArguments(process.argv.slice(2));
const destino = options.salida ?? join(RAIZ_POR_DEFECTO, marcaDeTiempo());
mkdirSync(destino, { recursive: true });

const filas = query(SQL);

/** Dos obras pueden compartir título; el fichero se nombra por slug, que es único. */
function nombreDeFichero(fila, usados) {
	const base = fila.slug || fila.obra_id;
	let nombre = base;
	let sufijo = 2;
	while (usados.has(nombre)) {
		nombre = `${base}-${sufijo}`;
		sufijo += 1;
	}
	usados.add(nombre);
	return `${nombre}.json`;
}

const usados = new Set();
const indice = [];

for (const fila of filas) {
	const fichero = nombreDeFichero(fila, usados);
	writeFileSync(join(destino, fichero), `${JSON.stringify(fila.documento, null, '\t')}\n`, 'utf-8');
	const documento = fila.documento;
	indice.push({
		titulo: fila.titulo,
		fichero,
		estado: documento.estado,
		secuencias: documento.secuencias.length,
		caracterizaciones: documento.secuencias.reduce(
			(total, secuencia) => total + secuencia.caracterizaciones_rango.length,
			0
		),
		anotaciones_v2: documento.secuencias.reduce(
			(total, secuencia) => total + secuencia.anotacion_v2.length,
			0
		)
	});
}

writeFileSync(
	join(destino, 'indice.json'),
	`${JSON.stringify({ tomada_el: new Date().toISOString(), obras: indice }, null, '\t')}\n`,
	'utf-8'
);

const totales = indice.reduce(
	(acumulado, obra) => ({
		secuencias: acumulado.secuencias + obra.secuencias,
		caracterizaciones: acumulado.caracterizaciones + obra.caracterizaciones,
		anotaciones: acumulado.anotaciones + obra.anotaciones_v2
	}),
	{ secuencias: 0, caracterizaciones: 0, anotaciones: 0 }
);

console.log(`Foto de ${indice.length} obras en ${destino}`);
console.log(
	`  ${totales.secuencias} secuencias · ${totales.caracterizaciones} caracterizaciones por rango · ${totales.anotaciones} anotaciones V2`
);
