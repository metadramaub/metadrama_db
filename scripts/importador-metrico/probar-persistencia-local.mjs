/** Pruebas PostgreSQL reales. Solo Docker aislado; no importa clientes de Supabase. */
import { spawn, spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';

const args = process.argv.slice(2);
if (args.length !== 2 || args[0] !== '--esquema')
	throw new Error(
		'Uso: node scripts/importador-metrico/probar-persistencia-local.mjs --esquema <volcado público>'
	);
const esquema = readFileSync(args[1], 'utf8');
const contenedor = 'versologia-importador-pruebas';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
	if (r.status !== 0) throw new Error(r.stderr || r.error?.message || r.stdout);
	return r.stdout;
}
const config = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length
)
	throw new Error('El contenedor debe estar aislado, sin red ni puertos publicados');
const db = `importador_prueba_${randomUUID().replaceAll('-', '')}`;
const psql = (sql, database = db) =>
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
			'postgres',
			'-d',
			database,
			'-v',
			'ON_ERROR_STOP=1'
		],
		sql
	);
function psqlConcurrente(sql) {
	return new Promise((resolve, reject) => {
		const p = spawn('docker', [
			'exec',
			'-i',
			contenedor,
			'psql',
			'-X',
			'-q',
			'-At',
			'-U',
			'postgres',
			'-d',
			db,
			'-v',
			'ON_ERROR_STOP=1'
		]);
		let out = '',
			err = '';
		p.stdout.on('data', (d) => {
			out += d;
		});
		p.stderr.on('data', (d) => {
			err += d;
		});
		p.on('error', reject);
		p.on('close', (code) => (code === 0 ? resolve(out) : reject(new Error(err))));
		p.stdin.end(sql);
	});
}
const read = (name) => readFileSync(new URL(name, import.meta.url), 'utf8');
const json = (name) => JSON.parse(read(`../../docs/importador-metrico/piloto/${name}`));
const lit = (v) => `'${String(v).replaceAll("'", "''")}'`;
const doc = (v) => `${lit(JSON.stringify(v))}::jsonb`;
const ids = Array.from(
	{ length: 7 },
	(_, i) => `00000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`
);
const autor = '00000000-0000-4000-8000-000000000100';
const refs = [
	'el-molino',
	'el-verdadero-amante',
	'los-donaires-de-matico',
	'los-locos-de-valencia'
];
let pruebas = 0;
const ok = (cond, name) => {
	pruebas++;
	return `select pg_temp.comprobar((${cond}),${lit(name)});\n`;
};
const rechaza = (sql, code, name) => {
	pruebas++;
	return `select pg_temp.rechaza(${lit(sql)},${lit(code)},${lit(name)});\n`;
};
const sesion = (i) =>
	`reset role; select set_config('request.jwt.claim.sub',${lit(ids[i])},false); set role authenticated;\n`;
const llamada = (i = 0, cambios = '', peticion = i + 1) => `select public.guardar_ficha_minima(
  '10000000-0000-4000-8000-${String(peticion).padStart(12, '0')}',${lit(autor)},
  (select datos ${cambios} from entradas where n=${i}), (select original from entradas where n=${i}))`;

