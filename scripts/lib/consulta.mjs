/**
 * Consultas SQL contra la base enlazada, a través de la CLI de Supabase.
 *
 * Se usa cuando hace falta el resultado de una **vista** y no solo los datos crudos: un
 * volcado no trae vistas, y replicar su lógica en JavaScript crea dos fuentes de verdad que
 * se separan en cuanto una cambia.
 */

import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const SUPABASE_CLI = fileURLToPath(
	new URL('../../node_modules/supabase/dist/supabase.js', import.meta.url)
);

/**
 * Ejecuta una consulta y devuelve sus filas.
 *
 * La CLI envuelve el resultado con un aviso de que los datos no son de fiar; aquí solo se
 * leen para escribir un informe, así que basta con quedarse con las filas.
 */
/**
 * Ejecuta la CLI, mandando el guion **por fichero cuando es largo**.
 *
 * Windows corta la línea de comandos en 32.767 caracteres, y un argumento más largo se pierde: el
 * proceso arranca, no ejecuta nada y **termina con éxito**. Costó descubrirlo sembrando obras —una
 * secuencia de pareados ocupaba 34.258 caracteres y desaparecía sin un solo error, mientras que la
 * misma consulta con 27.000 pasaba—. Por debajo del umbral se sigue mandando como argumento, que
 * es más rápido y deja el rastro en el proceso.
 */
function ejecutar(sql) {
	const porFichero = sql.length > 8000;
	const carpeta = porFichero ? mkdtempSync(join(tmpdir(), 'metadrama-sql-')) : null;
	const fichero = carpeta ? join(carpeta, 'consulta.sql') : null;
	if (fichero) writeFileSync(fichero, sql, 'utf-8');

	try {
		return spawnSync(
			process.execPath,
			[
				SUPABASE_CLI,
				'db',
				'query',
				'--linked',
				'--output-format',
				'json',
				...(fichero ? ['--file', fichero] : [sql])
			],
			{ encoding: 'utf-8', stdio: ['inherit', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024 }
		);
	} finally {
		if (carpeta) rmSync(carpeta, { recursive: true, force: true });
	}
}

export function query(sql) {
	const command = ejecutar(sql);
	if (command.status !== 0) {
		console.error(command.stderr || command.error?.message || '');
		console.error('No se pudo consultar la base enlazada. ¿Está el proyecto enlazado?');
		process.exit(command.status ?? 1);
	}
	// La salida puede traer líneas sueltas de la CLI antes del JSON.
	const salida = command.stdout;
	const inicio = salida.indexOf('{');
	if (inicio < 0) {
		console.error('Respuesta inesperada de la CLI de Supabase:');
		console.error(salida.slice(0, 500));
		process.exit(1);
	}
	let payload;
	try {
		payload = JSON.parse(salida.slice(inicio));
	} catch {
		console.error('No se pudo interpretar la respuesta de la consulta.');
		console.error(salida.slice(0, 500));
		process.exit(1);
	}
	return payload.rows ?? [];
}

/**
 * Como `query`, pero devuelve el error en vez de terminar el proceso.
 *
 * Lo necesita quien prueba a propósito algo que puede fallar —la siembra de obras llama a
 * `guardar_anotacion_metrica` una vez por secuencia y el interés está justamente en cuáles rechaza—,
 * porque con `query` el primer rechazo se llevaría por delante el resto de la siembra.
 */
export function tryQuery(sql) {
	const command = ejecutar(sql);
	if (command.status !== 0) {
		const salida = `${command.stderr ?? ''}${command.stdout ?? ''}`;
		const mensaje =
			salida.match(/ERROR:\s*[^\n]+/)?.[0] ?? salida.trim().split('\n').slice(-1)[0] ?? 'error';
		return { rows: [], error: mensaje };
	}
	const salida = command.stdout;
	const inicio = salida.indexOf('{');
	if (inicio < 0) return { rows: [], error: 'respuesta inesperada de la CLI' };
	try {
		return { rows: JSON.parse(salida.slice(inicio)).rows ?? [], error: null };
	} catch {
		return { rows: [], error: 'no se pudo interpretar la respuesta' };
	}
}
