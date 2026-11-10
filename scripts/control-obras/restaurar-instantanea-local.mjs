/** Sustituye SOLO los datos de la restauración aislada y conserva antes otro archivo completo. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
const carpeta =
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim();
const contenedor = 'versologia-control-obras-preparacion',
	base = 'control_obras_preparacion';
function docker(args, input, binario = false) {
	const r = spawnSync('docker', args, {
		input,
		encoding: binario ? null : 'utf8',
		maxBuffer: 256 * 1024 * 1024
	});
	if (r.status !== 0) throw Error(String(r.stderr || r.error?.message || 'Docker').slice(-3000));
	return r.stdout;
}
const c = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	c.HostConfig.NetworkMode !== 'none' ||
	Object.keys(c.HostConfig.PortBindings ?? {}).length ||
	c.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Contenedor no aislado');
const sql = (s) =>
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
if (sql("select to_regclass('public.fichas_completas') is null").trim() !== 't')
	throw Error('Ya existe un ensayo de expansión; no se reemplaza.');
const previo = join(carpeta, 'restaurada-inicial-completa.dump');
if (existsSync(previo)) throw Error('La copia previa ya existe; no se sobrescribe.');
writeFileSync(
	previo,
	docker(
		['exec', contenedor, 'pg_dump', '-U', 'supabase_admin', '-d', base, '-Fc'],
		undefined,
		true
	)
);
sql(`set session_replication_role=replica;
do $$ declare tablas text; begin
 select string_agg(format('%I.%I',n.nspname,c.relname),',') into tablas
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname in ('public','auth','storage','supabase_migrations') and c.relkind='r';
 execute 'truncate table '||tablas||' restart identity cascade';
end $$;`);
const salida = docker(
	[
		'exec',
		'-i',
		contenedor,
		'pg_restore',
		'-U',
		'supabase_admin',
		'-d',
		base,
		'--data-only',
		'--disable-triggers',
		'--exit-on-error',
		'--single-transaction'
	],
	readFileSync(join(carpeta, 'datos-consistentes.dump'))
);
writeFileSync(join(carpeta, 'restauracion-instantanea.log'), salida, 'utf8');
console.log(
	'Instantánea consistente restaurada; la primera restauración también queda archivada íntegra.'
);