psql(`create database ${db} template template0;`, 'postgres');
try {
	psql(`create schema auth; create schema extensions;
create extension "uuid-ossp" with schema extensions; create extension pgcrypto with schema extensions;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
grant usage on schema auth,extensions to anon,authenticated,service_role;
${esquema}`);
	// Ejecutar el borrador dos veces comprueba su repetibilidad, sin silenciar errores.
	const borrador = ['01-almacenamiento.sql', '02-esquema-documento.sql', '03-guardar.sql', '04-consulta.sql']
		.map((n) => read(`./sql/${n}`))
		.join('\n');
	psql(borrador);
	psql(borrador);
	let seed = `create temporary table entradas(n integer,datos jsonb,original jsonb); grant select on entradas to authenticated;
create temporary table resultados(n integer,valor jsonb); grant all on resultados to authenticated;
create function pg_temp.comprobar(p boolean,n text) returns text language plpgsql as $$
begin if p is distinct from true then raise exception 'FALLO: %',n; end if; return 'OK '||n; end; $$;
create function pg_temp.rechaza(s text,c text,n text) returns text language plpgsql as $$
begin begin execute s; exception when others then if sqlstate=c then return 'OK '||n; end if; raise; end;
raise exception 'FALLO: se aceptó %',n; end; $$;\n`;
	for (const v of json('auditoria-flujo-2026-10-26.json').vocabularios)
		seed += `insert into public.vocabularios(termino_id,categoria,termino) values(${lit(v.termino_id)},${lit(v.categoria)},${lit(v.termino)});\n`;
	for (const [i, role] of [
		'admin',
		'ip',
		'editor',
		'editor',
		'editor',
		'editor',
		'revisor'
	].entries()) {
		const rol = `20000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`;
		seed += `insert into public.vocabularios(termino_id,categoria,termino) values(${lit(rol)},'rol',${lit(role)}) on conflict (categoria,termino) do nothing;
insert into auth.users(id) values(${lit(ids[i])});
insert into public.editores(user_id,nombre_completo,email,role,activo,puede_importar_metrica)
values(${lit(ids[i])},'Persona de prueba ${i}',${lit(`prueba${i}@example.invalid`)},(select termino_id from public.vocabularios where categoria='rol' and termino=${lit(role)}),${i !== 5},${i === 2 || i === 3 || i === 5});\n`;
	}
	const nombre = json(`preparadas/${refs[0]}.json`).datos.metadatos.autor_nombre;
	seed += `insert into public.autores(autor_id,nombre_completo,slug) values(${lit(autor)},${lit(nombre)},'autor-de-prueba');\n`;
	for (const f of json('catalogo-referencia.json').formas) {
		seed += `insert into public.formas_metricas(forma_id,slug,nombre,definicion,tipo_registro)
values(${lit(f.forma_id)},${lit(f.slug)},${lit(f.nombre)},${lit(f.definicion)},${lit(f.tipo_registro)});\n`;
		for (const a of f.arquitecturas)
			seed += `insert into public.arquitecturas_forma(arquitectura_id,forma_id,slug,nombre,demarcable)
values(${lit(a.arquitectura_id)},${lit(f.forma_id)},${lit(a.slug)},${lit(a.nombre)},${f.tipo_registro !== 'sin_forma'});\n`;
	}
	for (const r of json('catalogo-referencia.json').rasgos) {
		// Solo ejercitamos referencias y contexto; la escala de recuento no interviene en estas pruebas.
		seed += `insert into public.rasgos_metricos(slug,nombre,tipo_valor,escala_recuento,naturaleza) values(${lit(r.slug)},${lit(r.nombre)},'catalogo','secuencia','construccion');\n`;
		for (const v of r.valores) seed += `insert into public.rasgo_valores(rasgo_id,slug,nombre) select rasgo_id,${lit(v.slug)},${lit(v.nombre)} from public.rasgos_metricos where slug=${lit(r.slug)};\n`;
		for (const c of r.contextos) seed += `insert into public.arquitectura_rasgos(arquitectura_id,rasgo_id,valor_id,modalidad) select a.arquitectura_id,r.rasgo_id,${c.valor_slug ? `(select valor_id from public.rasgo_valores where rasgo_id=r.rasgo_id and slug=${lit(c.valor_slug)})` : 'null'},'admitida' from public.arquitecturas_forma a join public.formas_metricas f using(forma_id) cross join public.rasgos_metricos r where f.slug=${lit(c.forma)} and a.slug=${lit(c.arquitectura)} and r.slug=${lit(r.slug)};\n`;
	}
	seed += `insert into public.estructuras_secciones(arquitectura_id,tipo_seccion,nombre,slug,orden)
select a.arquitectura_id,'remate','Remate o envío','remate',1 from public.arquitecturas_forma a
join public.formas_metricas f using(forma_id) where f.slug='cancion';\n`;
	for (const seccion of json('catalogo-referencia.json').secciones ?? []) {
		const forma = json('catalogo-referencia.json').formas.find((f) => f.slug === seccion.forma);
		const arquitectura = forma.arquitecturas.find((a) => a.slug === seccion.arquitectura);
		seed += `insert into public.estructuras_secciones(arquitectura_id,tipo_seccion,nombre,slug,orden,versos_min,versos_max)
values(${lit(arquitectura.arquitectura_id)},${lit(seccion.tipo_seccion)},${lit(seccion.seccion)},${lit(seccion.tipo_seccion)},${seccion.tipo_seccion === 'remate' ? 2 : 1},${seccion.versos_min},${seccion.versos_max});\n`;
	}
	for (const [slug, silabas] of [
		['heptasilabo', 7],
		['endecasilabo', 11],
		['octosilabo', 8]
	])
		seed += `insert into public.metros(slug,nombre,silabas) values(${lit(slug)},${lit(slug)},${silabas});\n`;
	for (const [i, ref] of refs.entries())
		seed += `insert into entradas values(${i},${doc(json(`preparadas/${ref}.json`).datos)},${doc(json(`extracciones/${ref}.json`))});\n`;
	let sql = seed + sesion(2);
	sql +=
		`reset role; insert into public.artefactos_publicos(clave,tipo,alcance,version_esquema,payload)
values('prueba/corpus','corpus_comparativas','publico',2,'{}');\n` + sesion(2);
	sql += ok('public.auth_puede_importar_metrica()', 'editor con permiso puede importar');
	sql += ok(
		'(select count(*)=0 from public.artefactos_publicos)',
		'capacidad de importar no abre el corpus del laboratorio'
	);
	for (let i = 0; i < 4; i++) sql += `insert into resultados values(${i},(${llamada(i)}));\n`;
	sql += ok(
		'(select count(*)=4 from public.importaciones_metricas)',
		'se guardan las cuatro importaciones'
	);
	sql += ok(
		"(select count(*)=4 from public.obras where tipo_ficha='minima')",
		'obras con tipo mínimo'
	);
	sql += ok('(select count(*)=12 from public.jornadas)', 'doce jornadas compartidas');
	sql += rechaza(llamada(3, "||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('titulo','Texto de fuente inventado')) ||jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{15,desviaciones,0,texto_fuente}','\"Inventado\"'))", 91), '23514', 'texto de desviación contrastado con la nota original');
	sql += ok("(select count(*)>0 from public.metrica_minima_secuencias m cross join lateral jsonb_array_elements(m.datos_minimos->'detalles_fuente') d where d->>'rasgo_slug'='distico_final' and d->>'valor_slug'='presente')", 'dístico final conservado como rasgo del catálogo');
	sql += ok("(select count(*)=2 from public.metrica_minima_secuencias m cross join lateral jsonb_array_elements(m.datos_minimos->'detalles_fuente') d where d->>'rasgo_slug'='vocales_asonancia' and ((d->>'literal'='-io' and d->>'valor_slug'='i-o') or (d->>'literal'='á-e' and d->>'valor_slug'='a-e')))", 'las dos asonancias se guardan como valores de catálogo con su notación original');
	sql += rechaza(llamada(0, "||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('titulo','Dístico incompatible')) ||jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{0,detalles_fuente}','[{\"literal\":\"pareado final\",\"rasgo_slug\":\"distico_final\",\"valor_slug\":\"presente\"}]'))", 90), '23514', 'dístico final rechazado en una forma incompatible');
	sql += ok(
		'(select count(*)=78 and sum(n_versos)=11754 from public.secuencias_metricas)',
		'78 segmentos y 11754 posiciones'
	);
	sql += ok(
		'(select count(*)=0 from public.anotaciones_metricas)',
		'no se fabrican anotaciones v2'
	);
	sql += ok(
		"(select count(*)=3 from public.metrica_minima_secuencias m join public.formas_metricas f using(forma_id) join resultados r on (r.valor->>'importacion_id')::uuid=m.importacion_id where r.n=1 and f.slug in ('cancion','terceto_encadenado') and m.arquitectura_id is null)",
		'Canción y dos pasajes de tercetos encadenados sin arquitectura'
	);
	sql += ok(
		'(select sum(s.n_versos)=11473 from public.metrica_minima_secuencias m join public.secuencias_metricas s using(secuencia_id) where m.forma_id is not null)',
		'11473 posiciones identificadas en importaciones confirmadas; 281 sin resolver'
	);
	sql += ok(
		"(select bool_and(not datos_minimos ?| array['aprobacion','propuesta','exhaustividad','fundamento','identificacion']) from public.metrica_minima_secuencias)",
		'métrica sin categorías internas ni duplicación de la identificación relacional'
	);
	sql += ok(
		"(select bool_and(i.datos_confirmados=e.datos and i.entrada_original=e.original) from public.importaciones_metricas i join resultados r on (r.valor->>'importacion_id')::uuid=i.importacion_id join entradas e using(n))",
		'original y copia confirmada conservan íntegramente sus documentos'
	);
	sql += ok(
		'(select bool_and(importado_por=auth.uid() and importado_en is not null) from public.importaciones_metricas)',
		'identidad tomada de la sesión'
	);
	sql += ok(
		`(select bool_and(o.editor_asignado is null and not o.visible_publico
 and o.fuente_fecha is not distinct from e.datos#>>'{metadatos,fuente_fecha}')
 from public.obras o join resultados r on (r.valor->>'obra_id')::uuid=o.obra_id join entradas e using(n))`,
		'sin editor ni publicación; fuente de fecha conservada'
	);
	sql += ok(`(${llamada()})->>'repetida'='true'`, 'repetir petición devuelve la misma importación');
	sql += rechaza(
		llamada(
			0,
			"||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('titulo','Otro título'))"
		),
		'23505',
		'misma petición con contenido cambiado se rechaza'
	);
	sql += rechaza(llamada(0, '', 9), '23505', 'otra petición exige revisar las coincidencias');
	sql += rechaza(
		llamada(
			1,
			"||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('titulo','Remate incorrecto')) || jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{6,detalles_fuente,0,n_versos}','4'))",
			12
		),
		'23514',
		'el remate del terceto encadenado es un verso, no cuatro'
	);
	sql += rechaza(
		llamada(
			0,
			"||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('titulo','Fallo tardío')) || jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{20,identificacion,forma_slug}','\"inexistente\"'))",
			10
		),
		'23514',
		'fallo de catálogo al final de la transacción'
	);
	sql += ok('(select count(*)=4 from public.obras)', 'el fallo tardío no deja una obra a medias');
	sql += ok(
		'(select count(*)=78 from public.metrica_minima_secuencias)',
		'el fallo tardío no deja métrica parcial'
	);
	sql += rechaza(
		llamada(0, "||jsonb_build_object('campo_inventado',true)", 11),
		'23514',
		'el contrato rechaza campos inesperados'
	);
	for (const [cambio, nombre] of [
		[
			"||jsonb_build_object('metadatos',(datos->'metadatos')||jsonb_build_object('fecha_inicio',1700,'fecha_fin',1600))",
			'fechas invertidas'
		],
		[
			"||jsonb_build_object('jornadas',jsonb_set(datos->'jornadas','{1,v_ini}','1'))",
			'jornadas solapadas'
		],
		[
			"||jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{20,origen,tramo_ref}','\"inexistente\"'))",
			'origen inexistente'
		],
		[
			"||jsonb_build_object('segmentos',jsonb_set(datos->'segmentos','{20,origen,notas_ref}','[\"inexistente\"]'))",
			'nota inexistente'
		]
	])
		sql += rechaza(
			llamada(
				0,
				`${cambio} || jsonb_build_object('metadatos',((datos ${cambio})->'metadatos')||jsonb_build_object('titulo','Prueba ${nombre}'))`,
				20 + pruebas
			),
			'23514',
			nombre
		);
	sql += rechaza(
		"select public.establecer_permiso_importacion('" + ids[4] + "',true)",
		'42501',
		'un importador no concede permisos'
	);
	sql += `with cambiadas as (update public.editores set puede_importar_metrica=true where user_id=auth.uid() returning user_id)
select pg_temp.comprobar((select count(*)=0 from cambiadas),'sin autoasignación directa de capacidad');\n`;
	pruebas++;
	sql += rechaza(
		"update public.importaciones_metricas set datos_confirmados='{}'::jsonb",
		'42501',
		'sin escritura directa en copia confirmada'
	);
	sql +=
		sesion(3) +
		ok(
			'(select count(*)=4 from public.importaciones_metricas)',
			'otro importador ve todas las importaciones'
		);
	sql += `with cambiadas as (update public.secuencias_metricas set sinopsis='No autorizado' returning secuencia_id)
select pg_temp.comprobar((select count(*)=0 from cambiadas),'consultar otra importación no permite editar sus secuencias');\n`;
	pruebas++;
	sql += ok(
		'(select count(*)=78 from public.secuencias_metricas)',
		'otro importador ve la estructura mínima'
	);
	sql +=
		sesion(4) +
		ok(
			'(select count(*)=0 from public.importaciones_metricas)',
			'editor sin capacidad no ve importaciones'
		);
	sql += ok(
		'(select count(*)=0 from public.obras)',
		'política restrictiva cierra la lectura amplia de obras mínimas'
	);
	sql += rechaza(llamada(), '42501', 'editor sin permiso no importa');
	sql +=
		sesion(5) + rechaza(llamada(), '42501', 'editor inactivo no importa aunque conserve capacidad');
	sql +=
		sesion(0) + ok('public.auth_puede_importar_metrica()', 'admin importa sin permiso individual');
	sql += `select public.establecer_permiso_importacion(${lit(ids[4])},true);\n`;
	sql +=
		sesion(4) +
		ok('public.auth_puede_importar_metrica()', 'admin concede el permiso sin cambiar el rol');
	sql +=
		sesion(1) + ok('public.auth_puede_importar_metrica()', 'IP importa sin permiso individual');
	sql += ok(
		'(select count(*)=1 from public.artefactos_publicos)',
		'IP mantiene acceso al laboratorio'
	);
	sql +=
		sesion(6) +
		ok(
			'(select count(*)=0 from public.secuencias_metricas)',
			'antiguo rol revisor no obtiene estructura mínima ajena'
		);
	sql += `reset role; update public.obras set editor_asignado=${lit(ids[6])} where obra_id=(select (valor->>'obra_id')::uuid from resultados where n=0);\n`;
	sql +=
		sesion(6) +
		ok(
			'(select count(*)=1 from public.importaciones_metricas)',
			'editor asignado consulta su propuesta sin capacidad de importar'
		);
	sql +=
		`reset role; set role anon;\n` +
		rechaza(
			'select * from public.importaciones_metricas',
			'42501',
			'anónimo no accede al registro de importación'
		);
	sql += ok('(select count(*)=0 from public.obras)', 'mínimas fuera del acceso anónimo');
	sql += `reset role;\n`;
	sql += rechaza(
		"update public.importaciones_metricas set entrada_original='{}'::jsonb",
		'23514',
		'inmutabilidad incluso frente a escritura privilegiada'
	);
	sql += rechaza(
		"update public.obras set estado=(select termino_id from public.vocabularios where categoria='estado' and termino='publicado')",
		'23514',
		'no se publica una ficha mínima'
	);
	sql += rechaza("update public.obras set tipo_ficha='completa' where tipo_ficha='minima'",'23514','no se elude la separación cambiando el tipo directamente');
	sql += `insert into public.obras(titulo,estado) values('Completa de control',(select termino_id from public.vocabularios where categoria='estado' and termino='borrador'));\n`;
	sql += ok(
		"(select tipo_ficha='completa' from public.obras where titulo='Completa de control')",
		'las obras existentes conservan el tipo completo por defecto'
	);
	sql +=
		sesion(5) +
		ok(
			'(select count(*)=1 from public.obras)',
			'el límite mínimo no cambia la política anterior para completas'
		);
	sql += `reset role;\n`;
	sql += `delete from public.secuencias_metricas where obra_id=(select (valor->>'obra_id')::uuid from resultados where n=0);
delete from public.jornadas where obra_id=(select (valor->>'obra_id')::uuid from resultados where n=0);\n`;
	sql += ok(
		"(select jsonb_array_length(datos_confirmados->'segmentos')=21 and usada_en_corpus from public.importaciones_metricas where obra_id=(select (valor->>'obra_id')::uuid from resultados where n=0))",
		'vaciar la estructura conserva la copia y su selección'
	);
	sql += ok(
		"(select bool_and(sha256_jsonb=encode(extensions.digest(convert_to(datos_confirmados::text,'UTF8'),'sha256'),'hex')) from public.importaciones_metricas)",
		'hash verificable después de guardar como JSONB'
	);
	// La identidad se resuelve expresamente: ni título/autor ni una variante son clave única.
	const tituloPiloto = lit(json(`preparadas/${refs[0]}.json`).datos.metadatos.titulo);
	sql += sesion(3);
	sql += ok(`(public.capacidades_importador_metrico()->>'guardado_disponible')::boolean`, 'sesión importadora tiene disponible el recorrido instalado');
	sql += ok(`jsonb_array_length(public.listar_fichas_basicas())=4`, 'otro importador lista las cuatro fichas y sus responsables');
	sql += ok(`(public.consultar_importacion_metrica((select (valor->>'importacion_id')::uuid from resultados where n=0))#>'{datos_confirmados}')=(select datos from entradas where n=0)`, 'consulta devuelve la copia íntegra aunque la estructura se haya vaciado');
	sql += sesion(6);
	sql += ok(`public.consultar_importacion_metrica((select (valor->>'importacion_id')::uuid from resultados where n=0)) is not null`, 'el editor asignado consulta la copia sin permiso de importar');
	sql += rechaza('select public.listar_fichas_basicas()', '42501', 'el editor asignado no obtiene por ello la lista de todas');
	sql += ok(`public.consultar_importacion_metrica((select (valor->>'importacion_id')::uuid from resultados where n=1)) is null`, 'la consulta no revela una copia ajena a un editor sin permiso');
	sql += sesion(5) + rechaza('select public.listar_fichas_basicas()', '42501', 'una sesión inactiva no lista importaciones');
	sql += sesion(2) + rechaza('select public.listar_fichas_basicas(-1)', '22023', 'se rechaza paginación inválida');
	sql += sesion(2);
	sql += `create temporary table revisadas as select array_agg(obra_id order by obra_id) ids
 from public.coincidencias_importacion_metrica(${tituloPiloto});\n`;
	sql += ok(`(select count(*)=1 from public.coincidencias_importacion_metrica(${tituloPiloto}))`, 'encuentra la básica existente por título');
	sql += `reset role; update public.obras set variantes_titulo=array[${tituloPiloto}] where titulo='Completa de control';\n` + sesion(2);
	const homonima = `select public.guardar_ficha_minima('10000000-0000-4000-8000-000000000901',${lit(autor)},
 (select datos from entradas where n=0),(select original from entradas where n=0),(select ids from revisadas))`;
	sql += rechaza(homonima, '23505', 'una coincidencia nueva exige revisar de nuevo antes de guardar');
	sql += ok(`(select count(*)=2 and bool_or(tipo_ficha='completa') from public.coincidencias_importacion_metrica(${tituloPiloto}))`, 'incluye variantes de detalladas incluso en borrador');
	sql += `update revisadas set ids=(select array_agg(obra_id order by obra_id) from public.coincidencias_importacion_metrica(${tituloPiloto}));
 insert into resultados values(90,(${homonima.replace(/^select /,'')}));\n`;
	sql += ok(`(select (valor->>'obra_id')::uuid<>(select (valor->>'obra_id')::uuid from resultados where n=0) from resultados where n=90)`, 'la decisión otra obra permite un homónimo del mismo autor');
	sql += ok(`(${homonima.replace(/^select /,'')})->>'repetida'='true'`, 'reintento del homónimo conserva la misma importación');
	sql += ok(`(select coincidencias_revisadas=(select ids from revisadas) from public.importaciones_metricas where obra_id=(select (valor->>'obra_id')::uuid from resultados where n=90))`, 'conserva una sola decisión de coincidencias por importación');
	sql += ok(`(select tipo_ficha='completa' from public.obras where titulo='Completa de control')`, 'no sobrescribe la detallada coincidente');
	sql += sesion(5) + rechaza(`select * from public.coincidencias_importacion_metrica(${tituloPiloto})`, '42501', 'la consulta de coincidencias respeta actividad y permiso');
	const salida = psql(sql);
	console.log(
		salida
			.split('\n')
			.filter((l) => l.startsWith('OK '))
			.join('\n')
	);
	const concurrente = structuredClone(json(`preparadas/${refs[0]}.json`).datos);
	concurrente.metadatos.titulo = 'Importación concurrente de prueba';
	concurrente.metadatos.fuente_fecha = null;
	concurrente.metadatos.fundamento_autoria = null;
	const pedido = () =>
		`${sesion(2)}select public.guardar_ficha_minima('10000000-0000-4000-8000-000000000999',${lit(autor)},${doc(concurrente)},${doc(json(`extracciones/${refs[0]}.json`))});`;
	const simultaneas = await Promise.all([psqlConcurrente(pedido()), psqlConcurrente(pedido())]);
	const respuestas = simultaneas.map((s) =>
		JSON.parse(s.split('\n').find((l) => l.startsWith('{')))
	);
	if (
		respuestas[0].obra_id !== respuestas[1].obra_id ||
		respuestas.filter((r) => r.repetida).length !== 1
	)
		throw new Error('La concurrencia creó resultados distintos');
	pruebas++;
	console.log('OK dos sesiones concurrentes guardan una sola obra');
	if (
		psql(`select o.fuente_fecha is null and o.editor_asignado is null and a.fuente_autoria is null
 from public.obras o join public.atribuciones a using(obra_id) where o.obra_id=${lit(respuestas[0].obra_id)};`).trim() !==
		't'
	)
		throw new Error('Se inventaron fuentes o asignaciones');
	pruebas++;
	console.log('OK fechas y fundamentos sin fuente textual admitidos');
	const simultanea=structuredClone(concurrente);
	simultanea.metadatos.titulo='Dos peticiones independientes sin revisar coincidencia';
	const intentos=await Promise.allSettled([991,992].map(n=>psqlConcurrente(`${sesion(2)}select public.guardar_ficha_minima(
 '10000000-0000-4000-8000-${String(n).padStart(12,'0')}',${lit(autor)},${doc(simultanea)},${doc(json(`extracciones/${refs[0]}.json`))});`)));
	if(intentos.filter(r=>r.status==='fulfilled').length!==1 || psql(`select count(*) from public.obras where titulo=${lit(simultanea.metadatos.titulo)};`).trim()!=='1')
		throw new Error('Dos peticiones independientes crearon una coincidencia sin revisar');
	pruebas++; console.log('OK dos peticiones distintas simultáneas no duplican sin revisión');
	console.log(
		`${pruebas} comprobaciones PostgreSQL; esquema real restaurado, datos y sesiones sintéticos. Sin acceso a Supabase.`
	);
} finally {
	psql(`drop database ${db} with (force);`, 'postgres');
}
