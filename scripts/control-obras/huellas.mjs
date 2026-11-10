/** Huellas de todas las filas; no exporta valores ni credenciales al informe. */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { query } from '../lib/consulta.mjs';
const carpeta = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
const tablas = query(
	"select n.nspname as esquema,c.relname as tabla from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','auth','storage','supabase_migrations') and c.relkind='r' order by 1,2"
);
const ident = (s) => '"' + s.replaceAll('"', '""') + '"';
const lit = (s) => "'" + s.replaceAll("'", "''") + "'";
const sql = tablas
	.map(
		({ esquema, tabla }) =>
			`select ${lit(esquema + '.' + tabla)} as tabla,count(*)::integer as filas,encode(extensions.digest(coalesce(string_agg(encode(extensions.digest(convert_to(to_jsonb(t)::text,'UTF8'),'sha256'),'hex'),'' order by encode(extensions.digest(convert_to(to_jsonb(t)::text,'UTF8'),'sha256'),'hex')),''),'sha256'),'hex') as sha256 from ${ident(esquema)}.${ident(tabla)} t`
	)
	.join('\nunion all\n');
writeFileSync(join(carpeta, 'huellas.sql'), sql + ';\n', 'utf8');
const huellas = query(
	'begin transaction isolation level repeatable read read only;\n' + sql + ';\ncommit;'
);
writeFileSync(
	join(carpeta, 'huellas-remotas.json'),
	JSON.stringify({ consultado_en: new Date().toISOString(), tablas: huellas }, null, 2) + '\n',
	'utf8'
);
console.log(`Huellas remotas de ${huellas.length} tablas guardadas, sin modificar registros.`);
