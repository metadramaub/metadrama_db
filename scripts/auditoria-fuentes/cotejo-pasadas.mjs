/**
 * Enfrenta la lectura ciega de la pasada B con lo que el catálogo registra.
 *
 * La pasada A juzgó cada afirmación teniéndola delante; la B leyó la fuente sin verla. Aquí se
 * ponen las dos caras una al lado de la otra, **y se señalan por máquina las diferencias que se
 * pueden detectar sin criterio**, que son justamente las dos que A dejaba pasar:
 *
 * - **Matices perdidos.** La lectura ciega recoge un «suele», «parece», «rara vez», y el texto del
 *   catálogo no lo tiene. Es el endurecimiento, el defecto que ningún validador veía y que solo
 *   apareció cuando lo comprobó un humano.
 * - **Enumeraciones truncadas.** La lectura ciega trae esquemas de rima —`aBaBcC`, `ABBAACCA`— que
 *   el catálogo no registra. Es la lista que se cerró antes de tiempo.
 *
 * Lo que este script **no** hace es decidir. Señala dónde mirar; si el matiz sobra o el esquema no
 * venía al caso lo dice una persona. Dos avisos falsos cuestan una lectura; un matiz perdido que
 * nadie señala se queda publicado.
 *
 * Uso:
 *   node scripts/auditoria-fuentes/cotejo-pasadas.mjs
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = fileURLToPath(new URL('../..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const A = join(BASE, 'dictamenes');
const B = join(BASE, 'dictamenes-b');
const SALIDA = join(BASE, 'cotejo.md');
const SALIDA_JSON = join(BASE, 'cotejo.json');

/**
 * Las palabras con que una fuente se reserva.
 *
 * No es una lista de sospechosos sino de cautelas: si la lectura ciega usa una y el catálogo no,
 * o la fuente no la decía —y entonces sobra en B— o el catálogo se la comió.
 */
const CAUTELAS = [
	'suele',
	'suelen',
	'parece',
	'parecen',
	'generalmente',
	'normalmente',
	'de ordinario',
	'rara vez',
	'raras veces',
	'a veces',
	'casi siempre',
	'no es raro',
	'no siempre',
	'lo más frecuente',
	'más corriente',
	'más común',
	'aunque no',
	'quizá',
	'debió',
	'poco frecuente',
	'con frecuencia'
];

const limpia = (t) =>
	String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();

const sinTildes = (t) => limpia(t).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/**
 * Los esquemas de rima que aparecen en un texto.
 *
 * Un esquema es una tira de letras de rima —`aBaBcC`, `ABBA:ACCDDC`, `abab cdcd`— y se reconoce
 * porque mezcla mayúsculas y minúsculas o repite letras sin formar una palabra. Se exigen cuatro
 * caracteres para no recoger las siglas ni las notas al pie.
 */
