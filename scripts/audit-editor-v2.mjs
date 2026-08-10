/**
 * Qué le pide el editor a cada forma.
 *
 * Elegir una forma debería llevar a una de dos cosas: que la secuencia quede registrada sin
 * preguntar nada, o que se pregunte lo justo y de la manera más cómoda. Este informe recorre las
 * 29 entradas del catálogo y cuenta, arquitectura por arquitectura, cuántas respuestas exige el
 * editor y de qué tipo, y señala lo que le hace trabajar de más.
 *
 * El patrón bueno, que el editor ya implementa, es **responder una vez para todas las unidades y
 * corregir después las que varían**: por eso una pregunta dentro de la unidad que no admita ese
 * atajo se cuenta como un defecto en cuanto la unidad puede repetirse.
 *
 * Uso:
 *   npm run audit:editor
 *   node scripts/audit-editor-v2.mjs --markdown docs/dominio-metrico/informe-editor.md
 */

import { writeFileSync } from 'node:fs';
import { query } from './lib/consulta.mjs';

const options = { markdown: null };
for (let i = 0; i < process.argv.length; i += 1) {
	if (process.argv[i] === '--markdown') options.markdown = process.argv[i + 1] ?? null;
}

const filas = query(`
	select
		f.slug as forma,
		f.nombre as forma_nombre,
		f.tipo_registro,
		a.slug as arquitectura,
		a.arquitectura_id,
		g.grupo_eleccion_id,
		g.slug as pregunta,
		g.nombre as pregunta_nombre,
		g.dimension,
		g.alcance,
		g.tipo_control,
		g.permite_aplicar_global,
		g.selecciones_min,
		g.selecciones_max,
		coalesce(s.slug, '') as seccion,
		coalesce(s.repeticiones_max::text, 'inf') as seccion_repeticiones_max,
		(
			select count(*) from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		) as opciones
	from public.formas_metricas f
	left join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.activo
	left join public.grupos_eleccion_metrica_resueltos g
		on g.arquitectura_id = a.arquitectura_id and g.activo
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	where f.activo
	order by f.nombre, a.slug, g.orden nulls last, g.slug
`);

/** Una unidad que puede darse más de una vez obliga a repetir la respuesta si no hay atajo. */
const seRepite = (fila) => fila.seccion_repeticiones_max === 'inf' || Number(fila.seccion_repeticiones_max) > 1;

const arquitecturas = new Map();
for (const fila of filas) {
	if (!fila.arquitectura) continue;
	const clave = String(fila.arquitectura_id);
	const entrada = arquitecturas.get(clave) ?? {
		forma: fila.forma,
		formaNombre: fila.forma_nombre,
		arquitectura: fila.arquitectura,
		preguntas: []
	};
	if (fila.grupo_eleccion_id) entrada.preguntas.push(fila);
	arquitecturas.set(clave, entrada);
}

const DEFECTOS = [
	{
		id: 'E1',
		titulo: 'Obligada a elegir la única opción',
		criterio:
			'Una pregunta con una sola opción y respuesta obligatoria no ofrece elección: el editor solo puede confirmar lo que el catálogo ya sabe, y eso se deriva. **No es el caso de la que admite cero respuestas**, que es un sí/no legítimo —«¿tiene final acentual destacado?»— donde marcarla o dejarla vacía es la respuesta.',
		detectar: (p) => Number(p.opciones) === 1 && Number(p.selecciones_min ?? 0) > 0
	},
	{
		id: 'E1b',
		titulo: 'Sí/no de una sola opción',
		criterio:
			'Se cuentan aparte porque en pantalla no deben verse como una lista de una opción sino como una casilla. Son legítimas; lo que no vale es pintarlas como si hubiera algo que elegir.',
		detectar: (p) => Number(p.opciones) === 1 && Number(p.selecciones_min ?? 0) === 0,
		informativo: true
	},
	{
		id: 'E2',
		titulo: 'Pregunta repetida sin atajo',
		criterio:
			'Una pregunta dentro de una sección que puede darse varias veces debe poder responderse una vez para todas y corregirse después donde varíe. Sin `permite_aplicar_global`, una composición de cuatro coplas exige cuatro respuestas para decir una cosa.',
		detectar: (p) =>
			p.alcance !== 'secuencia' && !p.permite_aplicar_global && p.seccion && seRepite(p)
	},
	{
		id: 'E3',
		titulo: 'Pregunta sin ninguna opción',
		criterio: 'Una pregunta activa que no ofrece nada es una pregunta imposible de responder.',
		detectar: (p) => Number(p.opciones) === 0 && p.tipo_control === 'opciones'
	},
	{
		id: 'E4',
		titulo: 'Pregunta obligatoria que el editor no puede saltarse',
		criterio:
			'Con `selecciones_min` mayor que cero la secuencia no se guarda sin responderla. Es legítimo, pero conviene tenerlas contadas: son el suelo de trabajo de cada forma.',
		detectar: (p) => Number(p.selecciones_min ?? 0) > 0,
		informativo: true
	}
];

