/**
 * Ensaya la migración del registro de correspondencias en un PostgreSQL efímero, sin red.
 * El catálogo y las funciones de permiso son sintéticos; no contacta Supabase.
 *
 *   docker run -d --rm --name versologia-registro-pruebas --network none \
 *     -e POSTGRES_PASSWORD=prueba-local postgres:17-alpine
 *   node scripts/importador-metrico/probar-registro-local.mjs
 */
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';

const CONTENEDOR = 'versologia-registro-pruebas';
const MIGRACION = '../../supabase/migrations/20261109180000_correspondencias_importador.sql';

function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
	if (r.status !== 0) throw new Error(r.stderr || r.stdout);
	return r.stdout;
}
const config = JSON.parse(docker(['inspect', CONTENEDOR]))[0];
if (config.HostConfig.NetworkMode !== 'none' || Object.keys(config.HostConfig.PortBindings ?? {}).length)
	throw new Error('El contenedor de pruebas debe ir sin red ni puertos.');

const db = 'registro_' + randomUUID().replaceAll('-', '');
const sql = (s, base = db) =>
	docker(['exec', '-i', CONTENEDOR, 'psql', '-X', '-q', '-At', '-U', 'postgres', '-d', base, '-v', 'ON_ERROR_STOP=1'], s);
const IMPORTADOR = '00000000-0000-4000-8000-000000000001';
const ADMIN = '00000000-0000-4000-8000-000000000002';
const cadena = (s) => "'" + s.replaceAll("'", "''") + "'";

let pruebas = 0;
const comprueba = (condicion, nombre) => {
	pruebas++;
	return `select pg_temp.comprueba((${condicion}), ${cadena(nombre)});\n`;
};
const rechaza = (sentencia, nombre) => {
	pruebas++;
	return `select pg_temp.rechaza(${cadena(sentencia)}, ${cadena(nombre)});\n`;
};
const como = (usuario, { importa = false, admin = false } = {}) => `reset role;
select set_config('request.jwt.claim.sub', '${usuario}', false);
select set_config('test.importa', '${importa ? 'si' : 'no'}', false);
select set_config('test.admin', '${admin ? 'si' : 'no'}', false);
set role authenticated;\n`;
const alta = (forma = 'seguidilla', { arquitectura = 'null', autor = null } = {}) =>
	`insert into public.correspondencias_importador (literal, forma, arquitectura, procedencia${autor ? ', creado_por' : ''})
	 values ('seguidilla', '${forma}', ${arquitectura}, '{"obra": "Prueba", "fila": "t01"}'${autor ? `, '${autor}'` : ''})`;
const filas = '(select count(*) from public.correspondencias_importador)';

sql(`create database ${db};`, 'postgres');
try {
	sql(`create schema auth;
		create table auth.users (id uuid primary key);
		insert into auth.users values ('${IMPORTADOR}'), ('${ADMIN}');
		do $$ begin
			if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated; end if;
			if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon; end if;
		end $$;
		create function auth.uid() returns uuid language sql stable
			as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
		create function public.auth_puede_importar_metrica() returns boolean language sql stable
			as $$ select coalesce(current_setting('test.importa', true), '') = 'si' $$;
		create function public.auth_is_admin_or_ip() returns boolean language sql stable
			as $$ select coalesce(current_setting('test.admin', true), '') = 'si' $$;
		create table public.formas_metricas (forma_id uuid primary key default gen_random_uuid(), slug text, activo boolean);
		create table public.arquitecturas_forma (forma_id uuid, slug text, activo boolean);
		insert into public.formas_metricas (slug, activo) values ('seguidilla', true), ('quintilla', true), ('retirada', false);
		insert into public.arquitecturas_forma select forma_id, 'propia', true from public.formas_metricas where slug = 'seguidilla';
		grant usage on schema auth, public to authenticated, anon;
		grant select on public.formas_metricas, public.arquitecturas_forma to authenticated;`);
	sql(readFileSync(new URL(MIGRACION, import.meta.url), 'utf8'));

	let s = `create function pg_temp.comprueba(p boolean, nombre text) returns text language plpgsql as $$
		begin if p is distinct from true then raise exception 'FALLO %', nombre; end if; return 'OK ' || nombre; end $$;
	create function pg_temp.rechaza(sentencia text, nombre text) returns text language plpgsql as $$
		begin
			begin execute sentencia;
			exception when insufficient_privilege or check_violation or unique_violation or foreign_key_violation then
				return 'OK ' || nombre;
			end;
			raise exception 'FALLO: se aceptó %', nombre;
		end $$;
	grant execute on function pg_temp.comprueba(boolean, text), pg_temp.rechaza(text, text) to authenticated, anon;\n`;

	s += como(IMPORTADOR, { importa: true });
	s += alta() + ';\n' + comprueba(`${filas} = 1`, 'quien importa registra');
	s += comprueba(
		`(select count(*) from public.correspondencias_importador where creado_por = '${IMPORTADOR}' and creado_en is not null) = 1`,
		'queda quién la señaló y cuándo'
	);
	s += rechaza(alta(), 'no se registra dos veces la misma');
	s += alta('quintilla') + ';\n' + comprueba(`${filas} = 2`, 'se conservan registros contradictorios');
	s += alta('seguidilla', { arquitectura: "'propia'" }) + ';\n' + comprueba(`${filas} = 3`, 'admite forma y arquitectura');
	s += rechaza(alta('inexistente'), 'forma fuera del catálogo');
	s += rechaza(alta('retirada'), 'forma inactiva');
	s += rechaza(alta('quintilla', { arquitectura: "'propia'" }), 'arquitectura de otra forma');
	s += rechaza(alta('seguidilla', { autor: ADMIN }), 'no se registra en nombre de otro');
	s += `update public.correspondencias_importador set revisado_por = '${IMPORTADOR}', revisado_en = now();\n`;
	s += comprueba('(select count(*) from public.correspondencias_importador where revisado_por is not null) = 0', 'quien importa no revisa');
	s += 'delete from public.correspondencias_importador;\n' + comprueba(`${filas} = 3`, 'quien importa no borra');

	s += como(ADMIN, { admin: true });
	s += comprueba(`${filas} = 3`, 'admin/IP consulta');
	s += rechaza("update public.correspondencias_importador set forma = 'quintilla'", 'nadie reescribe el destino');
	s += `update public.correspondencias_importador set revisado_por = '${ADMIN}', revisado_en = now() where forma = 'quintilla';\n`;
	s += comprueba(`(select count(*) from public.correspondencias_importador where revisado_por = '${ADMIN}') = 1`, 'admin/IP marca revisada');
	s += "delete from public.correspondencias_importador where forma = 'quintilla';\n";
	s += comprueba(`${filas} = 2`, 'admin/IP retira una correspondencia');

	s += como(IMPORTADOR);
	s += comprueba(`${filas} = 0`, 'sin permiso no consulta');
	s += rechaza(alta('quintilla'), 'sin permiso no registra');
	s += 'reset role;\nset role anon;\n';
	s += rechaza('select * from public.correspondencias_importador', 'anónimo no consulta');

	console.log(sql(s).split('\n').filter((l) => l.startsWith('OK')).join('\n'));
	console.log(JSON.stringify({ pruebas, resultado: 'correcto', limite: 'Catálogo y permisos sintéticos.' }));
} finally {
	sql(`drop database ${db} with (force);`, 'postgres');
}
