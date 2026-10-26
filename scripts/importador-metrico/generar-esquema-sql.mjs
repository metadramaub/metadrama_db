/** Genera únicamente la constante de validación SQL; no conecta ni aplica SQL. */
import { readFileSync, writeFileSync } from 'node:fs';
import { z } from 'zod';
import { fichaMinimaSchema } from '../lib/importador-metrico/ficha-minima.mjs';
import { extraccionSchema } from '../lib/importador-metrico/validacion.mjs';

if (process.argv.slice(2).some((a) => a !== '--comprobar')) throw new Error('Opción desconocida');
const path = new URL('./sql/02-esquema-documento.sql', import.meta.url);
const sql =
	'-- GENERADO con generar-esquema-sql.mjs. BORRADOR: no aplicar a la DB compartida.\n' +
	[
		['esquema_documento_minimo', fichaMinimaSchema],
		['esquema_extraccion_minima', extraccionSchema]
	]
		.map(
			([nombre, schema]) => `create or replace function public.${nombre}() returns json
language sql immutable set search_path = '' as $func$
  select $schema$${JSON.stringify(z.toJSONSchema(schema))}$schema$::json;
$func$;
revoke all on function public.${nombre}() from public,anon,authenticated;
`
		)
		.join('\n');
if (process.argv.includes('--comprobar')) {
	if (readFileSync(path, 'utf8') !== sql) throw new Error('Constante SQL desactualizada');
	console.log('Constante SQL comprobada; sin escritura ni conexión');
} else {
	writeFileSync(path, sql);
	console.log('Constante SQL generada; sin conexión');
}
