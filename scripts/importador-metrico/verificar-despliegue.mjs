/** Auditoría remota de SELECT: conserva huellas, no contenidos de las fichas. */
import { readFileSync, writeFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { query } from '../lib/consulta.mjs';
const args = process.argv.slice(2);
if (![2, 4].includes(args.length) || args[0] !== '--salida' || (args[3] && args[2] !== '--antes'))
	throw Error(
		'Uso: verificar-despliegue.mjs --salida <informe.json> [--antes <informe-previo.json>]'
	);
const r = query(`select jsonb_build_object(
 'migracion_aplicada',exists(select 1 from supabase_migrations.schema_migrations where version='20261029180000'),
 'prosa_aplicada',exists(select 1 from supabase_migrations.schema_migrations where version='20261029120000'),
 'basicas',(select count(*) from public.obras o where to_jsonb(o)->>'tipo_ficha'='minima'),
 'detalladas',(select count(*) from public.obras o where coalesce(to_jsonb(o)->>'tipo_ficha','completa')='completa'),
 'basicas_publicas',(select count(*) from public.obras o join public.vocabularios v on v.termino_id=o.estado where to_jsonb(o)->>'tipo_ficha'='minima' and (o.visible_publico or v.termino<>'borrador')),
 'basicas_precomputadas',(select count(*) from public.obras_resumen r join public.obras o using(obra_id) where to_jsonb(o)->>'tipo_ficha'='minima'),
 'basicas_en_perfiles',(select count(*) from public.perfil_metrico_unidades() u join public.obras o using(obra_id) where to_jsonb(o)->>'tipo_ficha'='minima'),
 'politicas_restrictivas',(select count(*) from pg_policies where schemaname='public' and permissive='RESTRICTIVE' and (policyname like '%_basicas_%' or policyname in ('obras_minimas_limite_consulta','obras_minimas_no_anon','jornadas_minimas_limite','secuencias_minimas_limite'))),
 'anon_puede_guardar',case when to_regprocedure('public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])') is null then false else has_function_privilege('anon','public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])','execute') end,
 'auth_puede_invocar_guardado',case when to_regprocedure('public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])') is null then false else has_function_privilege('authenticated','public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[])','execute') end,
 'anon_puede_leer_copias',case when to_regclass('public.importaciones_metricas') is null then false else has_table_privilege('anon','public.importaciones_metricas','select') end,
 'artefactos',(select jsonb_object_agg(clave,md5(payload::text)) from public.artefactos_publicos),
 'contratos_invalidos',(select count(*) from public.artefactos_publicos where tipo in ('obra_analisis','corpus_comparativas') and (version_esquema<>3 or (payload->>'schema_version')::integer is distinct from 3)),
 'fuentes',(select jsonb_agg(jsonb_build_object('tabla',t.tablename,'huellas',((xpath('/row/huellas/text()',query_to_xml(format(
  'select coalesce(jsonb_object_agg(h,n),%L::jsonb)::text huellas from (select md5((to_jsonb(s)-array[%L,%L])::text) h,count(*) n from public.%I s group by 1) x',
  '{}',case when t.tablename='obras' then 'tipo_ficha' else '__sin_columna__' end,case when t.tablename='editores' then 'puede_importar_metrica' else '__sin_columna__' end,t.tablename),false,true,'')))[1]::text)::jsonb) order by t.tablename)
 from pg_tables t where t.schemaname='public' and t.tablename not in ('obras_resumen','autores_resumen','artefactos_publicos','proyecto_activo','dashboard_activity_state'))
) informe;`)[0].informe;
writeFileSync(args[1], JSON.stringify(r, null, 2) + '\n');
if (args[3]) {
	const antes = JSON.parse(readFileSync(args[3], 'utf8'));
	assert.equal(r.migracion_aplicada, true, 'Migración no registrada');
	assert.equal(r.prosa_aplicada, true, 'No se conserva la corrección de prosa');
	assert.equal(r.basicas_publicas, 0, 'Una básica tiene estado/visibilidad inválidos');
	assert.equal(r.basicas_precomputadas, 0, 'El productor detallado ha generado una básica');
	assert.equal(r.basicas_en_perfiles, 0, 'El lector detallado está incluyendo básicas');
	assert.equal(r.contratos_invalidos, 0, 'Cambió el contrato de los precomputados publicados');
	assert.equal(r.politicas_restrictivas, 16, 'Faltan límites restrictivos de acceso/escritura');
	assert.equal(r.anon_puede_guardar, false);
	assert.equal(r.anon_puede_leer_copias, false);
	assert.equal(r.auth_puede_invocar_guardado, true);
	const actuales = new Map(r.fuentes.map((t) => [t.tabla, t.huellas]));
	for (const t of antes.fuentes)
		for (const [hash, n] of Object.entries(t.huellas))
			assert.ok(
				(actuales.get(t.tabla)?.[hash] ?? 0) >= n,
				`Cambió una fila previa de ${t.tabla}: revisar edición simultánea`
			);
	assert.deepEqual(
		r.artefactos,
		antes.artefactos,
		'Los artefactos detallados han cambiado: revisar su causa'
	);
	console.log(
		'Verificado: esquema/permisos, filas previas intactas y artefactos detallados conservados. Básicas privadas y fuera de precomputados.'
	);
} else console.log('Estado previo y huellas de filas guardados; solo SELECT.');
