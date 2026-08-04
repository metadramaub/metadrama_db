/**
 * Lectura de un volcado de datos de la base enlazada.
 *
 * Lo comparten el informe de conformidad del catálogo y el de migración por obra: los dos
 * necesitan los mismos datos y no tiene sentido que cada uno traiga su propio analizador.
 */

import { mkdtempSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

/** Vuelca los datos de la base enlazada a un fichero temporal y devuelve su ruta. */
export function dumpLinkedDatabase() {
	const supabaseCli = fileURLToPath(
		new URL('../../node_modules/supabase/dist/supabase.js', import.meta.url)
	);
	const target = join(mkdtempSync(join(tmpdir(), 'metrica-')), 'data.sql');
	const command = spawnSync(
		process.execPath,
		[supabaseCli, 'db', 'dump', '--linked', '--data-only', '-s', 'public', '-f', target],
		{ encoding: 'utf-8', stdio: ['inherit', 'pipe', 'pipe'] }
	);
	if (command.status !== 0) {
		console.error(command.stderr || command.error?.message || '');
		console.error('No se pudo volcar la base enlazada. Usa --dump con una copia local.');
		process.exit(command.status ?? 1);
	}
	return target;
}

/**
 * Lee las sentencias `INSERT INTO "public"."tabla" (...) VALUES (...), (...);`
 * de un volcado de pg_dump con standard_conforming_strings activo.
 */
export function readDump(path) {
	const sql = readFileSync(path, 'utf-8');
	const tables = new Map();
	const header = /INSERT INTO "public"\."([a-z0-9_]+)" \(([^)]*)\) VALUES\s*/g;

	let match;
	while ((match = header.exec(sql)) !== null) {
		const table = match[1];
		const columns = match[2].split(',').map((name) => name.trim().replace(/"/g, ''));
		const { rows, end } = readTuples(sql, header.lastIndex);
		header.lastIndex = end;

		const collected = tables.get(table) ?? [];
		for (const values of rows) {
			if (values.length !== columns.length) continue;
			const row = {};
			columns.forEach((name, index) => {
				row[name] = values[index];
			});
			collected.push(row);
		}
		tables.set(table, collected);
	}
	return tables;
}

function readTuples(sql, start) {
	const rows = [];
	let index = start;

	while (index < sql.length) {
		while (index < sql.length && /\s/.test(sql[index])) index += 1;
		if (sql[index] !== '(') break;
		index += 1;

		const values = [];
		let raw = '';
		let depth = 0;

		while (index < sql.length) {
			const character = sql[index];

			if (character === "'") {
				index += 1;
				let text = '';
				while (index < sql.length) {
					if (sql[index] === "'") {
						if (sql[index + 1] === "'") {
							text += "'";
							index += 2;
							continue;
						}
						index += 1;
						break;
					}
					text += sql[index];
					index += 1;
				}
				values.push(text);
				raw = null;
				continue;
			}

			if (character === '(') depth += 1;
			if (character === ')' && depth > 0) depth -= 1;
			else if (character === ')' && depth === 0) {
				if (raw !== null) values.push(literal(raw));
				index += 1;
				break;
			}

			if (character === ',' && depth === 0) {
				if (raw !== null) values.push(literal(raw));
				raw = '';
				index += 1;
				continue;
			}

			if (raw === null) {
				// ya se ha consumido una cadena; solo quedan separadores
				index += 1;
				continue;
			}
			raw += character;
			index += 1;
		}

		rows.push(values);
		while (index < sql.length && /\s/.test(sql[index])) index += 1;
		if (sql[index] === ',') {
			index += 1;
			continue;
		}
		if (sql[index] === ';') index += 1;
		break;
	}

	return { rows, end: index };
}

function literal(raw) {
	const value = raw.trim();
	if (value === '' || value.toUpperCase() === 'NULL') return null;
	if (value === 'true') return true;
	if (value === 'false') return false;
	if (/^-?\d+$/.test(value)) return Number(value);
	if (/^-?\d*\.\d+$/.test(value)) return Number(value);
	return value;
}
