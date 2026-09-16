/**
 * Comprueba que un dictamen de la pasada D juzga el texto que el catálogo tiene de verdad.
 *
 * **Por qué existe.** Toda la auditoría contrasta la fuente contra la ficha dando por supuesto que
 * la ficha, al menos, se lee bien. El 20 de septiembre se vio que no: un verificador de la pasada A
 * citó nuestro propio resumen con una frase que la ficha nunca tuvo —«establece como únicas
 * distribuciones posibles», donde dice «da como distribuciones más frecuentes»— y diagnosticó, con
 * todo rigor y con su cita literal de la fuente en la mano, un endurecimiento grave **contra un
 * texto inexistente**. La afirmación se salvó por casualidad, porque una segunda pasada la leyó bien
 * y la contradicción la dejó aparcada en vez de migrada.
 *
 * Cada lectura de la pasada D lleva por eso un campo `eco` con el resumen copiado carácter por
 * carácter. Esto lo compara con la base. **Si no coincide, el dictamen entero de esa afirmación no
 * vale**: no se discute qué encontró, porque no estaba mirando nuestro texto.
 *
 * Se comprueba también lo que sostiene la tabla:
 *
 * - toda cláusula con `esta: "sí"` trae `fragmento`, y toda cláusula con `esta: "no"` trae
 *   `que_busque`. Sin eso, un cero no es un resultado sino una casilla vacía;
 * - las cláusulas, juntas, cubren el resumen. Una descomposición que se deja fuera media ficha
 *   pasa por completa y nadie lo nota: se mide qué proporción de las palabras del resumen aparecen
 *   en alguna cláusula.
 *
 * Lo que este script NO hace: decir si el verificador acierta. Solo si estaba leyendo lo que decía
 * leer, y si su tabla se sostiene. Que los fragmentos existan en la fuente lo comprueba
 * `valida-dictamenes.mjs`, que sirve igual para esta carpeta.
 *
 * Uso:
 *   node scripts/auditoria-fuentes/valida-pasada-d.mjs
 */

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from '../lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('../..', import.meta.url));
const CARPETA = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes', 'dictamenes-d');

/** Cobertura mínima del resumen por el conjunto de cláusulas, en palabras. */
const COBERTURA_MINIMA = 0.6;

const palabras = (t) =>
	String(t ?? '')
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, ' ')
		.trim()
		.split(' ')
		.filter(Boolean);

if (!existsSync(CARPETA)) {
	console.log('No hay dictámenes de la pasada D todavía.');
	process.exit(0);
}

const enLaBase = new Map(
	query(
		`select left(afirmacion_id::text, 8) as id, resumen from public.afirmaciones_fuentes_metricas`
	).map((r) => [r.id, r.resumen])
);

const problemas = [];
let lecturas = 0;
let clausulas = 0;

for (const fichero of readdirSync(CARPETA).filter((f) => f.endsWith('.json'))) {
	let dictamen;
	try {
		dictamen = JSON.parse(readFileSync(join(CARPETA, fichero), 'utf-8'));
	} catch (error) {
		problemas.push(`${fichero}: no es JSON válido — ${error.message}`);
		continue;
	}
	for (const lectura of dictamen.lecturas ?? []) {
		lecturas += 1;
		const id = lectura.id;
		const suyo = enLaBase.get(id);

		if (!suyo) {
			problemas.push(`${fichero} · ${id}: no existe esa afirmación en la base.`);
			continue;
		}
		// El eco: sin normalizar nada, que es justo lo que se está comprobando.
		if (lectura.eco !== suyo) {
			problemas.push(
				`${fichero} · ${id}: **el eco no coincide con la ficha**. El dictamen no vale.\n` +
					`      base: ${suyo.slice(0, 110)}…\n` +
					`      eco : ${String(lectura.eco ?? '').slice(0, 110)}…`
			);
			continue;
		}

		const suyas = lectura.clausulas ?? [];
		if (!suyas.length) {
			problemas.push(`${fichero} · ${id}: no descompone en cláusulas.`);
			continue;
		}
		for (const c of suyas) {
			clausulas += 1;
			const esta = String(c.esta ?? '').toLowerCase();
			if (esta === 'sí' || esta === 'si') {
				if (!String(c.fragmento ?? '').trim())
					problemas.push(`${fichero} · ${id}: una cláusula dice «sí» y no trae fragmento.`);
			} else if (esta === 'no') {
				if (!String(c.que_busque ?? '').trim())
					problemas.push(`${fichero} · ${id}: una cláusula dice «no» y no dice qué buscó.`);
			} else {
				problemas.push(`${fichero} · ${id}: una cláusula tiene «esta» = «${c.esta}».`);
			}
		}

		// Que la descomposición cubra el resumen: se mide sobre las palabras, no sobre las frases.
		const delResumen = new Set(palabras(suyo));
		const cubiertas = new Set();
		for (const c of suyas) for (const p of palabras(c.clausula)) if (delResumen.has(p)) cubiertas.add(p);
		const cobertura = delResumen.size ? cubiertas.size / delResumen.size : 1;
		if (cobertura < COBERTURA_MINIMA)
			problemas.push(
				`${fichero} · ${id}: las cláusulas solo cubren el ${Math.round(cobertura * 100)} % del resumen.`
			);
	}
}

console.log(`${lecturas} lecturas · ${clausulas} cláusulas`);
if (!problemas.length) {
	console.log('Todos los ecos coinciden y todas las tablas se sostienen.');
	process.exit(0);
}
console.log(`\n${problemas.length} problemas:\n`);
for (const p of problemas) console.log(`  · ${p}`);
process.exitCode = 1;
