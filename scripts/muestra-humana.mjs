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
			console.log(`   el dictamen dice: hoja ${p.hoja} del PDF, página impresa ${p.numero_impreso}`);
		}
		console.log(`   comprobar: ${m.que_comprobar}\n`);
	}
	console.log(`Anota lo que veas en ${SALIDA}`);
	if (!existsSync(DICTAMENES)) process.exitCode = 1;
}

main();
