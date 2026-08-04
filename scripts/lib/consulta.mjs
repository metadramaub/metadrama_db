/**
 * Consultas SQL contra la base enlazada, a través de la CLI de Supabase.
 *
 * Se usa cuando hace falta el resultado de una **vista** y no solo los datos crudos: un
 * volcado no trae vistas, y replicar su lógica en JavaScript crea dos fuentes de verdad que
 * se separan en cuanto una cambia.
 */

import { spawnSync } from 'node:child_process';
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
export function query(sql) {
	const command = spawnSync(
		process.execPath,
		[SUPABASE_CLI, 'db', 'query', '--linked', '--output-format', 'json', sql],
		{ encoding: 'utf-8', stdio: ['inherit', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024 }
	);
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
