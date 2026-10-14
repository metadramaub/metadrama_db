-- El villancico admite los metros de arte menor ya catalogados (3–8 sílabas).
-- Decisión del IP, 14 de octubre de 2026: una medida por parte, en la arquitectura
-- activa. No se añade bisílabo, no se reactiva la arquitectura retirada y no se cambia
-- la prosa. Las respuestas antiguas siguen siendo válidas; el editor corregirá las de
-- Adonis y Venus, vv. 852–871, sin que esta migración anticipe su lectura.

begin;

create temporary table villancico_registro_previo on commit drop as
select am.anotacion_id, to_jsonb(am) as anotacion,
 coalesce((select jsonb_agg(to_jsonb(e) order by e.eleccion_id)
  from public.anotacion_elecciones e where e.anotacion_id = am.anotacion_id), '[]'::jsonb) as respuestas
from public.anotaciones_metricas am join public.formas_metricas f using (forma_id)
where f.slug = 'villancico';

create temporary table villancico_opciones_previas on commit drop as
select o.opcion_eleccion_id from public.opciones_eleccion_metrica o
join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
join public.arquitecturas_forma a using (arquitectura_id)
join public.formas_metricas f using (forma_id)
where f.slug = 'villancico' and a.activo;

create temporary table villancico_prosa_previa on commit drop as
select 'forma' as entidad, f.forma_id as id, f.definicion as texto
from public.formas_metricas f where f.slug = 'villancico'
union all
select 'arquitectura', a.arquitectura_id, a.descripcion
from public.arquitecturas_forma a join public.formas_metricas f using (forma_id) where f.slug = 'villancico'
union all
select 'esquema', em.esquema_metrico_id, em.descripcion
from public.esquemas_metricos em join public.arquitecturas_forma a using (arquitectura_id)
join public.formas_metricas f using (forma_id) where f.slug = 'villancico'
union all
select 'pregunta', g.grupo_eleccion_id, g.ayuda_editor
from public.grupos_eleccion_metrica g join public.arquitecturas_forma a using (arquitectura_id)
join public.formas_metricas f using (forma_id) where f.slug = 'villancico'
union all
select 'afirmacion', af.afirmacion_id, af.resumen
from public.afirmaciones_fuentes_metricas af join public.formas_metricas f using (forma_id) where f.slug = 'villancico';

create temporary table villancico_retirado_previo on commit drop as
select em.esquema_metrico_id, to_jsonb(em) as esquema,
 coalesce((select jsonb_agg(to_jsonb(eo) order by eo.metro_id)
  from public.esquema_metrico_opciones eo where eo.esquema_metrico_id = em.esquema_metrico_id), '[]'::jsonb) as opciones
from public.esquemas_metricos em join public.arquitecturas_forma a using (arquitectura_id)
join public.formas_metricas f using (forma_id) where f.slug = 'villancico' and not a.activo;

do $repertorio$
declare
 v_arq uuid;
 v_esquema uuid;
 v_n integer;
begin
 select count(*) into v_n from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
 where f.slug = 'villancico' and a.activo;
 if v_n <> 1 then raise exception 'El villancico tiene % arquitecturas activas; hay que revisarlas.', v_n; end if;
 select a.arquitectura_id into strict v_arq from public.arquitecturas_forma a
 join public.formas_metricas f using (forma_id) where f.slug = 'villancico' and a.activo and a.slug = 'estribillo_inicial';
 select esquema_metrico_id into strict v_esquema from public.esquemas_metricos
 where arquitectura_id = v_arq and slug in ('conjunto-6-8', 'arte-menor')
  and tipo_secuencia = 'conjunto' and medida_uniforme;

 select count(*) into v_n from public.grupos_eleccion_metrica
 where arquitectura_id = v_arq and dimension = 'metro' and activo
  and slug in ('medida_cabeza', 'medida_mudanza', 'medida_enlace', 'medida_vuelta')
  and alcance = 'unidad' and selecciones_min = 1 and selecciones_max = 1;
 if v_n <> 4 then raise exception 'No están las cuatro preguntas de una sola medida por parte.'; end if;
 select count(*) into v_n from public.metros where activo and arte = 'menor' and silabas between 3 and 8;
 if v_n <> 6 then raise exception 'No están los seis metros de arte menor aprobados.'; end if;
 if exists (select 1 from public.esquema_metrico_opciones eo join public.metros m using (metro_id)
  where eo.esquema_metrico_id = v_esquema and (m.arte <> 'menor' or m.silabas not between 3 and 8 or eo.rol is not null)) then
  raise exception 'El esquema del villancico contiene alternativas ajenas al repertorio revisado.';
 end if;

 insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
 select v_esquema, m.metro_id, m.silabas from public.metros m
 where m.activo and m.arte = 'menor' and m.silabas between 3 and 8
  and not exists (select 1 from public.esquema_metrico_opciones eo
   where eo.esquema_metrico_id = v_esquema and eo.metro_id = m.metro_id);
 update public.esquema_metrico_opciones eo set orden = m.silabas
 from public.metros m where eo.metro_id = m.metro_id and eo.esquema_metrico_id = v_esquema
  and eo.orden is distinct from m.silabas;
 update public.esquemas_metricos set slug = 'arte-menor'
 where esquema_metrico_id = v_esquema and slug <> 'arte-menor';
