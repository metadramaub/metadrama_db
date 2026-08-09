import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

/**
 * Carga `.env.local` si la variable no viene ya del entorno.
 *
 * Vite lo hace por su cuenta para la aplicación, pero un script suelto no: `node
 * scripts/gen-types.mjs` no ve nada de ese archivo. Sin esto, el comando fallaba pidiendo una
 * variable que **sí estaba configurada**, solo que en un sitio que él no miraba.
 */
function cargarEnvLocal() {
	const ruta = fileURLToPath(new URL('../.env.local', import.meta.url));
	if (!existsSync(ruta)) return;
	for (const linea of readFileSync(ruta, 'utf-8').split(/\r?\n/)) {
		const limpia = linea.trim();
		if (!limpia || limpia.startsWith('#')) continue;
		const separador = limpia.indexOf('=');
		if (separador < 0) continue;
		const clave = limpia.slice(0, separador).trim();
		if (process.env[clave]) continue;
		process.env[clave] = limpia
			.slice(separador + 1)
			.trim()
			.replace(/^["']|["']$/g, '');
	}
}

cargarEnvLocal();

const projectRef = process.env.SUPABASE_PROJECT_REF;
const supabaseCli = fileURLToPath(
	new URL('../node_modules/supabase/dist/supabase.js', import.meta.url)
);

if (!projectRef) {
	console.error(
		'Falta SUPABASE_PROJECT_REF. Se busca en el entorno y en .env.local; añádela a uno de los dos.'
	);
	process.exit(1);
}

const command = spawnSync(
	process.execPath,
	[
		supabaseCli,
		'gen',
		'types',
		'typescript',
		'--project-id',
		projectRef,
		'--schema',
		'public'
	],
	{
		encoding: 'utf-8',
		stdio: ['inherit', 'pipe', 'inherit']
	}
);

if (command.status !== 0 || !command.stdout) {
	if (command.error) {
		console.error(command.error.message);
	}
	console.error('Failed to generate types from Supabase.');
	process.exit(command.status ?? 1);
}

writeFileSync('src/lib/types/database.types.ts', command.stdout);
console.log('Generated src/lib/types/database.types.ts');
