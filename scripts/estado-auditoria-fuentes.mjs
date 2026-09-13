/**
 * Dónde se quedó la auditoría de las fuentes, leído del disco y contado contra la base.
 *
 * La auditoría se hace por lotes que despachan verificadores, y un lote puede quedarse a medias
 * —se acaba el límite, se corta la sesión, el agente muere—. Este script dice **qué lotes tienen
 * dictamen válido y cuáles hay que relanzar**, sin fiarse de lo que nadie recuerde: abre cada
 * fichero, lo interpreta y cuenta.
 *
 * Un fichero que existe no es un lote terminado: puede haberse escrito a medias y no ser JSON
 * válido, o traer menos dictámenes que afirmaciones tiene el lote. Las dos cosas se comprueban.
 *
 * **Y el censo son las afirmaciones de la base, no los lotes.** Esa distinción costó cuarenta y
 * tres lecturas: la primera versión medía cada pasada contra sus propios lotes, de modo que una
 * afirmación para la que nunca se llegó a armar un lote no aparecía como pendiente en ninguna
 * parte. La pasada B se dio por terminada con 224 de 267 leídas y el hueco no lo delató nada
 * hasta que se fue a recapitular a mano.
 *
 * Uso:
 *   node scripts/estado-auditoria-fuentes.mjs
 */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');

/** Las dos pasadas, con dónde viven sus lotes, sus resultados y cómo se llama la lista dentro. */
const PASADAS = [
	{
		nombre: 'A · comprobación con la ficha delante',
		lotes: join(BASE, 'lotes'),
		resultados: join(BASE, 'dictamenes'),
		campo: 'dictamenes',
		instrucciones: 'instrucciones-verificador.md',
		/** Un dictamen de A vale si trae veredicto. */
		vale: (x) => Boolean(x.veredicto)
	},
	{
		nombre: 'B · lectura ciega de la fuente',
		lotes: join(BASE, 'lotes-b'),
		resultados: join(BASE, 'dictamenes-b'),
		campo: 'lecturas',
		instrucciones: 'instrucciones-verificador-b.md',
		/**
		 * Una lectura de B vale si trae transcripción literal **o** si declara que la fuente no
		 * trata esa forma: entonces no hay pasaje que transcribir y lo que se guarda es el silencio.
		 */
		vale: (x) => Boolean(String(x.texto_original ?? '').trim()) || x.no_trata_esta_forma === true
	}
];

function leerJson(ruta) {
	try {
		return { datos: JSON.parse(readFileSync(ruta, 'utf-8')), error: null };
	} catch (error) {
		return { datos: null, error: error.message };
	}
}

/** El censo: cada afirmación del catálogo, con su fuente y de qué habla. */
function censo() {
	return query(`
		select left(a.afirmacion_id::text, 8) id, f.anio,
			coalesce(fo.nombre, foa.nombre || ' · ' || ar.nombre, foe.nombre) sobre
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		left join public.formas_metricas fo on fo.forma_id = a.forma_id
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.formas_metricas foa on foa.forma_id = ar.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma are on are.arquitectura_id = er.arquitectura_id
		left join public.formas_metricas foe on foe.forma_id = are.forma_id
		order by f.anio, 3;
	`);
}

