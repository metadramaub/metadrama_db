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
	},
	{
		nombre: 'C · localización ciega',
		lotes: join(BASE, 'lotes-c'),
		resultados: join(BASE, 'dictamenes-c'),
		campo: 'localizaciones',
		instrucciones: 'instrucciones-verificador-c.md',
		/**
		 * Una localización vale si propone un sitio **o** si declara no haber encontrado el pasaje.
		 * Lo segundo no es un fallo: en una afirmación que sostiene un silencio, no encontrar nada
		 * es la respuesta, y viene con la lista de lo que se buscó.
		 */
		vale: (x) =>
			Boolean(String(x.localizador_que_propongo ?? '').trim()) ||
			Boolean(String(x.no_encontrado ?? '').trim()),
		/**
		 * **La C no se mide contra las 267.** Las otras dos tienen que cubrir el catálogo entero;
		 * esta se lanza solo donde el localizador está en duda, porque una tercera opinión únicamente
		 * decide algo si hay algo que decidir. Su universo son las afirmaciones repartidas en sus
		 * lotes, y `npm run lotes:c` es quien dice cuáles faltan por repartir.
		 */
		soloDondeHayDuda: true
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
	const repartidas = new Set();
	const veredictos = new Map();

	if (!existsSync(pasada.lotes))
		return { pendientes, hechas, repartidas, veredictos, huboLotes: false };

	console.log(`\n══ Pasada ${pasada.nombre}`);
	console.log('lote        afirmaciones  resultado');
	console.log('----------  ------------  --------------------------------------');

	for (const fichero of readdirSync(pasada.lotes)
		.filter((f) => f.endsWith('.json'))
		.sort()) {
		const lote = leerJson(join(pasada.lotes, fichero));
		const cuantas = lote.datos?.afirmaciones?.length ?? 0;
		for (const a of lote.datos?.afirmaciones ?? []) repartidas.add(a.id);
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

	return { pendientes, hechas, repartidas, veredictos, huboLotes: true };
}

function main() {
	const afirmaciones = censo();
	const repasos = PASADAS.map((p) => ({ pasada: p, ...repasar(p) }));

	console.log(`\n══ Cobertura sobre las ${afirmaciones.length} afirmaciones del catálogo`);
	for (const { pasada, hechas, repartidas } of repasos) {
		// Las dos primeras se miden contra el catálogo entero; la C, contra lo que se le ha
		// repartido, porque solo se lanza donde el localizador está en duda.
		const universo = pasada.soloDondeHayDuda
			? afirmaciones.filter((a) => repartidas.has(a.id))
			: afirmaciones;
		const faltan = universo.filter((a) => !hechas.has(a.id));
		console.log(
			`\n${pasada.nombre}: ${universo.length - faltan.length} de ${universo.length}` +
				(pasada.soloDondeHayDuda ? ' repartidas · no se mide contra las 267' : '')
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
		// La lista de identificadores sirve para ir a buscarlos; más de una veintena deja de
		// servir y tapa el resto del informe.
		const muestra = faltan.slice(0, 20).map((a) => `${a.id} ${a.sobre}`);
		console.log(
			`   ${muestra.join(' · ')}${faltan.length > muestra.length ? ` … y ${faltan.length - muestra.length} más` : ''}`
		);
	}

	const veredictos = repasos.find((r) => r.pasada.campo === 'dictamenes')?.veredictos;
	if (veredictos?.size) {
		console.log('\nVeredictos de A: ' + [...veredictos].map(([v, n]) => `${n} ${v}`).join(' · '));
	}

	console.log('');
	let algo = false;
	for (const { pasada, pendientes, hechas, repartidas } of repasos) {
		const universo = pasada.soloDondeHayDuda
			? afirmaciones.filter((a) => repartidas.has(a.id))
			: afirmaciones;
		const sinLote = universo.filter((a) => !hechas.has(a.id)).length;
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
					`Con \`npm run lotes:${pasada.campo === 'lecturas' ? 'b' : 'c'} -- --escribe\` se reparten las que falten.`
			);
		}
		console.log(
			`   Sus instrucciones, palabra por palabra, en \`docs/dominio-metrico/auditoria-fuentes/${pasada.instrucciones}\`.`
		);
	}
	if (!algo)
		console.log(
			'Las tres pasadas están completas: las dos primeras sobre el catálogo entero, y la',
			'localización ciega sobre todo lo que se le ha repartido. `npm run lotes:c` dice si queda',
			'alguna afirmación con el localizador en duda sin repartir.'
		);
	else
		console.log(
			'\n**Se relanzan con ese texto exacto**: un lote verificado con otras instrucciones no es\ncomparable con los demás.'
		);
}

main();
