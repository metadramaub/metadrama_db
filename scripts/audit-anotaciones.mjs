/**
 * Si el catálogo se mueve, ¿qué se llevó por delante de lo ya anotado?
 *
 * Desde C20 una respuesta **se describe a sí misma** —dice qué afirma, no a qué pregunta
 * contesta— y la pregunta se deriva al leerla. Eso es lo que permite corregir el catálogo sin
 * reescribir lo anotado, pero abre la puerta a lo contrario: que una corrección deje una
 * respuesta sin pregunta a la que volver, o le quite la opción que el editor eligió. El dato
 * seguiría en la base y **no se vería en ninguna pantalla**, que es la peor forma de perderlo.
 *
 * Este informe recorre lo anotado y busca ese desajuste, diciendo siempre **en qué obra y quién
 * lo anotó**, porque decidir si el cambio es aceptable no es una cuestión técnica: hay que
 * contrastarlo con la obra y con quien la leyó.
 *
 * Se pasa **después** de tocar el catálogo, no antes. Antes no hay nada que medir.
 *
 * Uso:
 *   npm run audit:anotaciones
 *   node scripts/audit-anotaciones.mjs --markdown docs/dominio-metrico/informe-anotaciones.md
 *   node scripts/audit-anotaciones.mjs --comprobar   ← ¿de verdad ve el daño?
 */

import { writeFileSync } from 'node:fs';
import { query } from './lib/consulta.mjs';

const opciones = { markdown: null, comprobar: false };
for (let i = 0; i < process.argv.length; i += 1) {
	if (process.argv[i] === '--markdown') opciones.markdown = process.argv[i + 1] ?? null;
	if (process.argv[i] === '--comprobar') opciones.comprobar = true;
}

