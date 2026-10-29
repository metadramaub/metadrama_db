/** Prueba de productores y persistencia sobre una copia local; no accede a Supabase. */
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';

const [esquema, datos] = process.argv.slice(2);
if (!esquema || !datos)
	throw new Error('Uso: node scripts/probar-prosa-local.mjs <schema-public.sql> <data-public.sql>');
const contenedor = 'versologia-prosa-pruebas';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
	if (r.status !== 0)
		throw new Error((r.stderr || r.error?.message || 'Error Docker').slice(0, 1500));
	return r.stdout;
}
const config = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length
)
	throw new Error('La prueba requiere contenedor aislado, sin red ni puertos publicados');
const db = `prosa_prueba_${randomUUID().replaceAll('-', '')}`;
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
			'ON_ERROR_STOP=1',
			'-v',
			'VERBOSITY=terse'
		],
		sql
	);
psql(`create database ${db} template template0;`, 'postgres');
try {
	psql(`create schema auth; create schema extensions;
create extension "uuid-ossp" with schema extensions; create extension pgcrypto with schema extensions;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
grant usage on schema auth,extensions to anon,authenticated,service_role;
${readFileSync(esquema, 'utf8')}`);
	psql(readFileSync(datos, 'utf8'));
	psql(`create table public.prosa_control_anterior as
 select obra_id,public.analisis_obra_publico_json(obra_id)-'enunciacion'-'schema_version' as datos,
 (public.analisis_obra_publico_json(obra_id)->'enunciacion')-'prosa' as enunciacion_sin_prosa
 from public.obras_resumen where ficha is not null;`);
	function anotacionesHash() {
		return psql(`select md5(string_agg(tabla || ':' || contenido,',' order by tabla)) from (
 select t.tablename as tabla, (xpath('/row/hash/text()',query_to_xml(format(
 'select md5(string_agg(to_jsonb(t)::text,%L order by to_jsonb(t)::text)) as hash from public.%I t',
 '',t.tablename),false,true,'')))[1]::text as contenido
 from pg_tables t where t.schemaname='public' and (t.tablename like 'anotacion%'
 or t.tablename in ('obras','secuencias_metricas','secuencias_caracterizaciones_rango','jornadas','cuadros'))
) x;`).trim();
	}
	const anterior = anotacionesHash();
	psql(
		readFileSync('supabase/migrations/20261029120000_la_prosa_se_localiza_entre_versos.sql', 'utf8')
	);
	let n = 0;
	function comprobar(cond, nombre) {
		if (psql(`select (${cond});`).trim() !== 't') throw new Error(`FALLO: ${nombre}`);
		n++;
		console.log(`OK ${nombre}`);
	}
	const artefactosHash = () =>
		psql(`select md5(string_agg(clave||payload::text,',' order by clave))
 from public.artefactos_publicos where tipo in ('obra_analisis','corpus_comparativas');`).trim();
	const primeraGeneracion = artefactosHash();
	psql(
		readFileSync('supabase/migrations/20261029120000_la_prosa_se_localiza_entre_versos.sql', 'utf8')
	);
	if (artefactosHash() !== primeraGeneracion) throw new Error('La migración no es idempotente');
	n++;
	console.log('OK repetir la migración conserva los documentos de análisis');
	comprobar(
		`not exists(select 1 from public.prosa_control_anterior a where
 a.enunciacion_sin_prosa is distinct from (public.analisis_obra_publico_json(a.obra_id)->'enunciacion')-'prosa')`,
		'canto y evocación conservan los valores anteriores a la migración'
	);
	comprobar(
		`not exists(select 1 from public.prosa_control_anterior a where
 a.datos is distinct from public.analisis_obra_publico_json(a.obra_id)-'enunciacion'-'schema_version')`,
		'las demás métricas y hechos de obra se conservan'
	);
	comprobar(
		`not exists(select 1 from public.artefactos_publicos where tipo in ('obra_analisis','corpus_comparativas')
 and (version_esquema<>3 or (payload->>'schema_version')::integer<>3))`,
		'artefactos regenerados con contrato v3'
	);
	comprobar(
		`not exists(select 1 from public.artefactos_publicos where tipo='obra_analisis' and
 ((payload#>'{enunciacion,prosa}')?'versos' or (payload#>'{enunciacion,prosa}')?'proporcion_versos'))`,
		'la prosa no tiene longitud en los análisis guardados'
	);
	comprobar(
		`not exists(select 1 from public.artefactos_publicos where tipo='corpus_comparativas' and
 (payload#>'{enunciacion,prosa}')?'proporcion_versos')`,
		'el corpus no resume extensión de prosa'
	);
	comprobar(
		`not exists(select 1 from public.prosa_control_anterior a where
 (public.analisis_obra_publico_json(a.obra_id)#>'{enunciacion,cantado}') is distinct from
 (select payload#>'{enunciacion,cantado}' from public.artefactos_publicos where tipo='obra_analisis' and entidad_id=a.obra_id))`,
		'el canto leído y persistido coincide'
	);

	const id = psql(`select r.obra_id from public.obras_resumen r join public.obras o using(obra_id)
 join public.vocabularios v on v.termino_id=o.estado where v.termino='publicado' limit 1;`).trim();
	if (!id) throw new Error('La copia necesita una obra publicada para probar persistencia');
	const ficha = {
		estructura: { jornadas: [], cuadros: [] },
		metrica: {
			secuencias: [
				{
					secuencia_id: '00000000-0000-4000-8000-000000000001',
					v_ini: 1,
					v_fin: 100,
					n_versos: 100,
					forma_slug: 'redondilla',
					tipo_forma: 'forma_espanola',
					caracterizaciones_rango: [
						{ tipo_caracterizacion_rango_term: 'Prosa', v_ini: 56, v_fin: 57 },
						{ tipo_caracterizacion_rango_term: 'prosa', v_ini: 56, v_fin: 57 },
						{ tipo_caracterizacion_rango_term: 'prosa', v_ini: 57, v_fin: 58 },
						{ tipo_caracterizacion_rango_term: 'prosa', v_ini: 80, v_fin: 99 },
						{ tipo_caracterizacion_rango_term: 'cantado', v_ini: 1, v_fin: 4 },
						{ tipo_caracterizacion_rango_term: 'cantado', v_ini: 3, v_fin: 6 },
						{ tipo_caracterizacion_rango_term: 'evocacion_metrica', v_ini: 8, v_fin: 8 }
					]
				}
			]
		}
	};
	const lit = (v) => `'${String(v).replaceAll("'", "''")}'`;
	psql(`update public.obras_resumen set ficha=${lit(JSON.stringify(ficha))}::jsonb,total_versos=100 where obra_id='${id}';
 select public.recompute_artefactos_obra('${id}'); select public.recompute_artefactos_globales();`);
	const ana = `public.analisis_obra_publico_json('${id}')`;
	comprobar(
		`(${ana}#>'{enunciacion,prosa}')='{"presente":true,"formas":["redondilla"],"localizaciones":[{"v_anterior":56,"v_posterior":57},{"v_anterior":57,"v_posterior":58},{"v_anterior":80,"v_posterior":99}]}'::jsonb`,
		'prosa localizada: referencias repetidas se deduplican y las próximas no se fusionan'
	);
	comprobar(
		`(${ana}#>>'{enunciacion,cantado,versos}')::integer=6 and (${ana}#>>'{enunciacion,cantado,proporcion_versos}')::numeric=0.06`,
		'canto con solapes sigue contando seis versos de cien'
	);
	comprobar(
		`(${ana}#>>'{enunciacion,evocacion_metrica,versos}')::integer=1`,
		'evocación conserva su extensión'
	);
	comprobar(
		`(select payload#>'{enunciacion,prosa}' from public.artefactos_publicos where tipo='obra_analisis' and entidad_id='${id}')=(${ana}#>'{enunciacion,prosa}')`,
		'las localizaciones de prosa se guardan en el artefacto'
	);
	comprobar(
		`(select count(*)=2 and bool_and((payload#>>'{enunciacion,prosa,obras_con_anotacion}')::integer=(
 select count(*) from jsonb_array_elements(payload->'obras') o where o#>'{enunciacion,prosa}' is not null))
 from public.artefactos_publicos where tipo='corpus_comparativas')`,
		'ambos universos cuentan obras con prosa por presencia'
	);
	comprobar(
		`(select count(*)=2 and bool_and(not ((payload#>'{enunciacion,prosa}')?'proporcion_versos'))
 from public.artefactos_publicos where tipo='corpus_comparativas')`,
		'no reaparece un porcentaje de extensión en el corpus'
	);
	psql(`update public.obras_resumen set ficha=jsonb_set(ficha,'{metrica,secuencias,0,caracterizaciones_rango}','[]') where obra_id='${id}';
 select public.recompute_artefactos_obra('${id}');`);
	comprobar(`not (${ana}->'enunciacion'?'prosa')`, 'sin prosa no se crea un pasaje ficticio');
	if (anterior !== anotacionesHash()) throw new Error('Se han alterado anotaciones en la copia');
	n++;
	console.log('OK no se modifican obras, estructura ni anotaciones');
	const privados = psql(
		`begin; set local role anon; select count(*) from public.artefactos_publicos where tipo='corpus_comparativas'; rollback;`
	).trim();
	if (privados !== '0') throw new Error('El corpus privado se ha hecho visible');
	n++;
	console.log('OK el corpus mantiene su privacidad');
	console.log(`${n} comprobaciones PostgreSQL. Solo copia aislada; sin acceso remoto.`);
} finally {
	psql(`drop database ${db} with (force);`, 'postgres');
}