end;
$repertorio$;

do $guardas$
declare
 v_arq uuid;
 v_forma uuid;
 v_admin uuid;
 v_escenario uuid;
 v_anotacion uuid;
 v_raiz uuid;
 v_cabeza uuid;
 v_ciclo uuid;
 v_copla uuid;
 v_mudanza uuid;
 v_enlace uuid;
 v_vuelta uuid;
 v_represa uuid;
 v_secciones jsonb;
 v_unidades jsonb;
 v_elecciones jsonb;
 v_payload jsonb;
 v_metro record;
 v_n integer;
begin
 select a.arquitectura_id, a.forma_id into strict v_arq, v_forma
 from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
 where f.slug = 'villancico' and a.slug = 'estribillo_inicial' and a.activo;
 select count(*) into v_n from public.opciones_eleccion_metrica o
 join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
 join public.metros m on m.metro_id = o.metro_id
 where g.arquitectura_id = v_arq and g.dimension = 'metro' and g.activo
  and m.arte = 'menor' and m.silabas between 3 and 8 and o.posicion_unidad is null;
 if v_n <> 24 then raise exception 'Las cuatro partes no ofrecen seis medidas uniformes cada una: % opciones.', v_n; end if;
 if exists (select 1 from villancico_opciones_previas antes
  where not exists (select 1 from public.opciones_eleccion_metrica o where o.opcion_eleccion_id = antes.opcion_eleccion_id)) then
  raise exception 'Ha cambiado el identificador de una opción anterior del villancico.';
 end if;
 perform public.get_forma_metrica_publica_jerarquica('villancico');
 perform public.obtener_catalogo_demarcador();

 -- Guardado real en un escenario desechable. Cada metro se prueba en las cuatro
 -- partes, y el escenario completo se deshace al terminar, sin usar ninguna obra.
 select e.user_id into v_admin from public.editores e join public.vocabularios r on r.termino_id = e.role
 where lower(r.termino) in ('admin', 'ip') and e.activo order by e.created_at limit 1;
 if v_admin is null then raise exception 'No hay una identidad admin/IP para ensayar el guardado.'; end if;
 perform set_config('request.jwt.claim.sub', v_admin::text, true);
 select jsonb_object_agg(slug, seccion_id) into v_secciones
 from public.estructuras_secciones where arquitectura_id = v_arq;
 begin
  insert into public.anotacion_escenarios_prueba (nombre, created_by, updated_by)
  values ('Guarda transitoria: medidas del villancico', v_admin, v_admin) returning escenario_id into v_escenario;
  v_raiz := gen_random_uuid(); v_cabeza := gen_random_uuid(); v_ciclo := gen_random_uuid();
  v_copla := gen_random_uuid(); v_mudanza := gen_random_uuid(); v_enlace := gen_random_uuid();
  v_vuelta := gen_random_uuid(); v_represa := gen_random_uuid();
  v_unidades := (select jsonb_agg(jsonb_build_object('realizacion_id', unidad, 'realizacion_padre_id', padre,
   'seccion_id', case when seccion is null then null else (v_secciones ->> seccion)::uuid end,
   'orden', orden_global, 'v_ini', inicio, 'v_fin', fin) order by orden_global)
   from (values
    (1, v_raiz, null::uuid, null::text, 1, 1, 11),
    (2, v_cabeza, v_raiz, 'cabeza', 1, 1, 2),
    (3, v_ciclo, v_raiz, 'ciclo_copla', 2, 3, 11),
    (4, v_copla, v_ciclo, 'copla', 1, 3, 9),
    (5, v_mudanza, v_copla, 'mudanza', 1, 3, 6),
    (6, v_enlace, v_copla, 'enlace', 2, 7, 7),
    (7, v_vuelta, v_copla, 'vuelta', 3, 8, 9),
    (8, v_represa, v_ciclo, 'represa', 2, 10, 11)
   ) unidades(orden_global, unidad, padre, seccion, orden, inicio, fin));

  v_n := 0;
  for v_metro in select metro_id, silabas from public.metros where activo and arte = 'menor'
   and silabas between 3 and 8 order by silabas loop
   v_n := v_n + 1;
   -- Se guarda la misma anotación: la RPC retira sus realizaciones antes de recrearlas.
   select jsonb_agg(jsonb_build_object('dimension', 'metro', 'opcion_eleccion_id', o.opcion_eleccion_id,
    'realizacion_id', case g.slug when 'medida_cabeza' then v_cabeza when 'medida_mudanza' then v_mudanza
     when 'medida_enlace' then v_enlace when 'medida_vuelta' then v_vuelta end)) into v_elecciones
   from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
   where g.arquitectura_id = v_arq and g.dimension = 'metro' and g.activo and o.metro_id = v_metro.metro_id;
   v_elecciones := v_elecciones || jsonb_build_array((select jsonb_build_object('dimension', 'rima',
    'opcion_eleccion_id', o.opcion_eleccion_id, 'realizacion_id', v_mudanza)
    from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
    join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
    where g.arquitectura_id = v_arq and g.slug = 'rima_mudanza' and o.activo and er.notacion = 'abba' limit 1),
    (select jsonb_build_object('dimension', 'repeticion', 'opcion_eleccion_id', o.opcion_eleccion_id,
     'realizacion_id', v_ciclo) from public.opciones_eleccion_metrica o
     join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
     where g.arquitectura_id = v_arq and g.slug = 'represa_estribillo' and o.activo order by o.orden limit 1));
   v_payload := jsonb_build_object('anotacion_id', v_anotacion, 'escenario_id', v_escenario, 'forma_id', v_forma, 'arquitectura_id', v_arq,
    'orden', 1, 'v_ini', 1, 'v_fin', 11, 'unidades', v_unidades, 'elecciones', v_elecciones);
   v_anotacion := public.guardar_anotacion_metrica(v_payload);
   set constraints all immediate;
   set constraints all deferred;
  end loop;

  -- Las partes pueden medir distinto, sin que una misma parte admita dos medidas.
  select jsonb_agg(jsonb_build_object('dimension', 'metro', 'opcion_eleccion_id', o.opcion_eleccion_id,
   'realizacion_id', case g.slug when 'medida_cabeza' then v_cabeza when 'medida_mudanza' then v_mudanza
    when 'medida_enlace' then v_enlace when 'medida_vuelta' then v_vuelta end)) into v_elecciones
  from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
  join public.metros m on m.metro_id = o.metro_id
  where g.arquitectura_id = v_arq and g.dimension = 'metro' and g.activo
   and m.silabas = case g.slug when 'medida_cabeza' then 5 when 'medida_mudanza' then 7
    when 'medida_enlace' then 3 when 'medida_vuelta' then 4 end;
  v_elecciones := v_elecciones || (select jsonb_agg(e) from jsonb_array_elements(v_payload -> 'elecciones') e
   where e ->> 'dimension' <> 'metro');
  v_payload := jsonb_set(v_payload, '{elecciones}', v_elecciones);
  perform public.guardar_anotacion_metrica(v_payload);
  set constraints all immediate;
  set constraints all deferred;

  v_elecciones := v_elecciones || jsonb_build_array((select jsonb_build_object('dimension', 'metro',
   'opcion_eleccion_id', o.opcion_eleccion_id, 'realizacion_id', v_cabeza)
   from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
   join public.metros m on m.metro_id = o.metro_id
   where g.arquitectura_id = v_arq and g.slug = 'medida_cabeza' and m.silabas = 7));
  begin
   perform public.guardar_anotacion_metrica(jsonb_set(v_payload, '{elecciones}', v_elecciones));
   raise exception 'La base ha admitido dos medidas dentro de la misma cabeza.';
  exception when raise_exception then
   if sqlerrm not like 'La pregunta «%» necesita entre 1 y 1 respuestas%' then raise; end if;
  end;
  raise exception using errcode = 'ZX001', message = 'Deshacer los escenarios de las guardas';
 exception when sqlstate 'ZX001' then null;
 end;

 if exists (select 1 from villancico_registro_previo antes left join public.anotaciones_metricas am using (anotacion_id)
  where to_jsonb(am) is distinct from antes.anotacion or antes.respuestas is distinct from
   coalesce((select jsonb_agg(to_jsonb(e) order by e.eleccion_id)
    from public.anotacion_elecciones e where e.anotacion_id = am.anotacion_id), '[]'::jsonb)) then
  raise exception 'Ha cambiado una anotación de villancico.';
 end if;
 if exists (select 1 from villancico_retirado_previo antes left join public.esquemas_metricos em using (esquema_metrico_id)
  where to_jsonb(em) is distinct from antes.esquema or antes.opciones is distinct from
   coalesce((select jsonb_agg(to_jsonb(eo) order by eo.metro_id)
    from public.esquema_metrico_opciones eo where eo.esquema_metrico_id = em.esquema_metrico_id), '[]'::jsonb)) then
  raise exception 'Ha cambiado el esquema de la arquitectura retirada.';
 end if;
 if exists (select 1 from villancico_prosa_previa antes where antes.texto is distinct from case antes.entidad
  when 'forma' then (select definicion from public.formas_metricas where forma_id = antes.id)
  when 'arquitectura' then (select descripcion from public.arquitecturas_forma where arquitectura_id = antes.id)
  when 'esquema' then (select descripcion from public.esquemas_metricos where esquema_metrico_id = antes.id)
  when 'pregunta' then (select ayuda_editor from public.grupos_eleccion_metrica where grupo_eleccion_id = antes.id)
  when 'afirmacion' then (select resumen from public.afirmaciones_fuentes_metricas where afirmacion_id = antes.id)
 end) then raise exception 'Ha cambiado la prosa del catálogo sin aprobación.'; end if;
end;
$guardas$;

update public.catalogo_metrico_estado set revision = revision + 1, actualizado_en = now() where id;
set constraints all immediate;
commit;