const SQL_HALLAZGOS = `
with anotada as (
	select
		am.anotacion_id,
		am.arquitectura_id,
		am.v_ini,
		am.v_fin,
		am.updated_at,
		am.secuencia_id,
		coalesce(o.titulo, '(fuera de una obra)') as obra,
		coalesce(f.nombre, 'tramo sin forma') as forma,
		coalesce(a.nombre, '—') as arquitectura,
		coalesce(f.activo, true) as forma_activa,
		coalesce(a.activo, true) as arquitectura_activa,
		coalesce(ed.nombre_completo, ea.nombre_completo, '(sin registrar)') as editor
	from public.anotaciones_metricas am
	left join public.secuencias_metricas sm on sm.secuencia_id = am.secuencia_id
	left join public.obras o on o.obra_id = sm.obra_id
	left join public.editores ed on ed.user_id = am.created_by
	left join public.editores ea on ea.user_id = o.editor_asignado
	left join public.formas_metricas f on f.forma_id = am.forma_id
	left join public.arquitecturas_forma a on a.arquitectura_id = am.arquitectura_id
),
esperadas as (
	-- Lo que la arquitectura exige **hoy**, unidad por unidad. La condición que empareja una
	-- pregunta con una realización es la misma que comprueba \`validar_anotacion_eleccion\`: una
	-- pregunta de una parte solo alcanza a las unidades interiores de esa parte.
	select
		an.anotacion_id,
		g.grupo_eleccion_id,
		gr.nombre as pregunta,
		rz.realizacion_id
	from anotada an
	join public.preguntas_metricas g
		on g.arquitectura_id = an.arquitectura_id
		and g.activo
		and g.selecciones_min >= 1
	join public.grupos_eleccion_metrica_resueltos gr on gr.grupo_eleccion_id = g.grupo_eleccion_id
	left join public.anotacion_realizaciones rz
		on rz.anotacion_id = an.anotacion_id
		and g.alcance <> 'secuencia'
		and g.seccion_id is not distinct from (
			case when rz.realizacion_padre_id is not null then rz.seccion_id end
		)
	where g.alcance = 'secuencia' or rz.realizacion_id is not null
),
hallazgo as (
	-- 1 · La respuesta afirma algo que su arquitectura ya no pregunta. Grave: el dato está
	-- guardado y no hay pantalla que lo enseñe.
	select
		'respuesta sin pregunta' as tipo,
		1 as gravedad,
		r.anotacion_id,
		r.dimension || ': ' || coalesce(
			m.nombre, er.nombre, em.nombre, s.nombre, rep.nombre, rv.nombre, va.nombre,
			r.valor_texto, '(sin nombre)'
		) as detalle
	from public.anotacion_elecciones_resueltas r
	left join public.metros m on m.metro_id = r.metro_id
	left join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	left join public.esquemas_metricos em on em.esquema_metrico_id = r.esquema_metrico_id
	left join public.estructuras_secciones s on s.seccion_id = r.seccion_id
	left join public.repeticiones_metricas rep on rep.repeticion_id = r.repeticion_id
	left join public.rasgo_valores rv on rv.valor_id = r.valor_rasgo_id
	left join public.variedades_arquitectura va on va.variedad_id = r.variedad_id
	where r.grupo_eleccion_id is null

	union all

	-- 2 · La pregunta sigue en pie, pero lo elegido ya no está entre lo que ofrece. Una respuesta
	-- escrita a mano no tiene opción y no cuenta.
	select
		'respuesta fuera del repertorio',
		1,
		r.anotacion_id,
		gr.nombre
	from public.anotacion_elecciones_resueltas r
	join public.grupos_eleccion_metrica_resueltos gr on gr.grupo_eleccion_id = r.grupo_eleccion_id
	where r.opcion_eleccion_id is null and r.valor_texto is null

	union all

	-- 3 · Al revés: el catálogo pide algo que cuando se anotó no se pedía. No se pierde nada,
	-- pero la anotación queda incompleta y nadie va a volver sobre ella si no se dice.
	select
		'pregunta obligatoria sin responder',
		2,
		e.anotacion_id,
		e.pregunta
	from esperadas e
	where not exists (
		select 1
		from public.anotacion_elecciones_resueltas r
		where r.anotacion_id = e.anotacion_id
			and r.grupo_eleccion_id = e.grupo_eleccion_id
			and r.realizacion_id is not distinct from e.realizacion_id
	)

	union all

	-- 4 · La secuencia entera apunta a algo retirado del catálogo.
	select
		'forma o arquitectura retirada',
		1,
		an.anotacion_id,
		an.forma || ' · ' || an.arquitectura
	from anotada an
	where not an.forma_activa or not an.arquitectura_activa

	union all

	-- 5 · Y lo que la respuesta nombra puede haberse desactivado por su lado, aunque la pregunta
	-- siga: un metro, un valor de rasgo o una variedad.
	select
		'la respuesta nombra algo desactivado',
		1,
		e.anotacion_id,
		coalesce(m.nombre, rv.nombre, va.nombre, '(sin nombre)')
	from public.anotacion_elecciones e
	left join public.metros m on m.metro_id = e.metro_id and not m.activo
	left join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id and not rv.activo
	left join public.variedades_arquitectura va on va.variedad_id = e.variedad_id and not va.activo
	where m.metro_id is not null or rv.valor_id is not null or va.variedad_id is not null

	union all

	-- 6 · Lo mismo para lo observado en una desviación, que también nombra el catálogo.
	select
		'una desviación nombra algo desactivado',
		2,
		d.anotacion_id,
		coalesce(m.nombre, rv.nombre, '(sin nombre)')
	from public.anotacion_desviaciones d
	left join public.metros m on m.metro_id = d.metro_observado_id and not m.activo
	left join public.rasgo_valores rv on rv.valor_id = d.valor_rasgo_observado_id and not rv.activo
	where m.metro_id is not null or rv.valor_id is not null
)
select
	h.tipo,
	h.gravedad,
	h.detalle,
	an.obra,
	an.forma,
	an.arquitectura,
	an.editor,
	an.v_ini,
	an.v_fin,
	to_char(an.updated_at, 'YYYY-MM-DD') as fecha
from hallazgo h
join anotada an on an.anotacion_id = h.anotacion_id
order by h.gravedad, h.tipo, an.obra, an.v_ini
`;

