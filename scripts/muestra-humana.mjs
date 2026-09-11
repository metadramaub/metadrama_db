/**
 * Sortea la muestra que un humano comprueba contra el PDF.
 *
 * Es la pieza que valida a los verificadores. Todo lo demás de esta auditoría descansa en que
 * unos agentes dijeron la verdad; **esto es lo único que lo contrasta desde fuera**, y por eso
 * no puede elegirlo quien tiene interés en que salga bien.
 *
 * De ahí que el sorteo sea **reproducible**: la semilla se escribe en la salida y cualquiera
 * puede repetir la tirada y obtener la misma muestra. Un muestreo que no se puede repetir no
 * prueba nada, porque nadie sabe cuántas veces se tiró antes de quedarse con una.
 *
 * Y es **estratificado**, no uniforme: de 84 afirmaciones, 61 son conformes, así que una tirada
 * simple daría casi solo conformes y no comprobaría si los defectos están bien vistos. Se
 * reparte entre los tres grupos que fallan de maneras distintas —una conforme equivocada es un
 * error que nadie ve; un defecto equivocado es una acusación falsa; una duda mal clasificada
 * manda al IP algo que no le toca—.
 *
 * Uso:
 *   node scripts/muestra-humana.mjs
 *   node scripts/muestra-humana.mjs --semilla 2026-09-12 --cuantas 12
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const DICTAMENES = join(BASE, 'dictamenes');
const SALIDA = join(BASE, 'muestra-humana.json');
const HOJA = join(BASE, 'muestra-humana.md');

/** Un generador con semilla: la misma cadena da siempre la misma tirada. */
function generador(semilla) {
	let h = 1779033703 ^ semilla.length;
	for (let i = 0; i < semilla.length; i += 1) {
		h = Math.imul(h ^ semilla.charCodeAt(i), 3432918353);
		h = (h << 13) | (h >>> 19);
	}
	return () => {
		h = Math.imul(h ^ (h >>> 16), 2246822507);
		h = Math.imul(h ^ (h >>> 13), 3266489909);
		h ^= h >>> 16;
		return (h >>> 0) / 4294967296;
	};
}

function baraja(lista, azar) {
	const copia = [...lista];
	for (let i = copia.length - 1; i > 0; i -= 1) {
		const j = Math.floor(azar() * (i + 1));
		[copia[i], copia[j]] = [copia[j], copia[i]];
	}
	return copia;
}

/**
 * La hoja con la que un humano comprueba, partida en dos a propósito.
 *
 * La primera parte da lo que hay que juzgar —lo que el catálogo publica— y dónde mirarlo. La
 * segunda, lo que dictaminó el verificador. **Están separadas porque el orden decide si esto es
 * una comprobación o una ratificación**: quien lee primero el veredicto ajeno ya no juzga el
 * pasaje, juzga si el otro lo copió bien.
 */
function hojaDeTrabajo(muestra, completos, semilla) {
	const PDF = {
		'Quilis 1969': 'Antonio_Quilis_Metrica_espanola.pdf',
		'Navarro Tomás 1972': 'Tomas Navarro Tomas - Metrica Española - libgen.li.pdf',
		'Domínguez Caparrós 2014': 'Domínguez Caparrós - 2014 - Métrica española.pdf',
		'Diccionario 2016':
			'Diccionario de métrica española{José Domínguez Caparrós}{107384004} libgen.li.pdf'
	};
	const md = [];
	md.push('# Muestra humana · cómo se comprueba');
	md.push('');
	md.push(`Semilla del sorteo: \`${semilla}\`. **No leas la parte B hasta haber decidido la A**:`);
	md.push('quien lee primero el veredicto ajeno deja de comprobar y pasa a ratificar.');
	md.push('');
	md.push(
		'Para cada una: lee lo que publica el catálogo, abre la fuente por tu cuenta, y decide si'
	);
	md.push('la fuente sostiene eso. Después, y solo después, mira lo que dijo el verificador.');
	md.push('');
	md.push('## Parte A · lo que tienes que juzgar');
	md.push('');
	completos.forEach((d, i) => {
		md.push(`### ${i + 1}. ${d.sobre} · ${d.fuente}`);
		md.push('');
		md.push(`**Dice el catálogo hoy:** ${String(d.texto_registrado ?? '').replace(/\s+/g, ' ')}`);
		md.push('');
		md.push(`**Localizador declarado:** ${d.localizador_declarado}`);
		md.push('');
		if (d.fuente === 'Morley y Bruerton 1968') {
			md.push('Fuente: `docs/dominio-metrico/bibliografía/definiciones_Morley&Bruerton.md`.');
			md.push('Es corto: ábrelo y busca el epígrafe. Y **léelo entero**, que varias de estas');
			md.push(
				'afirmaciones dicen lo que M&B *no* registran, y eso no se comprueba en un epígrafe.'
			);
		} else if (d.fuente === 'Jauralde Pou 2020') {
			md.push('Fuente: el volcado en `bibliografía/txt/Jauralde-Pou-2020-metrica-espanola.txt`.');
			md.push('No hay PDF: viene de un epub, y no tiene páginas que comprobar.');
		} else {
			const hoja = d.confirmacion_pdf?.hoja;
			const num = d.confirmacion_pdf?.numero_impreso;
			md.push(`Fuente: \`bibliografía/${PDF[d.fuente]}\`.`);
			if (hoja) {
				md.push('');
				md.push(
					`El dictamen afirma que el pasaje está en la **hoja ${hoja}** del PDF y que esa hoja`
				);
				md.push(
					`lleva impreso el número **${num}**. Eso también se comprueba: ábrela y mira el número.`
				);
				md.push('');
				md.push('```bash');
				md.push(
					`pdftotext -enc UTF-8 -f ${hoja} -l ${hoja} "docs/dominio-metrico/bibliografía/${PDF[d.fuente]}" -`
				);
				md.push('```');
			}
		}
		md.push('');
		md.push(
			'**Tu juicio:** ¿sostiene la fuente lo que dice el catálogo? ¿Le añade algo, lo afirma'
		);
		md.push('con más fuerza de la que tiene, o se deja fuera algo que cambie la lectura?');
		md.push('');
		md.push('---');
		md.push('');
	});

	md.push('## Parte B · lo que dictaminó el verificador');
	md.push('');
	md.push('Ahora sí. Si coincides, el verificador merece crédito en esa. Si no, quiero saberlo.');
	md.push('');
	completos.forEach((d, i) => {
		md.push(`### ${i + 1}. ${d.sobre} · ${d.fuente} — **${d.veredicto}**`);
		md.push('');
		if (d.por_que_ahi)
			md.push(`*Dónde dice haberlo visto:* ${String(d.por_que_ahi).replace(/\s+/g, ' ')}`);
		md.push('');
		md.push(
			`*Transcribió del original:* ${String(d.texto_original ?? '')
				.replace(/\s+/g, ' ')
				.slice(0, 1200)}`
		);
		for (const f of d.defectos ?? []) {
			md.push('');
			md.push(
				`*Defecto ${f.tipo} (${f.gravedad}):* ${String(f.explicacion ?? '').replace(/\s+/g, ' ')}`
			);
		}
		if (d.observaciones) {
			md.push('');
			md.push(`*Observó:* ${String(d.observaciones).replace(/\s+/g, ' ')}`);
		}
		md.push('');
		md.push('---');
		md.push('');
	});
	return md.join(String.fromCharCode(10));
}

