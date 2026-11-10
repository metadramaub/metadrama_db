/** Aplica exclusivamente la candidata generada a la restauración aislada. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
const contenedor = 'versologia-control-obras-preparacion';
function docker(args, input, binario = false) {
	const r = spawnSync('docker', args, {
		input,
		encoding: binario ? null : 'utf8',
		maxBuffer: 64 * 1024 * 1024
	});
	if (r.status !== 0) throw Error(String(r.stderr || 'Docker').slice(-2500));
	return r.stdout;
}
const c = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	c.HostConfig.NetworkMode !== 'none' ||
	Object.keys(c.HostConfig.PortBindings ?? {}).length ||
	c.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Contenedor no aislado');
mkdirSync('backups/control-obras/cambio', { recursive: true });
const destino = 'backups/control-obras/cambio/antes-cambio.dump';
if (!existsSync(destino))
	writeFileSync(
		destino,
		docker(
			[
				'exec',
				contenedor,
				'pg_dump',
				'-U',
				'supabase_admin',
				'-d',
				'control_obras_preparacion',
				'-Fc'
			],
			undefined,
			true
		)
	);
const salida = docker(
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
	readFileSync('scripts/control-obras/002-cambio-ensayo.sql', 'utf8')
);
writeFileSync('backups/control-obras/cambio/aplicar.log', salida, 'utf8');
console.log(
	'Candidata aplicada exclusivamente en la restauración aislada; copia previa conservada.'
);