// ---------------------------------------------------------------------------------------------
// Un informe que nunca ha encontrado nada no está probado
//
// Mientras el catálogo esté sano el informe sale vacío, y un informe vacío se parece mucho a uno
// roto. Cada sonda **rompe una cosa a propósito** dentro de una transacción que se deshace, y
// comprueba que el aviso que le toca aparece. No escribe nada: el `rollback` va en la misma
// llamada que el daño, así que si algo fallara por el camino la base tampoco se quedaría tocada.
// ---------------------------------------------------------------------------------------------

const SONDAS = [
	{
		aviso: 'respuesta sin pregunta',
		explica: 'se retira una pregunta que ya tenía respuestas',
		dano: `update public.grupos_eleccion_metrica set activo = false
			where grupo_eleccion_id in (
				select grupo_eleccion_id from public.anotacion_elecciones_resueltas
				where grupo_eleccion_id is not null
			)`
	},
	{
		aviso: 'respuesta fuera del repertorio',
		explica: 'un esquema elegido pasa a patrón abierto y deja de ofrecerse',
		dano: `update public.esquemas_rima set tipo_secuencia = 'abierta'
			where esquema_rima_id in (
				select esquema_rima_id from public.anotacion_elecciones where esquema_rima_id is not null
			)`
	},
	{
		aviso: 'pregunta obligatoria sin responder',
		explica: 'una pregunta opcional se vuelve obligatoria',
		dano: `update public.grupos_eleccion_metrica set selecciones_min = 1 where selecciones_min = 0`
	},
	{
		aviso: 'forma o arquitectura retirada',
		explica: 'se desactiva una arquitectura que alguien ya anotó',
		dano: `update public.arquitecturas_forma set activo = false
			where arquitectura_id in (
				select arquitectura_id from public.anotaciones_metricas where arquitectura_id is not null
			)`
	},
	{
		aviso: 'la respuesta nombra algo desactivado',
		explica: 'se desactiva un metro que una respuesta nombra',
		dano: `update public.metros set activo = false
			where metro_id in (
				select metro_id from public.anotacion_elecciones where metro_id is not null
			)`
	},
	{
		aviso: 'una desviación nombra algo desactivado',
		explica: 'se desactiva un metro que una desviación observa',
		// No hay ninguna desviación todavía, así que la sonda se fabrica la suya.
		dano: `insert into public.anotacion_desviaciones
				(anotacion_id, v_ini, v_fin, dimension, relacion_norma, metro_observado_id)
			select am.anotacion_id, am.v_ini, am.v_ini, 'metro', 'menor_que_norma', m.metro_id
			from public.anotaciones_metricas am
			cross join lateral (select metro_id from public.metros where activo limit 1) m
			limit 1;
			update public.metros set activo = false
			where metro_id in (
				select metro_observado_id from public.anotacion_desviaciones
				where metro_observado_id is not null
			)`
	}
];

if (opciones.comprobar) {
	let fallos = 0;
	console.log('Sondas: se rompe algo a propósito y se deshace.\n');
	for (const sonda of SONDAS) {
		const filas = query(
			`begin;\n${sonda.dano};\n` +
				`select tipo, count(*)::int as cuantos from (${SQL_HALLAZGOS}) hallado group by tipo;\n` +
				`rollback;`
		);
		const vista = filas.find((fila) => fila.tipo === sonda.aviso);
		if (vista) {
			console.log(`  ok  ${sonda.aviso} — ${sonda.explica} (${vista.cuantos})`);
		} else {
			fallos += 1;
			console.log(`  NO  ${sonda.aviso} — ${sonda.explica}: no lo ha visto`);
			console.log(`      lo que vio: ${filas.map((f) => f.tipo).join(', ') || 'nada'}`);
		}
	}
	const intactas = query(
		`select count(*)::int as desviaciones from public.anotacion_desviaciones`
	)[0];
	console.log(`\nLa base queda como estaba: ${intactas.desviaciones} desviaciones.`);
	process.exit(fallos === 0 ? 0 : 1);
}