const lineas = [];
const escribir = (texto = '') => lineas.push(texto);
const celda = (v) => String(v ?? '').replace(/\|/g, '\\|');

escribir('# Qué le pide el editor a cada forma');
escribir();
escribir(`Generado el ${new Date().toISOString().slice(0, 10)} desde la base enlazada.`);
escribir();

escribir('## 1 · Coste por forma');
escribir();
escribir('| Forma | Arquitectura | Una vez | En la unidad | Con atajo | Sin atajo |');
escribir('| --- | --- | ---: | ---: | ---: | ---: |');

let sinPreguntas = [];
for (const entrada of arquitecturas.values()) {
	const unaVez = entrada.preguntas.filter((p) => p.alcance === 'secuencia').length;
	const enUnidad = entrada.preguntas.filter((p) => p.alcance !== 'secuencia').length;
	const conAtajo = entrada.preguntas.filter((p) => p.permite_aplicar_global).length;
	const sinAtajo = enUnidad - conAtajo;
	if (entrada.preguntas.length === 0) {
		sinPreguntas.push(`${entrada.formaNombre} · ${entrada.arquitectura}`);
		continue;
	}
	escribir(
		`| ${celda(entrada.formaNombre)} | ${celda(entrada.arquitectura)} | ${unaVez} | ${enUnidad} | ${conAtajo} | ${sinAtajo} |`
	);
}
escribir();
escribir(
	`**${sinPreguntas.length} arquitecturas se registran sin preguntar nada**, que es el mejor caso posible: elegir la forma basta.`
);
if (sinPreguntas.length > 0) {
	escribir();
	for (const nombre of sinPreguntas) escribir(`- ${nombre}`);
}
escribir();

escribir('## 2 · Lo que hace trabajar de más');
escribir();

let total = 0;
for (const defecto of DEFECTOS) {
	const hallazgos = [];
	for (const entrada of arquitecturas.values()) {
		for (const pregunta of entrada.preguntas) {
			if (!defecto.detectar(pregunta)) continue;
			hallazgos.push({
				sujeto: `${entrada.formaNombre} · ${entrada.arquitectura}`,
				detalle: `${pregunta.pregunta} · ${pregunta.dimension} · ${pregunta.opciones} opciones · alcance ${pregunta.alcance}`
			});
		}
	}
	if (!defecto.informativo) total += hallazgos.length;
	escribir(`### ${defecto.id} · ${defecto.titulo} — ${hallazgos.length}`);
	escribir();
	escribir(`> ${defecto.criterio}`);
	escribir();
	if (hallazgos.length === 0) {
		escribir('Sin incidencias.');
	} else {
		escribir('| Dónde | Cuál |');
		escribir('| --- | --- |');
		for (const h of hallazgos) escribir(`| ${celda(h.sujeto)} | ${celda(h.detalle)} |`);
	}
	escribir();
}

escribir('---');
escribir();
escribir(`Total de defectos detectados: ${total}.`);

const texto = lineas.join('\n');
if (options.markdown) {
	writeFileSync(options.markdown, `${texto}\n`, 'utf-8');
	console.log(`Informe escrito en ${options.markdown} · ${total} defectos.`);
} else {
	console.log(texto);
}
