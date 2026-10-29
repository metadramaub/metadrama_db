/** Empaqueta el SQL revisado. No conecta a ninguna DB ni publica una migración. */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const fuentes = [
	'01-almacenamiento',
	'02-esquema-documento',
	'03-guardar',
	'04-consulta',
	'05-aislamiento'
];
export const destino = new URL('./promocion/importador-basico.sql', import.meta.url);
export function compilarPromocion() {
	const bloques = fuentes.map((n) => {
		let s = readFileSync(new URL(`./sql/${n}.sql`, import.meta.url), 'utf8')
			.replace(/\r\n/g, '\n')
			.trim();
		if (n !== '02-esquema-documento') {
			const apertura = s.indexOf('\nbegin;\n');
			if (apertura < 0 || !s.endsWith('\ncommit;')) throw Error(`Revisar transacción de ${n}`);
			s = s.slice(0, apertura) + s.slice(apertura + '\nbegin;'.length, -'\ncommit;'.length);
		}
		if (/^\s*(begin|commit|rollback);\s*$/im.test(s))
			throw Error(`Transacción interna inesperada: ${n}`);
		return `-- Fuente: sql/${n}.sql\n${s}`;
	});
	return `-- CANDIDATA PARA REVISIÓN. No aplicada al Supabase compartido.
-- Generada con compilar-promocion.mjs. Fuera de supabase/migrations hasta aprobación.
-- No incluye la corrección de prosa ni ejecuta recálculos o importaciones.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '120s';
do $precondiciones$
begin
 if not exists(select 1 from pg_available_extensions where name='pg_jsonschema') then
  raise exception 'Falta pg_jsonschema en el servidor';
 end if;
 if to_regclass('public.obras') is null or to_regclass('public.editores') is null
  or to_regprocedure('public.auth_puede_editar_obra(uuid)') is null then
  raise exception 'No se reconoce el esquema editorial esperado';
 end if;
end;
$precondiciones$;

${bloques.join('\n\n')}

notify pgrst, 'reload schema';
commit;
`;
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
	const args = process.argv.slice(2);
	if (args.length && !(args.length === 1 && args[0] === '--comprobar'))
		throw Error('Uso: compilar-promocion.mjs [--comprobar]');
	const sql = compilarPromocion();
	if (args.length) {
		if (readFileSync(destino, 'utf8').replace(/\r\n/g, '\n') !== sql)
			throw Error('La candidata no coincide con los cinco SQL fuente');
		console.log('Candidata transaccional sincronizada con los cinco SQL.');
	} else {
		mkdirSync(new URL('./promocion/', import.meta.url), { recursive: true });
		writeFileSync(destino, sql);
		console.log('Candidata escrita fuera de supabase/migrations. Sin conexión a DB.');
	}
}