function main() {
	const argv = process.argv.slice(2);
	const arg = (nombre, porDefecto) => {
		const i = argv.indexOf(`--${nombre}`);
		return i >= 0 ? argv[i + 1] : porDefecto;
	};
	const semilla = arg('semilla', new Date().toISOString().slice(0, 10));
	const cuantas = Number(arg('cuantas', 9));

	const todos = [];
	for (const fichero of readdirSync(DICTAMENES)
		.filter((f) => f.endsWith('.json'))
		.sort()) {
		const datos = JSON.parse(readFileSync(join(DICTAMENES, fichero), 'utf-8'));
		for (const d of datos.dictamenes ?? []) {
			todos.push({ ...d, fuente: datos.fuente ?? fichero.slice(0, 4) });
		}
	}
	const porId = new Map(todos.map((d) => [`${d.fuente}·${d.id}`, d]));
	const dictamenes = [...porId.values()];

	const grupos = {
		conforme: dictamenes.filter((d) => d.veredicto === 'conforme'),
		defecto: dictamenes.filter((d) => d.veredicto === 'defecto'),
		otro: dictamenes.filter((d) => !['conforme', 'defecto'].includes(d.veredicto))
	};

	// Más peso a las conformes porque son el fallo invisible: un defecto mal visto se discute
	// leyendo el propio dictamen, pero una conforme equivocada no la delata nada.
	const reparto = {
		conforme: Math.max(1, Math.round(cuantas * 0.55)),
		defecto: Math.max(1, Math.round(cuantas * 0.33)),
		otro: Math.max(1, cuantas - Math.round(cuantas * 0.55) - Math.round(cuantas * 0.33))
	};

	const azar = generador(semilla);
	const muestra = [];
	const completos = [];
	for (const grupo of ['conforme', 'defecto', 'otro']) {
		for (const d of baraja(grupos[grupo], azar).slice(0, reparto[grupo])) {
			muestra.push({
				id: d.id,
				fuente: d.fuente,
				sobre: d.sobre,
				localizador_declarado: d.localizador_declarado,
				veredicto: d.veredicto,
				pagina_que_afirma_el_dictamen: d.confirmacion_pdf ?? null,
				que_comprobar:
					d.veredicto === 'conforme'
						? 'Que el pasaje está donde dice y que el catálogo no le añade, endurece ni omite nada que cambie la lectura.'
						: d.veredicto === 'defecto'
							? 'Que el defecto es real y no una acusación de más.'
							: 'Que está bien clasificada como cuestión de criterio y no como error.',
				hallazgo_humano: '',
				coincide_con_el_dictamen: null
			});
			completos.push(d);
		}
	}

	writeFileSync(
		SALIDA,
		`${JSON.stringify({ semilla, cuantas: muestra.length, de: dictamenes.length, muestra }, null, '\t')}\n`,
		'utf-8'
	);

	console.log(`Semilla: ${semilla} · ${muestra.length} de ${dictamenes.length} dictámenes\n`);
	for (const m of muestra) {
		console.log(`[${m.veredicto}] ${m.sobre} · ${m.fuente}`);
		console.log(`   localizador: ${m.localizador_declarado}`);
		if (m.pagina_que_afirma_el_dictamen?.hoja) {
			const p = m.pagina_que_afirma_el_dictamen;
			console.log(
				`   el dictamen dice: hoja ${p.hoja} del PDF, página impresa ${p.numero_impreso}`
			);
		}
		console.log(`   comprobar: ${m.que_comprobar}\n`);
	}
	writeFileSync(
		HOJA,
		`${hojaDeTrabajo(muestra, completos, semilla)}
`,
		'utf-8'
	);
	console.log(`
La hoja para comprobar, en ${HOJA}`);
	console.log(`Anota lo que veas en ${SALIDA}`);
	if (!existsSync(DICTAMENES)) process.exitCode = 1;
}

main();
