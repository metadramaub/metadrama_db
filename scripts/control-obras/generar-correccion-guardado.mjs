/** Genera un parche revisable desde las definiciones conservadas de producción. No lo aplica. */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
const funciones = JSON.parse(readFileSync('backups/incidencia-prado-20261110/funciones-a-corregir-live.json','utf8'));
let guardar = funciones.find(f=>f.proname==='guardar_anotacion_metrica').definicion;
const comienzo = "\t\tfor v_item in\n\t\t\tselect value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))\n\t\tloop";
const fin = guardar.indexOf('\n\t\tend loop;',guardar.indexOf(comienzo));
if(!guardar.includes(comienzo)||fin<0) throw Error('No se reconoce el bloque de respuestas');
let bloque=guardar.slice(guardar.indexOf(comienzo)+comienzo.length,fin);
bloque=bloque.replace(/\bv_item\b/g,'item.dato');
bloque=bloque.replace('\n\t\t\tinsert into public.anotacion_elecciones (', `
            -- Se deriva el repertorio una vez para toda la petición, conservando los triggers por fila.
            with opciones as materialized (select * from public.opciones_eleccion_metrica)
            insert into public.anotacion_elecciones (`);
bloque=bloque.replace("from (select nullif(item.dato ->> 'opcion_eleccion_id', '')::uuid as elegida) k\n\t\t\tleft join public.opciones_eleccion_metrica o\n\t\t\t\ton o.opcion_eleccion_id = k.elegida", `from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb)) item(dato)
            left join opciones o on o.opcion_eleccion_id = nullif(item.dato ->> 'opcion_eleccion_id', '')::uuid`);
if(bloque.includes('k.elegida')||!bloque.includes('with opciones as materialized')) throw Error('No se reconoce la consulta de opciones');
guardar=guardar.slice(0,guardar.indexOf(comienzo))+bloque+guardar.slice(fin+'\n\t\tend loop;'.length);
const joinAnterior=`select grupo.*, unidad.realizacion_id
\t\t\tfrom public.anotacion_realizaciones unidad
\t\t\tjoin public.grupos_eleccion_metrica_resueltos grupo`;
const joinNuevo=`with grupos as materialized (
                select * from public.grupos_eleccion_metrica_resueltos
                where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
                    and activo and alcance = 'unidad'
            )
            select grupo.*, unidad.realizacion_id
\t\t\tfrom public.anotacion_realizaciones unidad
\t\t\tjoin grupos grupo`;
if(!guardar.includes(joinAnterior)) throw Error('No se reconoce la validación por unidad');
guardar=guardar.replace(joinAnterior,joinNuevo);
writeFileSync('backups/incidencia-prado-20261110/guardar-optimizado.sql',guardar.trim()+';\n','utf8');
let derivar=funciones.find(f=>f.proname==='opciones_eleccion_derivadas').definicion;
// Un SET propio impide que PostgreSQL integre la función SQL en la consulta y empuje filtros.
// Todas las tablas ya están cualificadas. También se fijan las funciones antes de retirar SET.
derivar=derivar.replace(" SET search_path TO 'public'\n",'\n');
for(const nombre of ['concat_ws','row_number','generate_series','sum','count'])
 derivar=derivar.replace(new RegExp(`(?<![\\w.])${nombre}\\(`,'g'),`pg_catalog.${nombre}(`);