/** Recorre los lotes de una pasada y devuelve qué hay despachado y qué identificadores cubre. */
function repasar(pasada) {
	const pendientes = [];
	const hechas = new Set();
	const veredictos = new Map();

	if (!existsSync(pasada.lotes)) return { pendientes, hechas, veredictos, huboLotes: false };

	console.log(`\n══ Pasada ${pasada.nombre}`);
	console.log('lote        afirmaciones  resultado');
	console.log('----------  ------------  --------------------------------------');

	for (const fichero of readdirSync(pasada.lotes)
		.filter((f) => f.endsWith('.json'))
		.sort()) {
		const lote = leerJson(join(pasada.lotes, fichero));
		const cuantas = lote.datos?.afirmaciones?.length ?? 0;
		const ruta = join(pasada.resultados, fichero);

		if (!existsSync(ruta)) {
			pendientes.push(fichero);
			console.log(`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  falta`);
			continue;
		}

		const resultado = leerJson(ruta);
		if (resultado.error) {
			pendientes.push(fichero);
			console.log(
				`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  ROTO: ${resultado.error.slice(0, 40)}`
			);
			continue;
		}

		const suyos = (resultado.datos?.[pasada.campo] ?? []).filter(pasada.vale);
		for (const x of suyos) {
			hechas.add(x.id);
			if (x.veredicto) veredictos.set(x.veredicto, (veredictos.get(x.veredicto) ?? 0) + 1);
		}
		if (suyos.length < cuantas) {
			pendientes.push(fichero);
			console.log(
				`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  INCOMPLETO: ${suyos.length} de ${cuantas}`
			);
		} else {
			console.log(`${fichero.padEnd(10)}  ${String(cuantas).padStart(12)}  ${suyos.length} hechas`);
		}
	}

	// Lo que hay en los resultados sin lote que lo reclame: el piloto vive así, y no es un error.
	if (existsSync(pasada.resultados)) {
		for (const f of readdirSync(pasada.resultados).filter((x) => x.endsWith('.json'))) {
			if (existsSync(join(pasada.lotes, f))) continue;
			const r = leerJson(join(pasada.resultados, f));
			for (const x of (r.datos?.[pasada.campo] ?? []).filter(pasada.vale)) hechas.add(x.id);
		}
	}

	return { pendientes, hechas, veredictos, huboLotes: true };
}

function main() {
	const afirmaciones = censo();
	const repasos = PASADAS.map((p) => ({ pasada: p, ...repasar(p) }));

	console.log(`\n══ Cobertura sobre las ${afirmaciones.length} afirmaciones del catálogo`);
	for (const { pasada, hechas } of repasos) {
		const faltan = afirmaciones.filter((a) => !hechas.has(a.id));
		console.log(
			`\n${pasada.nombre}: ${afirmaciones.length - faltan.length} de ${afirmaciones.length}`
		);
		if (!faltan.length) {
			console.log('   completa.');
			continue;
		}
		const porAnio = new Map();
		for (const a of faltan) porAnio.set(a.anio, (porAnio.get(a.anio) ?? 0) + 1);
		console.log(
			`   faltan ${faltan.length}: ` +
				[...porAnio].map(([anio, n]) => `${n} de ${anio}`).join(' · ')
		);
		console.log(`   ${faltan.map((a) => `${a.id} ${a.sobre}`).join(' · ')}`);
	}

	const veredictos = repasos.find((r) => r.pasada.campo === 'dictamenes')?.veredictos;
	if (veredictos?.size) {
		console.log('\nVeredictos de A: ' + [...veredictos].map(([v, n]) => `${n} ${v}`).join(' · '));
	}

	console.log('');
	let algo = false;
	for (const { pasada, pendientes, hechas } of repasos) {
		const sinLote = afirmaciones.filter((a) => !hechas.has(a.id)).length;
		if (!pendientes.length && !sinLote) continue;
		algo = true;
		if (pendientes.length) {
			console.log(
				`Pasada ${pasada.nombre.slice(0, 1)}: relanzar ${pendientes.length} lote(s) — ${pendientes.join(', ')}`
			);
		}
		if (sinLote && !pendientes.length) {
			console.log(
				`Pasada ${pasada.nombre.slice(0, 1)}: hay afirmaciones sin lote que las reclame. ` +
					'Con `npm run lotes:b -- --escribe` se reparten las que le falten a la B.'
			);
		}
		console.log(
			`   Sus instrucciones, palabra por palabra, en \`docs/dominio-metrico/auditoria-fuentes/${pasada.instrucciones}\`.`
		);
	}
	if (!algo) console.log('Las dos pasadas están completas sobre el catálogo entero.');
	else
		console.log(
			'\n**Se relanzan con ese texto exacto**: un lote verificado con otras instrucciones no es\ncomparable con los demás.'
		);
}

main();
