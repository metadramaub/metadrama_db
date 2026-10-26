/** PostgreSQL real, aislado y sin clientes ni credenciales de producción. */
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';

const args = process.argv.slice(2);
const arg = (name) => args[args.indexOf(name) + 1];
if (!args.includes('--esquema') || !args.includes('--datos'))
	throw Error('Uso: --esquema <SQL> --datos <SQL> [--contenedor <nombre>]');
const container = args.includes('--contenedor')
	? arg('--contenedor')
	: 'versologia-pie-quebrado-pruebas';
const docker = (args, input) => {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
	if (r.status !== 0) throw Error(r.stderr || r.error?.message || r.stdout);
	return r.stdout;
};
const config = JSON.parse(docker(['inspect', container]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length
)
	throw Error('El contenedor debe estar aislado, sin red ni puertos publicados');
const db = `quebrados_${randomUUID().replaceAll('-', '')}`;
const psql = (sql, database = db) =>
	docker(
		[
			'exec',
			'-i',
			container,
			'psql',
			'-X',
			'-q',
			'-At',
			'-U',
			'postgres',
			'-d',
			database,
			'-v',
			'ON_ERROR_STOP=1'
		],
		sql
	);
const read = (path) => readFileSync(new URL(path, import.meta.url), 'utf8');
const fingerprint = `select md5(coalesce(string_agg(t::text,'' order by t::text),'')) from (
select to_jsonb(x) t from public.anotaciones_metricas x union all
select to_jsonb(x) from public.anotacion_realizaciones x union all
select to_jsonb(x) from public.anotacion_elecciones x union all
select to_jsonb(x) from public.anotacion_desviaciones x) datos;`;
psql(`create database ${db} template template0;`, 'postgres');
try {
	psql(`create schema auth;create schema extensions;
create extension "uuid-ossp" with schema extensions;create extension pgcrypto with schema extensions;
create extension pg_trgm with schema extensions;create extension unaccent with schema extensions;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema auth,extensions to anon,authenticated,service_role;
${readFileSync(arg('--esquema'), 'utf8')}`);
	psql(readFileSync(arg('--datos'), 'utf8'));
	const before = psql(fingerprint).trim();
	const unresolved = `select coalesce(jsonb_agg(eleccion_id order by eleccion_id),'[]'::jsonb) from public.anotacion_elecciones_resueltas where opcion_eleccion_id is null and valor_texto is null;`;
	const beforeUnresolved = psql(unresolved).trim();
	psql(
		read(
			'../../supabase/migrations/20261026090000_el_quebrado_conserva_su_disposicion.sql'
		)
	);
	if (before !== psql(fingerprint).trim()) throw Error('Se modificaron anotaciones anteriores');
	if (beforeUnresolved !== psql(unresolved).trim())
		throw Error('Una respuesta anterior perdió su opción de catálogo');
	console.log('OK: anotaciones, realizaciones, elecciones y desviaciones anteriores intactas');
	console.log('OK: ninguna respuesta anterior pierde su opción de catálogo');
	console.log(psql(read('./pie-quebrado-pruebas.sql')).trim());
} finally {
	psql(`drop database ${db} with (force);`, 'postgres');
}
