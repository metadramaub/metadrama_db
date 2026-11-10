/** Acceso exclusivo al contenedor de restauración; nunca acepta URL remota. */
import { spawnSync } from 'node:child_process';
export const contenedor = 'versologia-control-obras-preparacion';
export function docker(args, input, binario = false) {
	const r = spawnSync('docker', args, {input, encoding: binario ? null : 'utf8', maxBuffer: 64 * 1024 * 1024});
	if (r.status !== 0) throw Error(String(r.stderr || r.error?.message || 'Falló Docker').slice(-2500));
	return r.stdout;
}
export function exigirAislamiento() {
	const c = JSON.parse(docker(['inspect', contenedor]))[0];
	if(c.HostConfig.NetworkMode !== 'none' || Object.keys(c.HostConfig.PortBindings ?? {}).length || c.Config.Labels['versologia.tarea'] !== 'control-obras') throw Error('Se exige la restauración aislada, sin red ni puertos.');
}
export const sql = s => docker(['exec','-i',contenedor,'psql','-X','-q','-At','-U','supabase_admin','-d','control_obras_preparacion','-v','ON_ERROR_STOP=1'],s).trim();
export const filas = s => JSON.parse(sql(`select coalesce(jsonb_agg(to_jsonb(t)),'[]') from (${s}) t;`));
