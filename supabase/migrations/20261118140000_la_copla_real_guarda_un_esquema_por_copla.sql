-- Conversión de las coplas conformes a la norma 5 + 5 con rimas independientes.
-- Las coplas con incidencias conservan sus dos respuestas hasta su revisión editorial.
begin;

lock table public.anotaciones_metricas, public.anotacion_realizaciones,
 public.anotacion_elecciones, public.anotacion_desviaciones in share row exclusive mode;

do $catalogo$
declare
 arquitectura uuid;
 preguntas integer;
begin
 select a.arquitectura_id into strict arquitectura
 from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
 where f.slug = 'copla_real' and a.slug = 'octosilabica_consonante' and a.activo;

 update public.grupos_eleccion_metrica
 set selecciones_min = 0
 where arquitectura_id = arquitectura and activo
   and slug in ('rima_primera_quintilla','rima_segunda_quintilla');
 get diagnostics preguntas = row_count;
 if preguntas <> 2 then
  raise exception 'Se esperaban las dos preguntas de rima de las quintillas';
 end if;

 insert into public.grupos_eleccion_metrica (
  arquitectura_id, slug, dimension, alcance, tipo_control, selecciones_min,
  selecciones_max, permite_aplicar_global, define_norma, activo, orden, ayuda_editor
 ) values (
  arquitectura, 'rima_copla_completa','rima','unidad','opciones_y_esquema',0,1,true,false,true,99,
  'Escribe cinco posiciones por quintilla, separadas por una barra. Las letras empiezan de nuevo en cada copla.'
 )
 on conflict (arquitectura_id, slug) do nothing;
end $catalogo$;

-- Un entero 5 + 5 se registra como un solo esquema o como el par de respuestas locales.
-- Se comprueba al terminar el guardado, ya que el RPC reemplaza las filas de una anotación.
create or replace function public.comprobar_rima_de_copla_real(p_anotacion uuid)
returns void language plpgsql set search_path = '' as $func$
declare
 copla record;
 local_primera integer;
 local_segunda integer;
 completas integer;
 notacion text;
begin
 for copla in
  select r.realizacion_id, r.v_ini, r.v_fin
  from public.anotaciones_metricas a
  join public.formas_metricas f using (forma_id)
  join public.arquitecturas_forma ar using (arquitectura_id)
  join public.anotacion_realizaciones r using (anotacion_id)
  where a.anotacion_id = p_anotacion and f.slug = 'copla_real'
    and ar.slug = 'octosilabica_consonante' and r.realizacion_padre_id is null
 loop
  select count(*), min(e.valor_texto) into completas, notacion
  from public.anotacion_elecciones e
  where e.anotacion_id = p_anotacion and e.realizacion_id = copla.realizacion_id and e.dimension = 'rima';

  select count(*) filter (where s.slug = 'primera_quintilla'),
         count(*) filter (where s.slug = 'segunda_quintilla')
    into local_primera, local_segunda
  from public.anotacion_realizaciones h
  join public.estructuras_secciones s using (seccion_id)
  join public.anotacion_elecciones e using (realizacion_id, anotacion_id)
  where h.anotacion_id = p_anotacion and h.realizacion_padre_id = copla.realizacion_id and e.dimension = 'rima';

  if completas = 0 and local_primera = 1 and local_segunda = 1 then continue; end if;
  if completas <> 1 or local_primera <> 0 or local_segunda <> 0 or notacion is null then
   raise exception using errcode = '23514',
    message = 'La copla debe tener un esquema completo o una respuesta para cada quintilla';
  end if;
  notacion := regexp_replace(lower(notacion), '[[:space:]]', '', 'g');
  if notacion !~ '^[a-z-]{5}\|[a-z-]{5}$'
    or not exists (select 1 from public.anotacion_realizaciones h
     where h.anotacion_id = p_anotacion and h.realizacion_padre_id = copla.realizacion_id
       and h.v_ini = copla.v_ini and h.v_fin = copla.v_ini + 4)
    or not exists (select 1 from public.anotacion_realizaciones h
     where h.anotacion_id = p_anotacion and h.realizacion_padre_id = copla.realizacion_id
       and h.v_ini = copla.v_ini + 5 and h.v_fin = copla.v_fin and h.v_fin = h.v_ini + 4) then
   raise exception using errcode = '23514',
    message = 'El esquema de la copla completa requiere cinco posiciones en cada quintilla';
  end if;
  if exists (
   select 1 from regexp_split_to_table(split_part(notacion, '|', 1), '') letra
   where letra <> '-' and strpos(split_part(notacion, '|', 2), letra) > 0
  ) then
   raise exception using errcode = '23514',
    message = 'El catálogo vigente exige rimas independientes en las dos quintillas de una copla real';
  end if;
 end loop;
