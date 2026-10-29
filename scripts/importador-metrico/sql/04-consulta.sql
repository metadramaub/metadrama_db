-- BORRADOR LOCAL. Consultas de sesión y de la copia confirmada, sin activar análisis.
begin;
create or replace function public.capacidades_importador_metrico() returns jsonb
language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('puede_importar',public.auth_puede_importar_metrica(),
 'guardado_disponible',public.auth_puede_importar_metrica());
$$;
revoke all on function public.capacidades_importador_metrico() from public,anon;
grant execute on function public.capacidades_importador_metrico() to authenticated;

create or replace function public.listar_fichas_basicas(p_desde integer default 0)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='La sesión no puede consultar fichas básicas';
 end if;
 if p_desde is null or p_desde<0 then raise exception using errcode='22023',message='Página inválida'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(f)), '[]'::jsonb) from (
  select i.importacion_id,i.obra_id,i.datos_confirmados#>>'{metadatos,titulo}' as titulo,
   i.datos_confirmados#>>'{metadatos,autor_nombre}' as autor_nombre,
   e.nombre_completo::text as importado_por,i.importado_en
  from public.importaciones_metricas i join public.obras o using(obra_id)
  join public.editores e on e.user_id=i.importado_por
  where o.tipo_ficha='minima' and i.usada_en_corpus
  order by i.importado_en desc,i.importacion_id limit 51 offset p_desde
 ) f);
end;
$$;
revoke all on function public.listar_fichas_basicas(integer) from public,anon;
grant execute on function public.listar_fichas_basicas(integer) to authenticated;

create or replace function public.consultar_importacion_metrica(p_importacion uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('importacion_id',i.importacion_id,'obra_id',i.obra_id,
  'importado_por',e.nombre_completo,'importado_en',i.importado_en,
  'datos_confirmados',i.datos_confirmados,'entrada_original',i.entrada_original)
 from public.importaciones_metricas i join public.editores e on e.user_id=i.importado_por
 where i.importacion_id=p_importacion and public.auth_puede_consultar_importacion(i.obra_id);
$$;
revoke all on function public.consultar_importacion_metrica(uuid) from public,anon;
grant execute on function public.consultar_importacion_metrica(uuid) to authenticated;

create or replace function public.localizar_importacion_metrica(p_obra uuid)
returns uuid language sql stable security definer set search_path = '' as $$
 select i.importacion_id from public.importaciones_metricas i
 where i.obra_id=p_obra and public.auth_puede_consultar_importacion(i.obra_id)
 order by i.usada_en_corpus desc,i.importado_en desc,i.importacion_id limit 1;
$$;
revoke all on function public.localizar_importacion_metrica(uuid) from public,anon;
grant execute on function public.localizar_importacion_metrica(uuid) to authenticated;
commit;
