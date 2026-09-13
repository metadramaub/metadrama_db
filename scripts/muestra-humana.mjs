/**
 * Sortea la muestra que un humano comprueba contra la fuente.
 *
 * Es la pieza que valida a los verificadores. Todo lo demás descansa en que unos agentes dijeran
 * la verdad; **esto es lo único que lo contrasta desde fuera**, y por eso no puede elegirlo quien
 * tiene interés en que salga bien. De ahí que el sorteo sea **reproducible**: la semilla se
 * escribe en la salida y cualquiera puede repetir la tirada. Un muestreo que no se puede repetir
 * no prueba nada, porque nadie sabe cuántas veces se tiró antes de quedarse con una.
 *
 * **Se estratifica por la pregunta que toca, no por el veredicto.** En la primera ronda, con solo
 * la pasada A hecha, la pregunta era si sus veredictos merecían crédito. Ahora, con las dos
 * pasadas y el cotejo, la pregunta es otra y son tres:
 *
 * - **¿Son reales las señales del cotejo?** 102 afirmaciones que A dio por conformes aparecen
 *   señaladas por la lectura ciega. Si las señales son buenas, hay que leerlas todas; si son
 *   ruido, no. **Es la que más pesa, porque decide cuánto trabajo queda.**
 * - **¿Están limpias las conformes que nadie señala?** Es el silencio de los dos pasos a la vez,
 *   y el único sitio donde un error puede quedarse para siempre.
 * - **¿Se acusó de más?** Un defecto mal visto es una corrección que empeora el catálogo.
 *
 * Uso:
 *   node scripts/muestra-humana.mjs
 *   node scripts/muestra-humana.mjs --semilla 2026-09-13 --cuantas 18
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const A = join(BASE, 'dictamenes');
const B = join(BASE, 'dictamenes-b');
const COTEJO = join(BASE, 'cotejo.json');
const SALIDA = join(BASE, 'muestra-humana.json');
const HOJA = join(BASE, 'muestra-humana.md');

const PDF = {
	'Quilis 1969': 'Antonio_Quilis_Metrica_espanola.pdf',
	'Navarro Tomás 1972': 'Tomas Navarro Tomas - Metrica Española - libgen.li.pdf',
	'Domínguez Caparrós 2014': 'Domínguez Caparrós - 2014 - Métrica española.pdf',
	'Diccionario 2016':
		'Diccionario de métrica española{José Domínguez Caparrós}{107384004} libgen.li.pdf'
};

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

const limpia = (t, n = 1400) => {
	const s = String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();
	return s.length > n ? `${s.slice(0, n)}…` : s;
};

/**
 * Reparte la tirada entre las fuentes antes de sortear dentro de cada una.
 *
 * Una tirada uniforme sobre el montón entero deja fuentes sin tocar por azar, y la tasa de
 * defectos varía mucho entre ellas —del 44 % de conformes en Jauralde al 80 % del Diccionario—.
 * Repartir primero garantiza que ninguna se quede sin mirar.
 */
function reparte(lista, cuantas, azar) {
	const porFuente = new Map();
	for (const x of lista) {
		if (!porFuente.has(x.fuente)) porFuente.set(x.fuente, []);
		porFuente.get(x.fuente).push(x);
	}
	const fuentes = baraja([...porFuente.keys()], azar);
	const elegidas = [];
	let vuelta = 0;
	while (elegidas.length < cuantas && vuelta < 20) {
		for (const f of fuentes) {
			const suyas = porFuente.get(f);
			if (suyas.length > vuelta && elegidas.length < cuantas) {
				elegidas.push(baraja(suyas, azar)[vuelta]);
			}
		}
		vuelta += 1;
	}
	return elegidas.filter(Boolean);
}

