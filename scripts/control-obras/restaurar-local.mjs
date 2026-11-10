/** Restaura exclusivamente una base nueva en el contenedor aislado de esta preparación. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, join } from 'node:path';

const carpeta = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
const contenedor = 'versologia-control-obras-preparacion';
const base = 'control_obras_preparacion';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
	if (r.status !== 0) throw Error((r.stderr || r.error?.message || 'Falló Docker').slice(-3500));
	return r.stdout;
}
const config = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length ||
	config.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Se exige contenedor propio, sin red y sin puertos publicados.');
const psql = (s) =>
	docker(
		[
			'exec',
			'-i',
			contenedor,
			'psql',
			'-X',
			'-q',
			'-At',
			'-U',
			'supabase_admin',
			'-d',
			base,
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
if (psql("select to_regclass('public.obras') is not null").trim() !== 'f')
	throw Error('La base ya contiene obras; no se sobrescribe un ensayo previo.');
for (const file of [
	'schema.sql',
	'data.sql',
	'roles.sql',
	'managed-schema.sql',
	'migration-ledger.sql'
])
	if (!existsSync(join(carpeta, file)) || !readFileSync(join(carpeta, file)).length)
		throw Error(`Falta copia no vacía: ${file}`);
const reanudar = process.argv[3] === '--reanudar-esquema';
if (process.argv[3] && !reanudar) throw Error('Opción desconocida.');
if (!reanudar)
	psql(
		'create schema if not exists extensions; create schema if not exists vault; create publication supabase_realtime;'
	);
const archivos = reanudar
	? ['schema.sql', 'data.sql', 'migration-ledger.sql']
	: ['roles.sql', 'managed-schema.sql', 'schema.sql', 'data.sql', 'migration-ledger.sql'];
for (const file of archivos) {
	console.log(`Restaurando ${file} en ${contenedor}/${base}…`);
	// No se transforma el volcado. El de datos ya desactiva triggers para los ciclos de FK.
	const salida = psql(readFileSync(join(carpeta, file), 'utf8'));
	writeFileSync(join(carpeta, `restauracion-${file}.log`), salida, 'utf8');
}
psql('set session_replication_role=origin;');
console.log(
	'Restauración completa terminada; pendiente validación de filas, referencias y funciones.'
);
