/**
 * La cuarta comprobación mecánica: **¿la ficha conserva la cautela de la fuente?**
 *
 * El endurecimiento —recoger como un hecho lo que la fuente dice con reservas— es, según el plan,
 * el defecto que una lectura puede pasar por alto tranquilamente, «porque el resumen sigue siendo
 * verdad *a medias*». Esta sesión lo confirmó dos veces en Navarro Tomás, que escribe «parece
 * renacer» y «parece casi enteramente desterrado» donde la ficha afirmaba sin más.
 *
 * Hasta ahora esa señal venía de la pasada B: si el lector ciego anotaba una cautela, quedaba
 * registrada en el cotejo. **Eso deja fuera todo lo que B no anotó**, que no es lo mismo que lo que
 * la fuente no dice. Esta comprobación no pregunta a nadie: compara el pasaje con el resumen.
 *
 * **Se ancla en lo que la ficha cita, no en el extracto entero.** La primera versión comparaba el
 * resumen con toda la ventana que el nivel 1 resolvió, y señalaba 57 de 104: cuatro fichas de
 * Morley y Bruerton salían con la misma lista de ocho cautelas, porque la ventana era la misma y
 * las palabras venían de párrafos vecinos. Una señal así no dice por dónde empezar: entierra los
 * casos reales entre los que no lo son.
 *
 * De modo que para cada afirmación:
 *
 *   1. se toman los fragmentos que la ficha **entrecomilla**, que son su vínculo literal con el
 *      libro;
 *   2. se busca cada uno en el extracto y se recorta **la oración que lo contiene**;
 *   3. se señala cuando esa oración matiza y el resumen no.
 *
 * Así la cautela que se cuenta es la de la frase que la ficha resume, no la del capítulo.
 *
 * **Siguen siendo candidatos, no veredictos**, y quedan fuera las fichas que no citan nada: ahí no
 * hay a qué anclarse y el defecto, si lo hay, tiene que encontrarlo una lectura. Lo que decide, como
 * siempre, es abrir el libro.
 *
 *   node scripts/senal-endurecimiento.mjs [--todas]
 *
 * Sin argumentos mira las que la hoja de correcciones tiene por conformes con comprobación
 * anotada, que es donde el defecto puede haberse quedado escondido. Con `--todas`, las 267.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = RAIZ + 'docs/dominio-metrico/auditoria-fuentes/';
const ANIOS = [1968, 1969, 1972, 2014, 2016, 2020];

/**
 * Marcas de cautela: verbos, adverbios y giros con que una fuente deja abierta su afirmación.
 *
 * La lista es deliberadamente amplia, porque el coste de un falso positivo es abrir un libro y el
 * de un falso negativo es publicar como hecho lo que su autor dio por probable.
 */
const CAUTELA = [
	/\bsuele[nsa]?\b/gi,
	/\bsolía[n]?\b/gi,
	/\bparece[nr]?\b/gi,
	/\bal parecer\b/gi,
	/\bnormalmente\b/gi,
	/\blo normal\b/gi,
	/\bgeneralmente\b/gi,
	/\ben general\b/gi,
	/\bpor lo (común|general)\b/gi,
	/\bde ordinario\b/gi,
	/\bordinariamente\b/gi,
	/\ba veces\b/gi,
	/\ba menudo\b/gi,
	/\bcon frecuencia\b/gi,
	/\bfrecuente(mente)?\b/gi,
	/\brara vez\b/gi,
	/\bocasional(mente)?\b/gi,
	/\bno es raro\b/gi,
	/\bno siempre\b/gi,
	/\bcasi siempre\b/gi,
	/\bhabitual(mente)?\b/gi,
	/\bmás corriente\b/gi,
	/\bquizá[s]?\b/gi,
	/\bacaso\b/gi,
	/\btiende[n]? a\b/gi,
	/\bpued[eo][n]?\b/gi,
	/\bpodía[n]?\b/gi,
	/\bdebió\b/gi,
	/\bse diría\b/gi,
	/\baunque\b/gi,
	/\bexcepcional(mente)?\b/gi
];

/** Las marcas que aparecen en un texto, una vez cada una, en orden de lectura. */
function cautelas(texto) {
	const halladas = new Map();
	for (const patron of CAUTELA) {
		for (const m of String(texto ?? '').matchAll(patron)) {
			const clave = m[0].toLowerCase();
			if (!halladas.has(clave)) halladas.set(clave, m.index);
		}
	}
	return [...halladas.entries()].sort((a, b) => a[1] - b[1]).map(([palabra]) => palabra);
}

// ─────────────────────────────────────────────────────────────────── Los datos

const soloConformes = !process.argv.includes('--todas');

const decisiones = (() => {
	const crudo = JSON.parse(readFileSync(BASE + 'decisiones.json', 'utf-8'));
	return Array.isArray(crudo) ? crudo : (crudo.decisiones ?? []);
})();
const cubos = new Map(decisiones.map((d) => [d.id, d.cubo]));

const afirmaciones = [];
for (const anio of ANIOS) {
	const ruta = `${BASE}extractos/${anio}.json`;
	if (!existsSync(ruta)) {
		console.error(`  falta el extracto de ${anio}; se genera con npm run audit:fuentes`);
		continue;
	}
	for (const a of JSON.parse(readFileSync(ruta, 'utf-8')).afirmaciones ?? []) {
		afirmaciones.push({ ...a, id: String(a.afirmacion_id).slice(0, 8) });
	}
}