end $func$;

create or replace function public.validar_rima_de_copla_real()
returns trigger language plpgsql security definer set search_path = '' as $func$
begin
 if tg_table_name = 'anotacion_elecciones' then
  if (tg_op = 'INSERT' or old.dimension <> 'rima')
    and (tg_op = 'DELETE' or new.dimension <> 'rima') then
   return null;
  end if;
 end if;
 if tg_op <> 'DELETE' then perform public.comprobar_rima_de_copla_real(new.anotacion_id); end if;
 if tg_op = 'DELETE' or (tg_op = 'UPDATE' and old.anotacion_id <> new.anotacion_id) then
  perform public.comprobar_rima_de_copla_real(old.anotacion_id);
 end if;
 return null;
end $func$;

revoke all on function public.comprobar_rima_de_copla_real(uuid) from public, anon, authenticated;
revoke all on function public.validar_rima_de_copla_real() from public, anon, authenticated;

create constraint trigger validar_rima_de_copla_real
after insert or update or delete on public.anotacion_elecciones
deferrable initially deferred for each row execute function public.validar_rima_de_copla_real();

create constraint trigger validar_rima_de_copla_real
after insert or update or delete on public.anotacion_realizaciones
deferrable initially deferred for each row execute function public.validar_rima_de_copla_real();

-- Lleva las clases locales a letras consecutivas sin cambiar sus coincidencias ni los sueltos.
create function pg_temp.rima_local_canonica(p_notacion text, p_letras text)
returns text language sql immutable as $func$
 with versos as (
  select letra, posicion from regexp_split_to_table(lower(p_notacion), '') with ordinality as v(letra,posicion)
 ), clases as (
  select letra, row_number() over (order by min(posicion)) as indice
  from versos where letra <> '-' group by letra
 )
 select string_agg(case when v.letra = '-' then '-' else substr(p_letras,c.indice::integer,1) end,
                   '' order by v.posicion)
 from versos v left join clases c using (letra);
$func$;

create temporary table conversion_copla_real on commit drop as
select a.anotacion_id, r.realizacion_id, e1.eleccion_id as primera, e2.eleccion_id as segunda,
 p1.notacion as esquema_primera, p2.notacion as esquema_segunda,
 pg_temp.rima_local_canonica(p1.notacion, 'abcde') as primera_normalizada,
 pg_temp.rima_local_canonica(p2.notacion, 'abcde') as segunda_normalizada
from public.anotaciones_metricas a
join public.formas_metricas f using (forma_id)
join public.arquitecturas_forma ar using (arquitectura_id)
join public.anotacion_realizaciones r using (anotacion_id)
join public.anotacion_realizaciones h1 on h1.anotacion_id = a.anotacion_id
 and h1.realizacion_padre_id = r.realizacion_id and h1.v_ini = r.v_ini and h1.v_fin = r.v_ini + 4
join public.anotacion_realizaciones h2 on h2.anotacion_id = a.anotacion_id
 and h2.realizacion_padre_id = r.realizacion_id and h2.v_ini = r.v_ini + 5 and h2.v_fin = r.v_fin
