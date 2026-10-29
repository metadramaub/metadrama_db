/** Ensaya la candidata y su reversión sobre datos recientes. Solo Docker sin red ni puertos. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { randomUUID, createHash } from 'node:crypto';
import { resolve, join } from 'node:path';
import assert from 'node:assert/strict';
import { compilarPromocion } from './compilar-promocion.mjs';

const args = process.argv.slice(2);
if (
	![2, 3].includes(args.length) ||
	args[0] !== '--copia' ||
	(args[2] && args[2] !== '--solo-actual')
)
	throw Error('Uso: ensayar-promocion.mjs --copia backups/<copia> [--solo-actual]');
const carpeta = resolve(args[1]);
const schema = readFileSync(join(carpeta, 'schema.sql'), 'utf8');
const datos = readFileSync(join(carpeta, 'data.sql'), 'utf8');
const contexto = JSON.parse(readFileSync(join(carpeta, 'contexto.json'), 'utf8'));
const contenedor = 'versologia-importador-pruebas';
const docker = (args, input) => {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
	// pg_dump puede contener datos privados: los errores se guardan en backups, no se imprimen.
	if (r.status !== 0) {
		writeFileSync(
			join(carpeta, 'ultimo-error-local.txt'),
			r.stderr || r.error?.message || 'Error Docker'
		);
		throw Error('Falló el ensayo local; diagnóstico en ultimo-error-local.txt de la copia');
	}
	return r.stdout;
};
const config = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length
)
	throw Error('El contenedor debe estar aislado: sin red y sin puertos');
const sql = (db, s) =>
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
			db,
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
const json = (db, s) => JSON.parse(sql(db, s).trim());
const lit = (v) => "'" + String(v).replaceAll("'", "''") + "'";
const ident = (v) => '"' + v.replaceAll('"', '""') + '"';
const sha = (v) => createHash('sha256').update(v).digest('hex');
const candidata = compilarPromocion();
const prosa = readFileSync(
	new URL(
		'../../supabase/migrations/20261029120000_la_prosa_se_localiza_entre_versos.sql',
		import.meta.url
	),
	'utf8'
);
const resultados = [];
function catalogo(db) {
	return json(
		db,
		`select jsonb_build_object(
 'funciones',(select jsonb_agg(jsonb_build_object('firma',format('%I.%I(%s)',n.nspname,p.proname,oidvectortypes(p.proargtypes)),'hash',md5(pg_get_functiondef(p.oid)),'ddl',pg_get_functiondef(p.oid),'acl',p.proacl,'owner',p.proowner) order by p.oid::regprocedure::text) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f'),
 'politicas',(select jsonb_agg(jsonb_build_object('tabla',tablename,'nombre',policyname,'modo',permissive,'roles',roles,'operacion',cmd,'using',qual,'check',with_check) order by tablename,policyname) from pg_policies where schemaname='public'),
 'triggers',(select jsonb_agg(jsonb_build_object('tabla',c.relname,'nombre',t.tgname,'ddl',pg_get_triggerdef(t.oid,true)) order by c.relname,t.tgname) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal),
 'columnas',(select jsonb_agg(jsonb_build_object('tabla',c.relname,'columna',a.attname,'tipo',format_type(a.atttypid,a.atttypmod),'notnull',a.attnotnull,'default',pg_get_expr(d.adbin,d.adrelid)) order by c.relname,a.attnum) from pg_attribute a join pg_class c on c.oid=a.attrelid join pg_namespace n on n.oid=c.relnamespace left join pg_attrdef d on d.adrelid=a.attrelid and d.adnum=a.attnum where n.nspname='public' and c.relkind in ('r','p') and a.attnum>0 and not a.attisdropped),
 'seguridad',(select jsonb_agg(jsonb_build_object('tabla',c.relname,'acl',c.relacl,'rls',c.relrowsecurity,'forzar_rls',c.relforcerowsecurity) order by c.relname) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p')),
 'indices',(select jsonb_agg(indexdef order by indexname) from pg_indexes where schemaname='public'),
 'restricciones',(select jsonb_agg(jsonb_build_object('tabla',t.relname,'nombre',c.conname,'ddl',pg_get_constraintdef(c.oid)) order by t.relname,c.conname) from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace where n.nspname='public'),
 'tablas',(select jsonb_agg(tablename order by tablename) from pg_tables where schemaname='public'),
 'jsonschema',exists(select 1 from pg_extension where extname='pg_jsonschema'));`
	);
}
function huellas(db, tablas) {
	const consultas = tablas.map((t) => {
		const fila = `to_jsonb(t)${t === 'obras' ? "-'tipo_ficha'" : t === 'editores' ? "-'puede_importar_metrica'" : ''}`;
		return `select ${lit(t)} tabla,count(*) filas,md5(coalesce(string_agg((${fila})::text,E'\\n' order by (${fila})::text),'')) huella from public.${ident(t)} t`;
	});
	return json(
		db,
		`set timezone='UTC'; select jsonb_agg(to_jsonb(x) order by tabla) from (${consultas.join(' union all ')}) x;`
	);
}
function salidas(db, recalcular = false) {
	return json(
		db,
		`${recalcular ? 'begin; select public.recompute_all();' : ''} select jsonb_build_object(
 'formas',md5(coalesce((select jsonb_agg(to_jsonb(f) order by o.obra_id,f.secuencia_id)::text from public.obras o cross join lateral public.formas_de_la_obra(o.obra_id) f),'')),
 'unidades',md5(coalesce((select jsonb_agg(to_jsonb(u) order by u.autor_id,u.obra_id,u.jornada_id)::text from public.perfil_metrico_unidades() u),'')),
 'analisis',md5(coalesce((select jsonb_agg(public.analisis_obra_publico_json(o.obra_id) order by o.obra_id)::text from public.obras o),'')),
 'fichas',md5(coalesce((select jsonb_agg(public.ficha_publica_base_json(o.obra_id,true) order by o.obra_id)::text from public.obras o),''))); ${recalcular ? 'rollback;' : ''}`
	);
}
function comprobarClavesForaneas(db) {
	const claves = json(
		db,
		`select jsonb_agg(jsonb_build_object('nombre',c.conname,'tabla',format('%I.%I',n.nspname,t.relname),'destino',format('%I.%I',rn.nspname,rt.relname),
 'hijas',(select jsonb_agg(a.attname order by k.ord) from unnest(c.conkey) with ordinality k(num,ord) join pg_attribute a on a.attrelid=c.conrelid and a.attnum=k.num),
 'padres',(select jsonb_agg(a.attname order by k.ord) from unnest(c.confkey) with ordinality k(num,ord) join pg_attribute a on a.attrelid=c.confrelid and a.attnum=k.num)))
 from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace
 join pg_class rt on rt.oid=c.confrelid join pg_namespace rn on rn.oid=rt.relnamespace where c.contype='f' and n.nspname='public';`
	);
	const pruebas = claves.map(
		(c) =>
			`select ${lit(c.nombre)} nombre,count(*) errores from ${c.tabla} h where ${c.hijas.map((a) => `h.${ident(a)} is not null`).join(' and ')} and not exists(select 1 from ${c.destino} p where ${c.hijas.map((a, i) => `p.${ident(c.padres[i])}=h.${ident(a)}`).join(' and ')})`
	);
	const resultado = json(
		db,
		`select coalesce(jsonb_agg(to_jsonb(c)) filter(where errores>0),'[]'::jsonb) from (${pruebas.join(' union all ')}) c;`
	);
	assert.deepEqual(resultado, [], 'La copia contiene referencias rotas; no usarla como evidencia');
	return claves.length;
}
function reversion(antes, despues) {
	const prev = new Map(antes.funciones.map((f) => [f.firma, f]));
	const nuevas = despues.funciones.filter((f) => !prev.has(f.firma));
	const cambiadas = despues.funciones.filter(
		(f) => prev.has(f.firma) && prev.get(f.firma).hash !== f.hash
	);
	const diferencia = (campo) =>
		despues[campo].filter(
			(x) => !antes[campo].some((y) => JSON.stringify(x) === JSON.stringify(y))
		);
	let s = `-- RECUPERACIÓN LOCAL GENERADA PARA ESTA COPIA. Revisar antes de usar en Supabase.\n-- Solo antes de la primera importación. Sin CASCADE y sin borrar datos editoriales.\nbegin;\nset local lock_timeout='5s';\nset local statement_timeout='120s';\ndo $verificar$\nbegin\n if to_regclass('public.importaciones_metricas') is not null then\n  lock table public.importaciones_metricas in access exclusive mode;\n  if exists(select 1 from public.importaciones_metricas) then raise exception 'Hay importaciones: no deshacer el esquema; pausar y corregir hacia delante'; end if;\n end if;\n if exists(select 1 from information_schema.columns where table_schema='public' and table_name='obras' and column_name='tipo_ficha') then\n  if exists(select 1 from public.obras where tipo_ficha='minima') then raise exception 'Hay fichas básicas: no deshacer el esquema'; end if;\n end if;\n`;
	for (const f of cambiadas)
		s += ` if md5(pg_get_functiondef(${lit(f.firma)}::regprocedure)) not in (${lit(f.hash)},${lit(prev.get(f.firma).hash)}) then raise exception 'Ha cambiado una función después del ensayo: abortar recuperación'; end if;\n`;
	s += 'end;\n$verificar$;\n';
	for (const p of diferencia('politicas'))
		s += `drop policy if exists ${ident(p.nombre)} on public.${ident(p.tabla)};\n`;
	for (const t of diferencia('triggers'))
		s += `drop trigger if exists ${ident(t.nombre)} on public.${ident(t.tabla)};\n`;
	for (const f of cambiadas) s += prev.get(f.firma).ddl + ';\n';
	for (const f of nuevas) s += `drop function if exists ${f.firma};\n`;
	for (const t of diferencia('tablas').sort((a, b) => b.localeCompare(a)))
		s += `drop table if exists public.${ident(t)};\n`;
	s += `alter table public.obras drop column if exists tipo_ficha;\nalter table public.editores drop column if exists puede_importar_metrica;\n`;
	if (!antes.jsonschema) s += 'drop extension if exists pg_jsonschema;\n';
	return s + `notify pgrst,'reload schema';\ncommit;\n`;
}
mkdirSync(carpeta, { recursive: true });
for (const conProsa of args[2] ? [false] : [false, true]) {
	const db = 'importador_promocion_' + randomUUID().replaceAll('-', '');
	const nombre = conProsa ? 'prosa-primero' : 'esquema-actual';
	let creada = false;
	try {
		sql('postgres', `create database ${db} template template0;`);
		creada = true;
		sql(
			db,
			`create schema auth; create schema extensions; create extension "uuid-ossp" with schema extensions; create extension pgcrypto with schema extensions;
   create table auth.users(id uuid primary key); create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid; $$;
   grant usage on schema auth,extensions to anon,authenticated,service_role;
   ${schema}`
		);
		sql(
			db,
			`insert into auth.users(id) values ${contexto.auth_ids.map((id) => `(${lit(id)})`).join(',')};`
		);
		sql(db, datos);
		const clavesVerificadas = comprobarClavesForaneas(db);
		if (conProsa) sql(db, prosa);
		const antes = catalogo(db);
		const datosAntes = huellas(db, antes.tablas);
		const salidaAntes = salidas(db);
		const recalculadaAntes = salidas(db, true);
		// Un error al final no debe dejar ni la extensión, ni las columnas, ni cambios de funciones.
		const fallo = candidata.replace(
			/commit;\s*$/,
			"do $$ begin raise exception 'fallo deliberado del ensayo'; end; $$;\ncommit;\n"
		);
		assert.throws(() => sql(db, fallo));
		assert.ok(
			readFileSync(join(carpeta, 'ultimo-error-local.txt'), 'utf8').includes(
				'fallo deliberado del ensayo'
			)
		);
		assert.deepEqual(catalogo(db), antes, 'Un fallo dejó cambios parciales de esquema');
		assert.deepEqual(huellas(db, antes.tablas), datosAntes, 'Un fallo modificó datos');
		sql(db, candidata);
		const despues = catalogo(db);
		assert.deepEqual(
			huellas(db, antes.tablas),
			datosAntes,
			'La migración alteró datos editoriales o artefactos'
		);
		assert.deepEqual(salidas(db), salidaAntes, 'La migración cambió salidas detalladas');
		assert.deepEqual(
			salidas(db, true),
			recalculadaAntes,
			'El recálculo detallado cambió por la candidata'
		);
		assert.deepEqual(
			huellas(db, antes.tablas),
			datosAntes,
			'El ensayo de recálculo debe revertir sus escrituras'
		);
		assert.equal(sql(db, 'select count(*) from public.importaciones_metricas;').trim(), '0');
		assert.equal(sql(db, "select bool_and(tipo_ficha='completa') from public.obras;").trim(), 't');
		assert.equal(
			sql(db, 'select bool_and(not puede_importar_metrica) from public.editores;').trim(),
			't'
		);
		sql(db, candidata);
		assert.deepEqual(catalogo(db), despues, 'Repetir candidata alteró el esquema');
		const comprobarPausa = () =>
			json(
				db,
				"select to_jsonb(has_function_privilege('authenticated','public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])','execute'));"
			);
		assert.equal(comprobarPausa(), true);
		sql(db, readFileSync(new URL('./promocion/pausar-guardado.sql', import.meta.url), 'utf8'));
		assert.equal(comprobarPausa(), false);
		assert.deepEqual(
			huellas(db, antes.tablas),
			datosAntes,
			'Pausar no debe borrar ni alterar datos'
		);
		sql(db, readFileSync(new URL('./promocion/reanudar-guardado.sql', import.meta.url), 'utf8'));
		assert.equal(comprobarPausa(), true);
		const revertir = reversion(antes, despues);
		writeFileSync(join(carpeta, `recuperar-${nombre}.sql`), revertir);
		// No se permite una reversión destructiva después de empezar a importar.
		// La comprobación de ese bloqueo se hace con una tabla sintética dentro de una transacción.
		const guardia = revertir.slice(
			0,
			revertir.indexOf('end;\n$verificar$;') + 'end;\n$verificar$;'.length
		);
		const insertFake = `begin;
   insert into public.importaciones_metricas(importacion_id,obra_id,peticion_id,importado_por,autor_id,genero_id,entrada_original,datos_confirmados,sha256_jsonb)
   select gen_random_uuid(),o.obra_id,gen_random_uuid(),e.user_id,a.autor_id,v.termino_id,'{}','{"esquema":"versologia-ficha-minima/0.2"}',repeat('0',64) from public.obras o cross join public.editores e cross join public.autores a cross join public.vocabularios v limit 1;
   ${guardia.replace(/^begin;$/m, '')} rollback;`;
		assert.throws(() => sql(db, insertFake));
		assert.ok(
			readFileSync(join(carpeta, 'ultimo-error-local.txt'), 'utf8').includes(
				'Hay importaciones: no deshacer el esquema'
			)
		);
		sql(db, revertir);
		assert.deepEqual(
			catalogo(db),
			antes,
			'La recuperación no restauró las definiciones anteriores'
		);
		assert.deepEqual(
			huellas(db, antes.tablas),
			datosAntes,
			'La recuperación alteró anotaciones o artefactos'
		);
		assert.deepEqual(salidas(db), salidaAntes, 'La recuperación alteró las salidas detalladas');
		resultados.push({
			caso: nombre,
			tablasOriginales: antes.tablas.length,
			clavesForaneasVerificadas: clavesVerificadas,
			obras: datosAntes.find((t) => t.tabla === 'obras')?.filas,
			datosSinCambios: true,
			salidasSinCambios: true,
			falloAtomico: true,
			repetible: true,
			reversionVerificada: true,
			pausaVerificada: true,
			recalculoComparado: true,
			funcionesModificadas: despues.funciones
				.filter((f) => antes.funciones.some((a) => a.firma === f.firma && a.hash !== f.hash))
				.map((f) => f.firma),
			sha256Recuperacion: sha(revertir),
			tablas: datosAntes.map(({ tabla, filas }) => ({ tabla, filas })),
			salidas: salidaAntes
		});
		console.log(`OK ${nombre}: datos, salidas, atomicidad, repetición y recuperación.`);
	} finally {
		if (creada) sql('postgres', `drop database ${db} with (force);`);
	}
}
const informe = {
	fecha: '2026-10-29',
	soloLocal: true,
	sha256Esquema: sha(schema),
	sha256Datos: sha(datos),
	sha256Candidata: sha(candidata),
	sha256Prosa: sha(prosa),
	resultados
};
writeFileSync(join(carpeta, 'resultado-promocion.json'), JSON.stringify(informe, null, 2));
console.log('Informe y dos recuperaciones en la carpeta de copia. No se ha conectado a Supabase.');
