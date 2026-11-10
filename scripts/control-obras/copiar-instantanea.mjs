/** Una instantánea pg_dump para public/Auth/Storage/historial; credenciales solo en memoria. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
const carpeta = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
const r = spawnSync(
	process.execPath,
	['node_modules/supabase/dist/supabase.js', 'db', 'dump', '--linked', '--dry-run'],
	{ encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 }
);
if (r.status !== 0) throw Error('No se pudo preparar la conexión temporal de lectura.');
const exports = r.stdout.split('\n').filter((l) => l.startsWith('export '));
if (!exports.some((l) => l.startsWith('export PGPASSWORD=')))
	throw Error('No se reconoce la configuración pg_dump; no se imprime para proteger credenciales.');
const guion = [
	'set -euo pipefail',
	...exports,
	'exec pg_dump --data-only --format=custom --quote-all-identifiers --role=postgres --schema=public --schema=auth --schema=storage --schema=supabase_migrations'
].join('\n');
const dump = spawnSync(
	'docker',
	[
		'run',
		'--rm',
		'-i',
		'--entrypoint',
		'bash',
		'public.ecr.aws/supabase/postgres:17.6.1.136',
		'-s'
	],
	{ input: guion, encoding: null, maxBuffer: 256 * 1024 * 1024 }
);
if (dump.status !== 0) {
	writeFileSync(join(carpeta, 'instantanea-error.log'), dump.stderr ?? Buffer.alloc(0));
	throw Error('Falló la instantánea; consultar el log privado.');
}
if (dump.stdout.subarray(0, 5).toString() !== 'PGDMP') throw Error('Archivo pg_dump no reconocido');
writeFileSync(join(carpeta, 'datos-consistentes.dump'), dump.stdout);
writeFileSync(join(carpeta, 'instantanea-advertencias.log'), dump.stderr ?? Buffer.alloc(0));
console.log(
	`Instantánea única guardada (${dump.stdout.length} bytes), incluidas las tablas internas de migraciones de Auth/Storage.`
);
