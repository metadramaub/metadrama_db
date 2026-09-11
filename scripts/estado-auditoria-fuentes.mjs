/**
 * Dónde se quedó la auditoría de las fuentes, leído del disco.
 *
 * La auditoría se hace por lotes que despachan verificadores, y un lote puede quedarse a medias
 * —se acaba el límite, se corta la sesión, el agente muere—. Este script dice **qué lotes tienen
 * dictamen válido y cuáles hay que relanzar**, sin fiarse de lo que nadie recuerde: abre cada
 * fichero, lo interpreta y cuenta.
 *
 * Un fichero que existe no es un lote terminado: puede haberse escrito a medias y no ser JSON
 * válido, o traer menos dictámenes que afirmaciones tiene el lote. Las dos cosas se comprueban.
 *
 * Uso:
 *   node scripts/estado-auditoria-fuentes.mjs
 */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const LOTES = join(BASE, 'lotes');
const DICTAMENES = join(BASE, 'dictamenes');

function leerJson(ruta) {
	try {
		return { datos: JSON.parse(readFileSync(ruta, 'utf-8')), error: null };
	} catch (error) {
		return { datos: null, error: error.message };
	}
}

function main() {
	if (!existsSync(LOTES)) {
		console.log('No hay lotes todavía. Se generan desde los extractos de `npm run audit:fuentes`.');
		return;
	}

	const pendientes = [];
	const veredictos = new Map();
	let afirmacionesTotales = 0;
	let dictaminadas = 0;

	console.log('lote        afirmaciones  dictamen');
	console.log('----------  ------------  --------------------------------------');

	for (const fichero of readdirSync(LOTES)
		.filter((f) => f.endsWith('.json'))
		.sort()) {
		const lote = leerJson(join(LOTES, fichero));
		const cuantas = lote.datos?.afirmaciones?.length ?? 0;
		afirmacionesTotales += cuantas;

		const rutaDictamen = join(DICTAMENES, fichero);
		if (!existsSync(rutaDictamen)) {
			pendientes.push(fichero);
			console.log(`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  falta`);
			continue;
		}

		const dictamen = leerJson(rutaDictamen);
		if (dictamen.error) {
			pendientes.push(fichero);
			console.log(
				`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  ROTO: ${dictamen.error.slice(0, 40)}`
			);
			continue;
		}

		const suyos = dictamen.datos?.dictamenes ?? [];
		dictaminadas += suyos.length;
		for (const d of suyos) {
			const v = d.veredicto ?? 'sin veredicto';
			veredictos.set(v, (veredictos.get(v) ?? 0) + 1);
		}
		if (suyos.length < cuantas) {
			pendientes.push(fichero);
			console.log(
				`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  INCOMPLETO: ${suyos.length} de ${cuantas}`
			);
		} else {
			console.log(
				`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  ${suyos.length} dictámenes`
			);
		}
	}

	console.log(`\n${dictaminadas} de ${afirmacionesTotales} afirmaciones dictaminadas.`);
	if (veredictos.size) {
		console.log('Veredictos: ' + [...veredictos].map(([v, n]) => `${n} ${v}`).join(' · '));
	}

	if (pendientes.length) {
		console.log(`\nHay que relanzar ${pendientes.length} lote(s): ${pendientes.join(', ')}`);
		console.log(
			'Las instrucciones del verificador, palabra por palabra, están en',
			'`docs/dominio-metrico/auditoria-fuentes/instrucciones-verificador.md`.',
			'**Se relanzan con ese texto exacto**: un lote verificado con otras instrucciones no es',
			'comparable con los demás.'
		);
	} else {
		console.log('\nNo queda ningún lote por despachar.');
	}
}

main();