/**
 * **El resumen se lee de la base, no del extracto.**
 *
 * Los extractos guardan el texto del día en que se generaron, y desde entonces se han migrado más
 * de cincuenta correcciones. Comparando contra ellos, esta comprobación señalaba el pareado de
 * Navarro Tomás por perder un «parece» que la migración `20260916140000` ya le había devuelto. Es el
 * mismo descuido que tuvo la hoja de correcciones antes de leer de la base: **un informe que juzga
 * el catálogo no puede juzgar una copia suya.**
 */
const enLaBase = new Map(
	query(
		`select left(afirmacion_id::text, 8) as id, resumen from public.afirmaciones_fuentes_metricas`
	).map((r) => [r.id, r.resumen])
);

const mirados = afirmaciones
	.filter((a) => !soloConformes || cubos.get(a.id) === 'confirmacion' || cubos.get(a.id) === 'limpio')
	.map((a) => ({ ...a, resumen: enLaBase.get(a.id) ?? a.resumen }));

/** Las palabras de un texto, sin tildes ni puntuación: como compara un volcado de OCR. */
const palabras = (t) =>
	String(t ?? '')
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, ' ')
		.trim()
		.split(' ')
		.filter(Boolean);

const TIRADA = 6;

/**
 * Las oraciones del pasaje que el resumen está resumiendo.
 *
 * El ancla no son las comillas —solo dieciséis fichas citan con ellas, y siete resuelven— sino las
 * **tiradas de seis palabras** que el resumen comparte con la fuente. Es la misma técnica con que la
 * tercera comprobación mecánica encuentra cláusulas copiadas entre fichas, aplicada aquí a emparejar
 * un resumen con su párrafo. Cubre 65 de las 104 conformes, y las 39 restantes quedan fuera y se
 * dicen en el informe: sin tirada compartida no hay a qué anclarse.
 */
function oracionesResumidas(texto, resumen) {
	const oraciones = String(texto ?? '').split(/(?<=[.;:])\s+/);
	const delResumen = new Set();
	const R = palabras(resumen);
	for (let i = 0; i + TIRADA <= R.length; i += 1) delResumen.add(R.slice(i, i + TIRADA).join(' '));
	if (!delResumen.size) return [];

	const halladas = [];
	for (const oracion of oraciones) {
		const O = palabras(oracion);
		for (let i = 0; i + TIRADA <= O.length; i += 1) {
			if (delResumen.has(O.slice(i, i + TIRADA).join(' '))) {
				halladas.push(oracion);
				break;
			}
		}
	}
	return halladas;
}

const señalados = [];
let sinAncla = 0;
for (const a of mirados) {
	const enFicha = cautelas(a.resumen);
	const oraciones = oracionesResumidas(a.extracto?.texto, a.resumen);
	if (!oraciones.length) {
		sinAncla += 1;
		continue;
	}
	// La cautela que la fuente pone en la frase resumida y el resumen no recoge en ninguna parte.
	const enFuente = new Set();
	for (const oracion of oraciones) {
		for (const c of cautelas(oracion)) if (!enFicha.includes(c)) enFuente.add(c);
	}
	if (enFuente.size) señalados.push({ ...a, enFuente: [...enFuente], oraciones });
}

// ─────────────────────────────────────────────────────────────────── La salida

señalados.sort((x, y) => y.enFuente.length - x.enFuente.length || x.sobre.localeCompare(y.sobre));

const L = [];
L.push('# Señal de endurecimiento · la cautela que la fuente tiene y la ficha no');
L.push('');
L.push('Generado por `node scripts/senal-endurecimiento.mjs`. Para cada ficha se buscan en el pasaje');
L.push('las **oraciones que ella resume** —las que comparten con el resumen una tirada de seis');
L.push('palabras— y se mira si matizan donde el resumen no matiza.');
L.push('**Son candidatos, no veredictos**: lo que decide es abrir el libro.');
L.push('');
L.push(
	`Miradas **${mirados.length}** afirmaciones${soloConformes ? ' de los cubos «conforme» y «limpio»' : ' (todas)'}. **${señalados.length}** resumen una oración que matiza sin recoger la cautela. Otras **${sinAncla}** quedan fuera por no compartir con su pasaje ninguna tirada de ${TIRADA} palabras: ahí no hay a qué anclarse.`
);
L.push('');
L.push('| forma | fuente | localizador | cautelas del pasaje |');
L.push('| --- | --- | --- | --- |');
for (const s of señalados) {
	L.push(
		`| ${s.sobre} | ${s.anio} | ${s.localizador ?? '—'} | ${s.enFuente.map((c) => `«${c}»`).join(', ')} |`
	);
}
L.push('');

writeFileSync(BASE + 'senal-endurecimiento.md', L.join('\n'), 'utf-8');
console.log(`${mirados.length} miradas · ${señalados.length} señaladas · ${sinAncla} sin tirada compartida`);
console.log('Informe en docs/dominio-metrico/auditoria-fuentes/senal-endurecimiento.md');
