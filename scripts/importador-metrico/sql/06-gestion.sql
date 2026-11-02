-- Gestión editorial de básicas. No abre escritura directa sobre las copias confirmadas.
begin;

-- Los registros anteriores no se fechan retroactivamente. Las nuevas copias nacen
-- con ambas fechas; hoy son inmutables y aún no existe edición/reimportación general.
alter table public.importaciones_metricas add column if not exists modificado_en timestamptz;
alter table public.importaciones_metricas alter column modificado_en set default now();

create or replace function public.listar_fichas_basicas(p_desde integer default 0)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='La sesión no puede consultar fichas básicas';
 end if;
 if p_desde is null or p_desde<0 then raise exception using errcode='22023',message='Página inválida'; end if;
 return (
  with pagina as materialized (
   select i.* ,e.nombre_completo::text as importado_por_nombre
   from public.importaciones_metricas i join public.obras o using(obra_id)
   join public.editores e on e.user_id=i.importado_por
   where o.tipo_ficha='minima' and i.usada_en_corpus
   order by i.importado_en desc,i.importacion_id limit 51 offset p_desde
  )
  select coalesce(jsonb_agg(jsonb_build_object(
   'importacion_id',i.importacion_id,'obra_id',i.obra_id,
   'titulo',i.datos_confirmados#>>'{metadatos,titulo}',
   'autor_nombre',i.datos_confirmados#>>'{metadatos,autor_nombre}',
   'importado_por',i.importado_por_nombre,'importado_en',i.importado_en,
   'modificado_en',i.modificado_en,
   'formas_pendientes',coalesce((select jsonb_agg(jsonb_build_object(
     'denominacion',coalesce(s#>>'{origen,denominacion_literal}','Forma sin resolver'),
     'v_ini',(s->>'v_ini')::integer,'v_fin',(s->>'v_fin')::integer
    ) order by (s->>'v_ini')::integer)
    from jsonb_array_elements(i.datos_confirmados->'segmentos') s
    where s->'identificacion'='null'::jsonb),'[]'::jsonb),
   'comprobacion_registrada',i.datos_confirmados ? 'comprobacion',
   'avisos_longitud',coalesce(i.datos_confirmados#>'{comprobacion,avisos_longitud}','[]'::jsonb),
   'incidencias_fuente',coalesce((select jsonb_agg(jsonb_build_object('descripcion',c->>'descripcion'))
      from jsonb_array_elements(i.entrada_original->'incidencias') c),'[]'::jsonb)
  ) order by i.importado_en desc,i.importacion_id),'[]'::jsonb) from pagina i
 );
end;
$$;
revoke all on function public.listar_fichas_basicas(integer) from public,anon;
grant execute on function public.listar_fichas_basicas(integer) to authenticated;

create or replace function public.eliminar_ficha_basica(p_importacion uuid,p_confirmacion text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_obra uuid; v_tipo text; v_editor uuid; v_titulo text; v_vigente boolean;
begin
 if not public.auth_is_admin_or_ip() or not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='Solo admin o IP pueden eliminar fichas básicas';
 end if;
 -- Bloqueo compartido con las operaciones que modifiquen el tipo o asignación de la obra.
 select o.obra_id,o.tipo_ficha,o.editor_asignado,i.datos_confirmados#>>'{metadatos,titulo}',i.usada_en_corpus
 into v_obra,v_tipo,v_editor,v_titulo,v_vigente
 from public.importaciones_metricas i join public.obras o using(obra_id)
 where i.importacion_id=p_importacion for update of o,i;
 if not found then raise exception using errcode='P0002',message='La ficha ya no está disponible'; end if;
 if v_tipo<>'minima' or not v_vigente or v_editor is not null then
  raise exception using errcode='23514',message='La obra ya no es una ficha básica disponible para eliminar';
 end if;
 if p_confirmacion is null or btrim(p_confirmacion)<>btrim(v_titulo) then
  raise exception using errcode='22023',message='Escribe el título de la obra para confirmar';
 end if;
 if exists(select 1 from public.secuencias_metricas s join public.anotaciones_metricas a using(secuencia_id) where s.obra_id=v_obra) then
  raise exception using errcode='23514',message='La obra contiene anotaciones detalladas y no puede eliminarse desde el importador';
 end if;
 -- Los FK eliminan en la misma transacción jornadas, secuencias e importaciones de esa obra.
 delete from public.obras where obra_id=v_obra;
 return jsonb_build_object('eliminada',true,'obra_id',v_obra);
end;
$$;
revoke all on function public.eliminar_ficha_basica(uuid,text) from public,anon;
grant execute on function public.eliminar_ficha_basica(uuid,text) to authenticated;
commit;