const disparadores=['validar_estructura_anotacion_diferida','validar_extension_patron_anotacion_realizaciones','validar_arquitectura_de_realizacion','validar_densidad_de_pareados_regulares'];
let estructura=funciones.find(f=>f.proname==='validar_estructura_anotacion').definicion;
const raices="\t\t\t\tand seccion_id is null\n";
if(!estructura.includes(raices)) throw Error('No se reconoce el recorrido de unidades');
estructura=estructura.replace(raices,raices+`                -- Sin secciones raíz no hay nada que comprobar dentro de esta unidad.
                -- Filtrarlo aquí evita un bucle SQL vacío por cada estrofa y evento diferido.
                and exists (
                    select 1 from public.estructuras_secciones raiz
                    where raiz.arquitectura_id = coalesce(anotacion_realizaciones.arquitectura_id, v_configuracion_id)
                        and raiz.seccion_padre_id is null
                )
`);
const migracion=`-- Corrige el coste del guardado métrico sin cambiar el catálogo ni los datos anotados.
-- No modifica el nuevo modelo de control de obras. Ensayar sobre copia antes de desplegar.
begin;
set local lock_timeout='5s';
set local statement_timeout='120s';
create temporary table _opciones_antes_guardado on commit drop as
select * from public.opciones_eleccion_metrica;

-- Se permite integrar la derivación en los planes; las referencias quedan cualificadas.
${derivar.trim()};

-- Estas funciones solo se ejecutan como triggers y solo comprueban integridad.
-- Las autorizaciones de escritura siguen en RLS y en la RPC. Las comprobaciones ven toda
-- la anotación sin volver a resolver sus permisos para cada fila en cada evento diferido.
${disparadores.map(n=>`alter function public.${n}() security definer;\nalter function public.${n}() set search_path to '';`).join('\n')}

${estructura.trim()};

${guardar.trim()};

do $guarda$
declare
 v_admin uuid;
 v_escenario uuid;
 v_anotacion uuid;
 v_unidad uuid := gen_random_uuid();
 v_forma uuid;
 v_arquitectura uuid;
 v_opcion uuid;
 v_sub text := current_setting('request.jwt.claim.sub',true);
 v_claims text := current_setting('request.jwt.claims',true);
begin
 if exists ((select * from _opciones_antes_guardado except all select * from public.opciones_eleccion_metrica)
  union all (select * from public.opciones_eleccion_metrica except all select * from _opciones_antes_guardado)) then
  raise exception 'La optimización ha cambiado las opciones del catálogo';
 end if;
 select e.user_id into v_admin from public.editores e join public.vocabularios v on v.termino_id=e.role
 where coalesce(e.activo,true) and lower(v.termino) in ('admin','ip') order by e.created_at limit 1;
 select a.forma_id,a.arquitectura_id,o.opcion_eleccion_id into v_forma,v_arquitectura,v_opcion
 from public.formas_metricas f join public.arquitecturas_forma a using(forma_id)
 join public.preguntas_metricas g using(arquitectura_id)
 join public.opciones_eleccion_metrica o using(grupo_eleccion_id)
 join public.esquemas_rima r using(esquema_rima_id)
 where f.slug='redondilla' and a.activo and r.notacion='abba' limit 1;
 if v_admin is null or v_opcion is null then raise exception 'Faltan identidad o catálogo para ejecutar la guarda'; end if;
 perform set_config('request.jwt.claim.sub',v_admin::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
 begin
  insert into public.anotacion_escenarios_prueba(nombre,created_by,updated_by)
  values ('Guarda transitoria de rendimiento',v_admin,v_admin) returning escenario_id into v_escenario;
  v_anotacion:=public.guardar_anotacion_metrica(jsonb_build_object('escenario_id',v_escenario,
   'forma_id',v_forma,'arquitectura_id',v_arquitectura,'orden',1,'v_ini',1,'v_fin',4,
   'unidades',jsonb_build_array(jsonb_build_object('realizacion_id',v_unidad,'orden',1,'v_ini',1,'v_fin',4)),
   'elecciones',jsonb_build_array(jsonb_build_object('realizacion_id',v_unidad,'dimension','rima','opcion_eleccion_id',v_opcion))));
  set constraints all immediate;
  if not exists(select 1 from public.anotacion_elecciones where anotacion_id=v_anotacion and realizacion_id=v_unidad) then
   raise exception 'La guarda no ha conservado la respuesta';
  end if;
  raise exception using errcode='ZX001',message='Deshacer solamente los datos de la guarda';
 exception when sqlstate 'ZX001' then null;
 end;
 perform set_config('request.jwt.claim.sub',coalesce(v_sub,''),true);
 perform set_config('request.jwt.claims',coalesce(v_claims,''),true);
end $guarda$;
-- Las pruebas ejecutables de guardado y permisos acompañan esta migración en
-- scripts/control-obras/probar-guardado-prado-local.mjs; la guarda no deja datos de prueba.
commit;
`;
const salida='supabase/migrations/20261110130000_el_guardado_metrico_no_recalcula_el_catalogo_por_respuesta.sql';
// Ya aplicada: conservarla inmutable. Una revisión exige otra migración.
if(existsSync(salida)) {
 if(readFileSync(salida,'utf8')!==migracion) throw Error('No se sobrescribe una migración existente; crear otra para cualquier cambio');
 console.log('Migración existente idéntica; se conserva sin escribirla.');
} else {
 writeFileSync(salida,migracion,'utf8');
 console.log('Generada corrección candidata; falta validarla.');
}
