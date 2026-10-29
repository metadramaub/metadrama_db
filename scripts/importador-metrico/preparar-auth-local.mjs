/** Solo Supabase local del importador: esquema exportado + personas y catálogo sintéticos. */
import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';
import { semillaImportador } from './fixtures-locales.mjs';

const args = process.argv.slice(2);
if (args.length !== 2 || args[0] !== '--esquema')
	throw Error(
		'Uso: node scripts/importador-metrico/preparar-auth-local.mjs --esquema <volcado público>'
	);
const config = JSON.parse(
	readFileSync('backups/importador-auth/status.json', 'utf8').replace(/^\uFEFF/, '')
);
const url = new URL(config.API_URL);
if (url.origin !== 'http://127.0.0.1:55421')
	throw Error('Solo se admite la API local del ensayo, puerto 55421');
const container = 'supabase_db_versologia_importador_auth';
const run = (args, input) => {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
	if (r.status !== 0) throw Error(r.stderr || r.error?.message || 'Falló Docker local');
	return r.stdout;
};
const inspect = JSON.parse(run(['inspect', container]))[0];
if (inspect.Config.Labels['com.supabase.cli.project'] !== 'versologia_importador_auth')
	throw Error('El contenedor no pertenece al proyecto de ensayo');
const sql = (s) =>
	run(
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
			'postgres',
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
if (
	sql(
		"select count(*) from information_schema.tables where table_schema='public' and table_name='obras'"
	).trim() !== '0'
)
	throw Error('La base ya tiene obras. No se sobrescribe ni se borra un ensayo previo.');
const admin = createClient(url.origin, config.SERVICE_ROLE_KEY, {
	auth: { persistSession: false, autoRefreshToken: false }
});
const password = randomBytes(24).toString('base64url');
const usuarios = [];
for (let i = 0; i < 7; i++) {
	const email = `prueba${i}@example.invalid`;
	const r = await admin.auth.admin.createUser({ email, password, email_confirm: true });
	if (r.error) throw Error(`No se pudo crear la cuenta sintética ${i}: ${r.error.code}`);
	usuarios.push({ id: r.data.user.id, email });
}
sql(readFileSync(args[1], 'utf8'));
for (const n of [
	'01-almacenamiento',
	'02-esquema-documento',
	'03-guardar',
	'04-consulta',
	'05-aislamiento'
])
	sql(readFileSync(new URL(`./sql/${n}.sql`, import.meta.url), 'utf8'));
sql(
	semillaImportador(
		usuarios.map((u) => u.id),
		false
	) + "\nnotify pgrst,'reload schema';"
);
writeFileSync(
	'backups/importador-auth/cuentas.json',
	JSON.stringify({ usuarios, password }, null, 2)
);
console.log(
	'Supabase local preparado: 7 cuentas sintéticas, esquema exportado y borrador del importador. Credenciales solo en backups ignorado.'
);
