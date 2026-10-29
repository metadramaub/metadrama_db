/** Comprobación remota de solo lectura. Guarda evidencia sin imprimir datos editoriales. */
import { readFileSync, writeFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { query } from './lib/consulta.mjs';
const args = process.argv.slice(2);
if (
	![2, 4].includes(args.length) ||
	args[0] !== '--salida' ||
	(args.length === 4 && args[2] !== '--antes')
)
	throw Error(
		'Uso: verificar-despliegue-prosa.mjs --salida <informe.json> [--antes <informe-previo.json>]'
	);
const r = query(`select jsonb_build_object(
 'migracion_aplicada',exists(select 1 from supabase_migrations.schema_migrations where version='20261029120000'),
 'importador_instalado',to_regclass('public.importaciones_metricas') is not null,
 'artefactos',(select jsonb_agg(to_jsonb(x) order by tipo,version_esquema) from (select tipo,version_esquema,count(*) cantidad from public.artefactos_publicos group by tipo,version_esquema) x),
 'analisis_con_prosa',(select count(*) from public.artefactos_publicos where tipo='obra_analisis' and payload#>'{enunciacion,prosa}' is not null),
 'prosa_con_extension',(select count(*) from public.artefactos_publicos where tipo in ('obra_analisis','corpus_comparativas') and (jsonb_path_exists(payload,'$.**.prosa.versos') or jsonb_path_exists(payload,'$.**.prosa.proporcion_versos'))),
 'contratos_invalidos',(select count(*) from public.artefactos_publicos where tipo in ('obra_analisis','corpus_comparativas') and (version_esquema<>3 or (payload->>'schema_version')::integer is distinct from 3)),
 'prosa_sin_localizacion',(select count(*) from public.artefactos_publicos where tipo='obra_analisis' and payload#>'{enunciacion,prosa}' is not null and (payload#>'{enunciacion,prosa,presente}' is distinct from 'true'::jsonb or jsonb_typeof(payload#>'{enunciacion,prosa,localizaciones}') is distinct from 'array')),
 'huella_anotaciones',(select md5(string_agg(tabla||':'||contenido,',' order by tabla)) from (
  select t.tablename tabla,(xpath('/row/hash/text()',query_to_xml(format('select md5(string_agg(to_jsonb(t)::text,%L order by to_jsonb(t)::text)) hash from public.%I t','',t.tablename),false,true,'')))[1]::text contenido
  from pg_tables t where t.schemaname='public' and (t.tablename like 'anotacion%' or t.tablename in ('obras','secuencias_metricas','secuencias_caracterizaciones_rango','secuencias_subtipos_estrofa','jornadas','cuadros'))
 ) x)
) informe;`)[0].informe;
writeFileSync(args[1], JSON.stringify(r, null, 2) + '\n');
if (args[3]) {
	const antes = JSON.parse(readFileSync(args[3], 'utf8'));
	assert.equal(r.migracion_aplicada, true, 'La migración no está registrada');
	assert.equal(r.importador_instalado, false, 'La corrección no debe instalar el importador');
	assert.equal(r.contratos_invalidos, 0, 'Quedan documentos de análisis con otro contrato');
	assert.equal(r.prosa_con_extension, 0, 'Queda prosa expresada como extensión en versos');
	assert.equal(r.prosa_sin_localizacion, 0, 'Hay prosa sin presencia/localización válida');
	assert.equal(
		r.huella_anotaciones,
		antes.huella_anotaciones,
		'Las anotaciones han cambiado: revisar si hubo edición simultánea'
	);
	console.log(
		'Verificado en Supabase: migración registrada, contrato v3, prosa sin extensión, anotaciones intactas e importador ausente.'
	);
} else console.log('Estado previo guardado; consulta de solo lectura.');