const hallazgos = query(SQL_HALLAZGOS);

const censo = query(`
	select
		count(*) as anotaciones,
		count(*) filter (where am.secuencia_id is not null) as en_obras,
		count(distinct sm.obra_id) as obras,
		(select count(*) from public.anotacion_elecciones) as respuestas,
		(select count(*) from public.anotacion_desviaciones) as desviaciones
	from public.anotaciones_metricas am
	left join public.secuencias_metricas sm on sm.secuencia_id = am.secuencia_id
`)[0];

const GRAVE = 'lo anotado ya no se puede leer entero';
const LEVE = 'lo anotado se lee, pero se ha quedado corto';

const porTipo = new Map();
for (const hallazgo of hallazgos) {
	const entrada = porTipo.get(hallazgo.tipo) ?? { gravedad: hallazgo.gravedad, filas: [] };
	entrada.filas.push(hallazgo);
	porTipo.set(hallazgo.tipo, entrada);
}

const lineas = [];
lineas.push('# Lo anotado frente al catálogo de hoy');
lineas.push('');
lineas.push('Generado por `npm run audit:anotaciones`. Una respuesta no guarda a qué pregunta');
lineas.push(
	'contesta: dice qué afirma, y la pregunta se deriva al leerla. Este informe busca dónde'
);
lineas.push('esa derivación ya no llega, que es como se pierde un dato sin que nadie lo note.');
lineas.push('');
lineas.push(
	`**${censo.anotaciones} anotaciones** —${censo.en_obras} dentro de una obra, repartidas por ` +
		`${censo.obras}—, con ${censo.respuestas} respuestas y ${censo.desviaciones} desviaciones.`
);
lineas.push('');

if (hallazgos.length === 0) {
	lineas.push('**Todo lo anotado encaja con el catálogo de hoy.** Ninguna respuesta se ha quedado');
	lineas.push('sin pregunta, ninguna elección fuera de su repertorio y ninguna anotación');
	lineas.push('incompleta por una pregunta que llegó después.');
} else {
	lineas.push('## Resumen');
	lineas.push('');
	lineas.push('| qué pasa | cuántas | qué significa |');
	lineas.push('|---|---|---|');
	for (const [tipo, { gravedad, filas }] of porTipo) {
		lineas.push(`| ${tipo} | ${filas.length} | ${gravedad === 1 ? GRAVE : LEVE} |`);
	}
	lineas.push('');
	for (const [tipo, { filas }] of porTipo) {
		lineas.push(`## ${tipo[0].toUpperCase()}${tipo.slice(1)}`);
		lineas.push('');
		lineas.push('| obra | versos | forma · arquitectura | qué | lo anotó | última vez |');
		lineas.push('|---|---|---|---|---|---|');
		for (const fila of filas) {
			lineas.push(
				`| ${fila.obra} | ${fila.v_ini}–${fila.v_fin} | ${fila.forma} · ${fila.arquitectura} |` +
					` ${fila.detalle} | ${fila.editor} | ${fila.fecha} |`
			);
		}
		lineas.push('');
	}
}

const texto = lineas.join('\n') + '\n';

if (opciones.markdown) {
	writeFileSync(opciones.markdown, texto, 'utf-8');
	console.log(`Escrito ${opciones.markdown}`);
}

console.log(
	`${censo.anotaciones} anotaciones · ${censo.respuestas} respuestas · ${hallazgos.length} desajustes`
);
for (const [tipo, { gravedad, filas }] of porTipo) {
	console.log(`  ${gravedad === 1 ? '!!' : ' ·'} ${tipo}: ${filas.length}`);
}
if (hallazgos.length === 0) console.log('  Todo encaja con el catálogo de hoy.');

process.exitCode = hallazgos.some((hallazgo) => hallazgo.gravedad === 1) ? 1 : 0;