join public.anotacion_elecciones e1 on e1.anotacion_id = a.anotacion_id and e1.realizacion_id = h1.realizacion_id
join public.anotacion_elecciones e2 on e2.anotacion_id = a.anotacion_id and e2.realizacion_id = h2.realizacion_id
join public.esquemas_rima p1 on p1.esquema_rima_id = e1.esquema_rima_id
join public.esquemas_rima p2 on p2.esquema_rima_id = e2.esquema_rima_id
where a.secuencia_id is not null and f.slug = 'copla_real' and ar.slug = 'octosilabica_consonante'
  and r.realizacion_padre_id is null and r.v_fin = r.v_ini + 9
  and e1.dimension = 'rima' and e2.dimension = 'rima'
  and e1.valor_texto is null and e2.valor_texto is null
  and nullif(btrim(e1.observaciones),'') is null and nullif(btrim(e2.observaciones),'') is null
  and p1.notacion ~ '^[a-zA-Z-]{5}$' and p2.notacion ~ '^[a-zA-Z-]{5}$'
  and (select count(*) from public.anotacion_realizaciones h
   where h.anotacion_id = a.anotacion_id and h.realizacion_padre_id = r.realizacion_id) = 2
  and not exists (select 1 from public.anotacion_elecciones e
   where e.anotacion_id = a.anotacion_id and e.realizacion_id = r.realizacion_id and e.dimension = 'rima')
  and not exists (select 1 from public.anotacion_desviaciones d
   where d.anotacion_id = a.anotacion_id and d.dimension in ('rima','estructura')
     and d.v_ini <= r.v_fin and d.v_fin >= r.v_ini);

do $conversion$
declare
 convertidas integer;
begin
 if (select count(*) from conversion_copla_real) <> 107
   or (select md5(string_agg(
    concat_ws(':',realizacion_id,primera,segunda,esquema_primera,esquema_segunda),
    ',' order by realizacion_id,primera,segunda
   )) from conversion_copla_real) is distinct from '491b6c8419f699f2f33e9e34b31f772a' then
  raise exception 'Cambió el lote de 107 coplas revisado antes de la migración';
 end if;
 if pg_temp.rima_local_canonica('xyyxy','cdefg') is distinct from 'cddcd' then
  raise exception 'La conversión debe preservar las clases locales de cada quintilla';
 end if;

 update public.anotacion_elecciones e
 set realizacion_id = c.realizacion_id, esquema_rima_id = null,
   valor_texto = c.primera_normalizada || ' | ' ||
    pg_temp.rima_local_canonica(c.esquema_segunda, substr('abcdefghij',
      1 + (select count(distinct signo)::integer
           from regexp_split_to_table(c.primera_normalizada,'') signo where signo <> '-')))
 from conversion_copla_real c where e.eleccion_id = c.primera;
 get diagnostics convertidas = row_count;
 if convertidas <> 107 then raise exception 'No se convirtieron las 107 coplas'; end if;

 delete from public.anotacion_elecciones e
 using conversion_copla_real c where e.eleccion_id = c.segunda;
 get diagnostics convertidas = row_count;
 if convertidas <> 107 then raise exception 'No se sustituyeron las 107 respuestas locales restantes'; end if;

 if exists (
  select 1 from conversion_copla_real c
  left join public.anotacion_elecciones_resueltas e on e.eleccion_id = c.primera
  left join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = e.grupo_eleccion_id
  where g.slug is distinct from 'rima_copla_completa'
    or pg_temp.rima_local_canonica(btrim(split_part(e.valor_texto,'|',1)), 'abcde') is distinct from c.primera_normalizada
    or pg_temp.rima_local_canonica(btrim(split_part(e.valor_texto,'|',2)), 'abcde') is distinct from c.segunda_normalizada
 ) then
  raise exception 'No se puede reabrir el esquema completo o cambió una rima local';
 end if;
end $conversion$;

set constraints all immediate;
commit;
