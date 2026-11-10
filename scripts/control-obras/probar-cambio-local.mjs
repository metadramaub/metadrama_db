import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
const contenedor = 'versologia-control-obras-preparacion';
const inspeccion = spawnSync('docker', ['inspect', contenedor], { encoding: 'utf8' });
const cfg = JSON.parse(inspeccion.stdout)[0];
if (
	cfg.HostConfig.NetworkMode !== 'none' ||
	Object.keys(cfg.HostConfig.PortBindings ?? {}).length ||
	cfg.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Contenedor no aislado');
const prueba = readFileSync(new URL('./pruebas-cambio.sql', import.meta.url), 'utf8');
const r = spawnSync(
	'docker',
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
		'control_obras_preparacion',
		'-v',
		'ON_ERROR_STOP=1'
	],
	{ input: prueba, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }
);
writeFileSync('backups/control-obras/cambio/pruebas.log', r.stdout + r.stderr, 'utf8');
if (r.status !== 0) throw Error(r.stderr.slice(-2800));
console.log(r.stdout);
