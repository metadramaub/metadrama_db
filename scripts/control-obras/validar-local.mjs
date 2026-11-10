/** Integridad de la restauración, expansión repetida y reversión, solo en Docker sin red. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
const carpeta = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
const contenedor = 'versologia-control-obras-preparacion',
	base = 'control_obras_preparacion';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
	if (r.status !== 0) throw Error((r.stderr || r.error?.message || 'Docker').slice(-3500));
	return r.stdout;
}
const c = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	c.HostConfig.NetworkMode !== 'none' ||
	Object.keys(c.HostConfig.PortBindings ?? {}).length ||
	c.Config.Labels['versologia.tarea'] !== 'control-obras'
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
			base,
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
const json = (q) =>
	JSON.parse(
		sql(`select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (${q.replace(/;\s*$/, '')}) x;`).trim()
	);
if(sql("select to_regclass('public.obras_editoriales') is not null").trim()==='t')
	throw Error('El ensayo ya está en la fase de cambio editorial. Usar probar-cambio-local.mjs; no revertir su expansión.');
const registro = { ejecutado_en: new Date().toISOString(), comprobaciones: [] };
function ok(cond, nombre) {
	if (!cond) throw Error('FALLO: ' + nombre);
	registro.comprobaciones.push(nombre);
	console.log('OK ' + nombre);
}
const huellasSql = readFileSync(join(carpeta, 'huellas.sql'), 'utf8');
const huellas = () => json(huellasSql);
const orden = (a) => [...a].sort((a, b) => a.tabla.localeCompare(b.tabla));
const igual = (a, b) => JSON.stringify(orden(a)) === JSON.stringify(orden(b));
const antes = huellas();
const remotas = JSON.parse(readFileSync(join(carpeta, 'huellas-remotas.json'), 'utf8')).tablas;
writeFileSync(
	join(carpeta, 'huellas-restauradas.json'),
	JSON.stringify(antes, null, 2) + '\n',
	'utf8'
);
const diferentes = remotas
	.filter((r) => {
		const l = antes.find((x) => x.tabla === r.tabla);
		return !l || l.filas !== r.filas || l.sha256 !== r.sha256;
	})
	.map((x) => x.tabla);
writeFileSync(
	join(carpeta, 'diferencias-restauracion.json'),
	JSON.stringify(diferentes, null, 2) + '\n',
	'utf8'
);
// Auth puede cambiar mientras los editores siguen conectados. La instantánea pg_dump es
// coherente en su propio instante; no se atribuyen las sesiones posteriores a pérdida de datos.
registro.diferencias_con_consulta_remota = diferentes;
ok(
	!diferentes.some((t) => t.startsWith('public.') || t.startsWith('supabase_migrations.')),
	'Todas las tablas de aplicación e historial coinciden con la consulta remota (recuento y SHA-256)'
);

// Las cargas desactivan triggers para los ciclos: comprobar todas las FK mediante anti-joins.
const fk =
	json(`select con.conname,con.conrelid::regclass::text as origen,con.confrelid::regclass::text as destino,
 string_agg(format('o.%I = d.%I',a.attname,b.attname),' and ' order by k.n) as enlace,
 string_agg(format('o.%I is not null',a.attname),' and ' order by k.n) as no_nulo
 from pg_constraint con join pg_class t on t.oid=con.conrelid join pg_namespace ns on ns.oid=t.relnamespace
 cross join lateral generate_subscripts(con.conkey,1) k(n)
 join pg_attribute a on a.attrelid=con.conrelid and a.attnum=con.conkey[k.n]
 join pg_attribute b on b.attrelid=con.confrelid and b.attnum=con.confkey[k.n]
 where con.contype='f' and ns.nspname in ('public','auth','storage') group by con.oid`);
const lit = (s) => "'" + s.replaceAll("'", "''") + "'";
const referencias = json(
	fk
		.map(
			(f) =>
				`select ${lit(f.origen + '.' + f.conname)} as nombre,not exists(select 1 from ${f.origen} o where ${f.no_nulo} and not exists(select 1 from ${f.destino} d where ${f.enlace})) as valida`
		)
		.join(' union all ')
);
registro.referencias_comprobadas = referencias.length;
ok(
	referencias.every((f) => f.valida),
	`${referencias.length} claves foráneas sin referencias huérfanas`
);
ok(
	sql(
		"select not exists(select 1 from public.importaciones_metricas where sha256_jsonb<>encode(extensions.digest(convert_to(datos_confirmados::text,'UTF8'),'sha256'),'hex'))"
	).trim() === 't',
	'Huellas declaradas de importaciones confirmadas'
);
const candidata = readFileSync(new URL('./001-expandir-ensayo.sql', import.meta.url), 'utf8');
sql(candidata);
ok(
	igual(antes, huellas()),
	'Expansión conserva todas las filas originales, Auth, Storage y artefactos'
);
const nuevas = () =>
	json(
		"select 'fichas_completas' as tabla,count(*)::integer as filas,md5(string_agg(to_jsonb(t)::text,'' order by obra_id)) as sha256 from public.fichas_completas t union all select 'corpus',count(*)::integer,md5(string_agg(to_jsonb(t)::text,'' order by codigo)) from public.corpus t"
	);
const primera = nuevas();
sql(candidata);
ok(igual(primera, nuevas()), 'Expansión idempotente sin cambiar fechas ni contenido');
ok(
	sql(
		"select (select count(*) from public.fichas_completas)=(select count(*) from public.obras where tipo_ficha='completa')"
	).trim() === 't',
	'Todas las completas heredadas conservadas'
);
ok(
	sql(
		'select not exists(select 1 from public.fichas_completas where inicio_elaboracion is not null)'
	).trim() === 't',
	'Sin fechas de inicio inventadas'
);
ok(
	sql('select count(*)=0 from public.obras_corpus').trim() === 't',
	'Sin pertenencias inferidas ni carga automática del CSV'
);
ok(
	sql(
		"select not has_table_privilege('anon','public.fichas_completas','select') and not has_table_privilege('authenticated','public.fichas_completas','update')"
	).trim() === 't',
	'Sin apertura anónima ni escritura directa de fichas'
);

// Ejecutar funciones sobre TODAS las obras, no solo comprobar que se crean.
const ejecuciones = [];
for (const expresion of [
	'public.auth_puede_ver_obra(o.obra_id)',
	'public.auth_puede_editar_obra(o.obra_id)',
	'public.auth_puede_consultar_importacion(o.obra_id)',
	'public.can_view_obra_ficha_publica(o.obra_id,false)',
	'public.get_obra_ficha_publica(o.obra_id,true)'
]) {
	sql(`select count(${expresion}) from public.obras o`);
	ejecuciones.push(expresion);
}
registro.funciones_ejecutadas = ejecuciones;
ok(true, 'Permisos y productor de ficha ejecutados sobre todas las obras');
// Recompute completo en una transacción que se revierte: prueba cuerpos PL/pgSQL sin alterar el ensayo.
sql('begin; select public.recompute_all(); rollback;');
ok(igual(antes, huellas()), 'recompute_all ejecutado y revertido sin alterar el origen');
sql(readFileSync(new URL('./revertir-expansion-ensayo.sql', import.meta.url), 'utf8'));
ok(igual(antes, huellas()), 'Reversión aditiva conserva íntegramente la restauración');
sql(candidata);
ok(igual(antes, huellas()), 'Reaplicación tras revertir conserva el origen');
registro.resumen = json(
	'select o.tipo_ficha,count(*)::integer as obras,count(*) filter(where o.editor_asignado is not null)::integer as asignadas from public.obras o group by o.tipo_ficha'
);
writeFileSync(
	join(carpeta, 'validacion-local.json'),
	JSON.stringify(registro, null, 2) + '\n',
	'utf8'
);
console.log(
	`Validación terminada: ${registro.comprobaciones.length} comprobaciones. Copia local expandida conservada.`
);
