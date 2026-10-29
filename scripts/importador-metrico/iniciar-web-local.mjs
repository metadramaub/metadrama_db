/** Web separada para el ensayo de Auth: no modifica .env ni la instancia de los editores. */
import { readFileSync } from 'node:fs';
import { spawn } from 'node:child_process';
const config = JSON.parse(
	readFileSync('backups/importador-auth/status.json', 'utf8').replace(/^\uFEFF/, '')
);
if (new URL(config.API_URL).origin !== 'http://127.0.0.1:55421')
	throw Error('Solo se admite la API local del ensayo');
const child = spawn(
	process.execPath,
	['node_modules/vite/bin/vite.js', '--host', '127.0.0.1', '--port', '5190', '--strictPort'],
	{
		stdio: 'inherit',
		env: {
			...process.env,
			PUBLIC_SUPABASE_URL: config.API_URL,
			VITE_SUPABASE_URL: config.API_URL,
			PUBLIC_SUPABASE_ANON_KEY: config.ANON_KEY,
			VITE_SUPABASE_ANON_KEY: config.ANON_KEY,
			SUPABASE_SERVICE_ROLE_KEY: config.SERVICE_ROLE_KEY
		}
	}
);
child.on('exit', (code) => {
	process.exitCode = code ?? 1;
});