function main() {
	const argv = process.argv.slice(2);
	const arg = (nombre, porDefecto) => {
		const i = argv.indexOf(`--${nombre}`);
		return i >= 0 ? argv[i + 1] : porDefecto;
	};
	// **La semilla se pega a la muestra que ya existe.** Por defecto era la fecha de hoy, así que
	// regenerar la hoja al día siguiente sorteaba otras quince afirmaciones y le cambiaba el
	// trabajo debajo a quien estuviera comprobándolas. Solo se tira de nuevo si se pide
	// expresamente otra semilla.
	const semillaPrevia = existsSync(SALIDA)
		? JSON.parse(readFileSync(SALIDA, 'utf-8')).semilla
		: null;
	const semilla = arg('semilla', semillaPrevia ?? new Date().toISOString().slice(0, 10));
	const cuantas = Number(arg('cuantas', 15));

	if (!existsSync(COTEJO)) {
		console.error('Falta el cotejo. Ejecuta antes `npm run cotejo:pasadas`.');
		process.exit(1);
	}

	const deA = new Map();
	for (const f of readdirSync(A).filter((x) => x.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(A, f), 'utf-8'));
		for (const x of d.dictamenes ?? []) deA.set(x.id, { ...x, fuente: d.fuente ?? f.slice(0, 4) });
	}
	const deB = new Map();
	for (const f of readdirSync(B).filter((x) => x.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(B, f), 'utf-8'));
		for (const l of d.lecturas ?? []) deB.set(l.id, l);
	}
	const cotejo = JSON.parse(readFileSync(COTEJO, 'utf-8'));

	const enriquecido = cotejo
		.map((c) => ({ ...c, a: deA.get(c.id), b: deB.get(c.id) }))
		.filter((x) => x.a);

	const grupos = {
		senalada: enriquecido.filter((x) => x.veredictoA === 'conforme' && x.senalada),
		limpia: enriquecido.filter((x) => x.veredictoA === 'conforme' && !x.senalada),
		defecto: enriquecido.filter((x) => x.veredictoA === 'defecto')
	};

	// Más peso donde está la pregunta que decide el trabajo que queda.
	const reparto = {
		senalada: Math.max(1, Math.round(cuantas * 0.55)),
		limpia: Math.max(1, Math.round(cuantas * 0.25)),
		defecto: Math.max(1, Math.round(cuantas * 0.2))
	};

	const azar = generador(semilla);
	const muestra = [];
	for (const grupo of ['senalada', 'limpia', 'defecto']) {
		for (const x of reparte(grupos[grupo], reparto[grupo], azar)) muestra.push({ ...x, grupo });
	}

	// ------------------------------------------------------------------ La hoja
	const md = [];
	md.push('# Muestra humana · segunda ronda');
	md.push('');
	md.push(`Semilla: \`${semilla}\` · ${muestra.length} de ${enriquecido.length} afirmaciones con`);
	md.push('las dos pasadas hechas.');
	md.push('');
	md.push('**No leas la parte B hasta haber decidido la A.** Quien lee primero el veredicto ajeno');
	md.push('deja de comprobar y pasa a ratificar.');
	md.push('');
	md.push(
		'En la parte A tienes lo que el catálogo publica y **la transcripción literal del pasaje**'
	);
	md.push(
		'que hizo la lectura ciega. Eso te ahorra buscarlo, pero **no te ahorra desconfiar**: si'
	);
	md.push('algo no cuadra, abre la fuente. Para eso va la orden de `pdftotext` donde la hay.');
	md.push('');

	md.push('## Parte A · lo que tienes que juzgar');
	md.push('');
	muestra.forEach((x, i) => {
		md.push(`### ${i + 1}. ${x.sobre} · ${x.fuente}`);
		md.push('');
		md.push(`**Dice el catálogo hoy:** ${limpia(x.a.texto_registrado)}`);
		md.push('');
		md.push(`**Localizador declarado:** ${x.a.localizador_declarado ?? '—'}`);
		md.push('');
		if (x.b?.texto_original) {
			md.push(`**Dice la fuente, transcrito:** ${limpia(x.b.texto_original)}`);
			md.push('');
		}
		const hoja = x.a.confirmacion_pdf?.hoja;
		if (hoja && PDF[x.fuente]) {
			md.push('```bash');
			md.push(
				`pdftotext -enc UTF-8 -f ${hoja} -l ${hoja} "docs/dominio-metrico/bibliografía/${PDF[x.fuente]}" -`
			);
			md.push('```');
			md.push('');
		}
		md.push('**Tus dos juicios**, que son independientes:');
		md.push('');
		md.push('1. **El contenido.** ¿Dice la fuente lo que el catálogo le atribuye, con la misma');
		md.push('   fuerza y sin dejarse nada que cambie la lectura?');
		md.push('2. **El localizador.** ¿Lleva al pasaje? Una afirmación puede ser fiel y citar mal,');
		md.push('   que es el caso más frecuente de esta auditoría.');
		md.push('');
		md.push('---');
		md.push('');
	});

	md.push('## Parte B · lo que dijeron las dos pasadas');
	md.push('');
	muestra.forEach((x, i) => {
		md.push(`### ${i + 1}. ${x.sobre} · ${x.fuente}`);
		md.push('');
		md.push(`- **Pasada A** dictaminó: **${x.veredictoA}**`);
		for (const f of x.a.defectos ?? []) {
			md.push(`  - ${f.tipo} (${f.gravedad}): ${limpia(f.explicacion, 400)}`);
		}
		if (x.senalada) {
			const s = x.senales;
			const partes = [];
			if (s.matices?.length)
				partes.push(`matices que la fuente tiene y el catálogo no: ${s.matices.join(', ')}`);
			if (s.esquemas?.length) partes.push(`esquemas sin registrar: ${s.esquemas.join(', ')}`);
			if (s.localizador) partes.push('el localizador no lleva al pasaje');
			if (s.noTrata) partes.push('la lectura ciega dice que la fuente no trata esta forma');
			md.push(`- **El cotejo señala:** ${partes.join(' · ')}`);
		} else {
			md.push('- **El cotejo no señala nada.**');
		}
		if (x.b?.lo_que_dice_la_fuente) {
			md.push('');
			md.push(`**Lectura ciega de la fuente:** ${limpia(x.b.lo_que_dice_la_fuente)}`);
		}
		md.push('');
		md.push('---');
		md.push('');
	});

	writeFileSync(HOJA, `${md.join('\n')}\n`, 'utf-8');

	writeFileSync(
		SALIDA,
		`${JSON.stringify(
			{
				semilla,
				como_se_anota:
					'Dos juicios independientes por afirmación. contenido_correcto: ¿dice la fuente lo que ' +
					'el catálogo le atribuye, con la misma fuerza y sin dejarse nada que cambie la lectura? ' +
					'localizador_correcto: ¿lleva el localizador declarado al pasaje? Una afirmación puede ' +
					'ser correcta en contenido y llevar mal el localizador, que es el caso más frecuente de ' +
					'esta auditoría. Si no aplica —silencios sin página, fuentes sin paginar— déjalo en null ' +
					'y dilo en hallazgo_humano.',
				cuantas: muestra.length,
				de: enriquecido.length,
				muestra: muestra.map((x) => ({
					id: x.id,
					sobre: x.sobre,
					fuente: x.fuente,
					grupo: x.grupo,
					veredicto_pasada_a: x.veredictoA,
					senalada_por_el_cotejo: x.senalada,
					que_se_pregunta:
						x.grupo === 'senalada'
							? '¿Es real lo que señala el cotejo, o el matiz no venía al caso?'
							: x.grupo === 'limpia'
								? '¿Está de verdad limpia, o se les pasó a las dos pasadas?'
								: '¿El defecto es real, o se acusó de más?',
					hallazgo_humano: '',
					contenido_correcto: null,
					localizador_correcto: null
				}))
			},
			null,
			'\t'
		)}\n`,
		'utf-8'
	);

	console.log(`Semilla ${semilla} · ${muestra.length} de ${enriquecido.length}`);
	for (const g of ['senalada', 'limpia', 'defecto']) {
		console.log(`  ${muestra.filter((x) => x.grupo === g).length}  ${g} (de ${grupos[g].length})`);
	}
	console.log(`\nHoja en ${HOJA}\nAnota en ${SALIDA}`);
}

main();
