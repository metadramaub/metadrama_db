/** API real en loopback del contenedor sin red. JWT sintético; ninguna credencial remota. */
import { spawnSync } from 'node:child_process';
import { randomBytes, createHmac } from 'node:crypto';
import { writeFileSync } from 'node:fs';
const contenedor = 'versologia-control-obras-preparacion';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
	if (r.status !== 0) throw Error((r.stderr || 'Docker').slice(-2000));
	return r.stdout;
}
const cfg = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	cfg.HostConfig.NetworkMode !== 'none' ||
	Object.keys(cfg.HostConfig.PortBindings ?? {}).length ||
	cfg.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Contenedor no aislado');
const sql = (s) =>
	docker(
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
		s
	).trim();
function detenerApi() {
	const procesos = docker(['exec', contenedor, 'ps', '-eo', 'pid,args']);
	for (const linea of procesos.split('\n')) {
		const m = linea.match(/^\s*(\d+)\s+\/tmp\/postgrest\s*$/);
		if (m) docker(['exec', '-u', 'root', contenedor, 'kill', '-KILL', m[1]]);
	}
}
const gestor = sql(
	"select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino in ('admin','ip') limit 1"
);
const editor = sql(
	"select e.user_id from public.editores e join public.vocabularios v on v.termino_id=e.role where coalesce(e.activo,true) and v.termino='editor' limit 1"
);
const secreto = randomBytes(32).toString('hex');
const claveLocal = randomBytes(32).toString('hex');
sql(`alter role authenticator password '${claveLocal}'`);
detenerApi();
const token = (sub) => {
	const h = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
	const p = Buffer.from(
		JSON.stringify({ role: 'authenticated', sub, exp: Math.floor(Date.now() / 1000) + 300 })
	).toString('base64url');
	return (
		h +
		'.' +
		p +
		'.' +
		createHmac('sha256', secreto)
			.update(h + '.' + p)
			.digest('base64url')
	);
};
docker([
	'exec',
	'-d',
	'-e',
	`PGRST_DB_URI=postgresql://authenticator:${claveLocal}@127.0.0.1:5432/control_obras_preparacion`,
	'-e',
	'PGRST_DB_ANON_ROLE=anon',
	'-e',
	`PGRST_JWT_SECRET=${secreto}`,
	'-e',
	'PGRST_SERVER_HOST=127.0.0.1',
	'-e',
	'PGRST_SERVER_PORT=58080',
	contenedor,
	'bash',
	'-c',
	'exec /tmp/postgrest >/tmp/control-obras-postgrest.log 2>&1'
]);
const pruebas = [];
function exigir(p, n) {
	if (!p) throw Error(n);
	pruebas.push(n);
}
function request(path, sub = null, method = 'GET', body) {
	const args = [
		'exec',
		contenedor,
		'curl',
		'--silent',
		'--show-error',
		'--max-time',
		'15',
		'-X',
		method,
		'-w',
		'\n%{http_code}',
		'-H',
		'Content-Type: application/json'
	];
	if (sub) args.push('-H', 'Authorization: Bearer ' + token(sub));
	if (body !== undefined) args.push('-d', JSON.stringify(body));
	args.push('http://127.0.0.1:58080/' + path);
	const out = docker(args);
	const k = out.lastIndexOf('\n');
	const texto = out.slice(0, k);
	return { status: Number(out.slice(k + 1)), data: texto ? JSON.parse(texto) : null };
}
let id;
try {
	let ready = false;
	for (let i = 0; i < 15; i++) {
		try {
			const r = request('');
			if (r.status === 200) {
				ready = true;
				break;
			}
		} catch {}
		await new Promise((r) => setTimeout(r, 200));
	}
	exigir(ready, 'PostgREST disponible solo dentro del contenedor');
	const publico = request('obras_consulta_publica?select=obra_id&limit=500');
	exigir(
		publico.status === 200 &&
			publico.data.length ===
				Number(
					sql(
						"select count(*) from public.fichas_completas f join public.vocabularios v on v.termino_id=f.estado where v.termino='publicado' and f.visible_publico"
					)
				),
		'Lectura pública limitada por estado y visibilidad'
	);
	const anidada = request('obras_consulta_publica?select=obra_id,obras_resumen(obra_id)&limit=1');
	exigir(anidada.status === 200, 'Relación anidada de resumen desde la proyección pública');
	exigir(request('obras_editoriales').status === 401, 'Vista editorial inaccesible al anónimo');
	const total = Number(sql('select count(*) from public.obras'));
	const inventario = request('obras_editoriales?select=obra_id', gestor);
	exigir(
		inventario.status === 200 && inventario.data.length === total,
		'Gestor consulta inventario completo: ' +
			(inventario.status === 200
				? 'recuento ' + inventario.data.length
				: inventario.status + ' ' + inventario.data?.message)
	);
	exigir(
		request('obras_editoriales?select=obra_id', editor).data.length < total,
		'Editor no consulta el inventario ajeno'
	);
	const creada = request('obras_editoriales?select=obra_id,titulo,tipo_ficha', gestor, 'POST', {
		titulo: 'Ensayo API: obra sin ficha',
		tipo_ficha: 'sin_ficha'
	});
	// Sin Prefer return=representation, PostgREST devuelve 201 sin cuerpo.
	exigir(creada.status === 201, 'Creación por API mediante trigger de la proyección');
	id = sql("select obra_id from public.obras where titulo='Ensayo API: obra sin ficha'");
	exigir(Boolean(id), 'Identidad conservada tras crear por API');
	const r = request('rpc/gestionar_corpus', gestor, 'POST', {
		p_operacion: 'anadir',
		p_codigo: 'C60',
		p_obras: [id]
	});
	exigir(r.status === 204, 'Asignación de corpus por RPC autorizada');
	exigir(
		request('rpc/gestionar_corpus', editor, 'POST', {
			p_operacion: 'anadir',
			p_codigo: 'TAD',
			p_obras: [id]
		}).status === 403,
		'Editor no modifica corpus'
	);
	exigir(
		request('obras_editoriales?obra_id=eq.' + id, gestor, 'PATCH', {
			titulo: 'Ensayo API: título actualizado'
		}).status === 204,
		'Actualización por API sobre identidad existente'
	);
	exigir(
		sql(`select titulo from public.obras where obra_id='${id}'`) ===
			'Ensayo API: título actualizado',
		'Escritura efectiva en el núcleo de metadatos'
	);
	writeFileSync(
		'backups/control-obras/cambio/api.json',
		JSON.stringify({ ejecutado_en: new Date().toISOString(), pruebas }, null, 2) + '\n',
		'utf8'
	);
	console.log(
		`${pruebas.length} comprobaciones HTTP correctas, incluida relación pública anidada.`
	);
} finally {
	if (id) {
		const r = request('obras_editoriales?obra_id=eq.' + id, gestor, 'DELETE');
		if (r.status !== 204) throw Error('No se pudo retirar el registro de ensayo API');
	}
	detenerApi();
}