function esquemas(texto) {
	const hallados = new Set();
	for (const m of limpia(texto).matchAll(/\b[a-hA-H][a-hA-H'ºᵃ:\- ]{3,}[a-hA-H]\b/g)) {
		const crudo = m[0].replace(/[\s:'-]/g, '');
		// Descarta lo que sea una palabra: un esquema no tiene vocales y consonantes alternadas
		// de verdad, pero sí repite letras del principio del alfabeto.
		if (/^[a-hA-H]{4,}$/.test(crudo) && /(.).*\1/i.test(crudo)) hallados.add(crudo);
	}
	return hallados;
}

/**
 * Busca por palabra entera, no por subcadena.
 *
 * «aparece» contiene «parece», y contarlo daba treinta cautelas falsas de una sola palabra.
 */
function cautelasDe(texto) {
	const t = sinTildes(texto);
	return CAUTELAS.filter((c) => new RegExp(`(^|[^a-z])${sinTildes(c)}([^a-z]|$)`).test(t));
}

function main() {
	if (!existsSync(B)) {
		console.error('Todavía no hay lecturas de la pasada B.');
		process.exit(1);
	}

	// ---- Pasada A: el texto del catálogo y el veredicto
	const deA = new Map();
	for (const f of readdirSync(A).filter((x) => x.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(A, f), 'utf-8'));
		for (const x of d.dictamenes ?? []) {
			deA.set(x.id, { ...x, fuente: d.fuente ?? f.slice(0, 4) });
		}
	}

	// ---- Pasada B: la lectura ciega
	const filas = [];
	for (const f of readdirSync(B).filter((x) => x.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(B, f), 'utf-8'));
		for (const l of d.lecturas ?? []) {
			const a = deA.get(l.id);
			if (!a) continue;

			const registrado = limpia(a.texto_registrado);
			const ciega = limpia(l.lo_que_dice_la_fuente);

			// **Los matices se buscan en la transcripción literal, no en el resumen del agente.**
			// Un verificador escribe «no parece que…» en su propia prosa y eso no es una cautela de
			// la fuente: medir sobre su resumen señalaba setenta afirmaciones, casi todas por
			// palabras suyas. Sobre el original transcrito, lo que aparece es lo que escribió el
			// autor.
			const original = limpia(l.texto_original);
			const perdidas = cautelasDe(original).filter(
				(c) => !sinTildes(registrado).includes(sinTildes(c))
			);
			const deB = esquemas(original);
			const deCatalogo = esquemas(registrado);
			const esquemasFuera = [...deB].filter(
				(e) => ![...deCatalogo].some((c) => c.toLowerCase() === e.toLowerCase())
			);

			filas.push({
				id: l.id,
				sobre: l.sobre ?? a.sobre,
				fuente: a.fuente,
				veredictoA: a.veredicto,
				registrado,
				ciega,
				perdidas,
				esquemasFuera,
				localizadorFalla: l.el_localizador_lleva_al_pasaje === false,
				donde: l.donde_esta_de_verdad,
				noTrata: l.no_trata_esta_forma === true
			});
		}
	}

	// ---- Lo que pide mirada primero
	const marca = (f) =>
		(f.perdidas.length ? 1 : 0) + (f.esquemasFuera.length ? 1 : 0) + (f.localizadorFalla ? 1 : 0);
	filas.sort((x, y) => marca(y) - marca(x) || x.fuente.localeCompare(y.fuente));

	const conAviso = filas.filter((f) => marca(f) > 0);
	const md = [];
	md.push('# Cotejo de las dos pasadas');
	md.push('');
	md.push(`Generado el ${new Date().toISOString().slice(0, 10)} con \`npm run cotejo:pasadas\`.`);
	md.push('**No se edita a mano.**');
	md.push('');
	md.push(
		`De **${filas.length}** afirmaciones con lectura ciega, **${conAviso.length}** muestran alguna`,
		'diferencia detectable por máquina entre lo que la fuente dice y lo que el catálogo registra.',
		'Son avisos, no veredictos: puede que el matiz no viniera al caso o que el esquema sea de otra',
		'forma. **Lo decide quien lea.**'
	);
	md.push('');

	for (const f of conAviso) {
		md.push(`## ${f.sobre} · ${f.fuente}`);
		md.push('');
		md.push(`\`${f.id}\` · la pasada A dijo **${f.veredictoA}**`);
		md.push('');
		if (f.localizadorFalla) {
			md.push(`- **El localizador no lleva al pasaje.** Está en: ${limpia(f.donde) || '—'}`);
		}
		if (f.noTrata) md.push('- **La lectura ciega dice que la fuente no trata esta forma.**');
		if (f.perdidas.length) {
			md.push(`- **Matices que la fuente tiene y el catálogo no:** ${f.perdidas.join(', ')}`);
		}
		if (f.esquemasFuera.length) {
			md.push(
				`- **Esquemas que la fuente da y el catálogo no registra:** ${f.esquemasFuera.join(', ')}`
			);
		}
		md.push('');
		md.push(`**Lectura ciega de la fuente:** ${f.ciega}`);
		md.push('');
		md.push(`**Texto actual del catálogo:** ${f.registrado}`);
		md.push('');
		md.push('---');
		md.push('');
	}

	md.push('## Sin diferencias detectables');
	md.push('');
	md.push('La lectura ciega y el catálogo no discrepan en nada que una máquina pueda ver. No');
	md.push(
		'significa que coincidan en todo: significa que la diferencia, si la hay, pide criterio.'
	);
	md.push('');
	for (const f of filas.filter((x) => marca(x) === 0)) {
		md.push(`- ${f.sobre} · ${f.fuente}`);
	}
	md.push('');

	writeFileSync(SALIDA, `${md.join('\n')}\n`, 'utf-8');

	// El mismo cotejo en JSON, sin transcripciones: lo lee el sorteo de la muestra humana para
	// estratificar por senal, y asi lo que se manda comprobar no se elige a ojo.
	const comoJson = filas.map((f) => ({
		id: f.id,
		sobre: f.sobre,
		fuente: f.fuente,
		veredictoA: f.veredictoA,
		senales: {
			matices: f.perdidas,
			esquemas: f.esquemasFuera,
			localizador: f.localizadorFalla,
			noTrata: f.noTrata
		},
		senalada: marca(f) > 0
	}));
	writeFileSync(SALIDA_JSON, JSON.stringify(comoJson, null, '	') + String.fromCharCode(10), 'utf-8');

	console.log(`${filas.length} afirmaciones cotejadas · ${conAviso.length} con aviso`);
	console.log(`  ${filas.filter((f) => f.perdidas.length).length} con matices perdidos`);
	console.log(`  ${filas.filter((f) => f.esquemasFuera.length).length} con esquemas sin registrar`);
	console.log(
		`  ${filas.filter((f) => f.localizadorFalla).length} con el localizador fuera de sitio`
	);
	console.log(`\nCotejo en ${SALIDA}`);
}

main();
