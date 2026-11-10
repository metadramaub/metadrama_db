-- Evita expandir las políticas de autoría dentro de una subconsulta por fila del inventario.
-- La comprobación de acceso se mantiene explícita antes de leer las propuestas.
create or replace function public.autores_de_obra_editorial(p_obra uuid) returns text[]
language plpgsql stable security definer set search_path='' as $$
declare mantenimiento boolean:=auth.uid() is null and session_user in ('postgres','supabase_admin');
        servicio boolean:=coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role','')='service_role';
begin
 if not(mantenimiento or servicio or public.auth_puede_ver_obra(p_obra) or
   (exists(select 1 from public.importaciones_metricas where obra_id=p_obra) and public.auth_puede_consultar_importacion(p_obra))) then
  return '{}'::text[];
 end if;
 return coalesce((select array_agg(distinct au.nombre_completo::text order by au.nombre_completo::text)
  from public.atribuciones a join public.atribucion_autores aa using(atribucion_id)
  join public.autores au using(autor_id) where a.obra_id=p_obra),'{}'::text[]);
end $$;
revoke all on function public.autores_de_obra_editorial(uuid) from public,anon;
grant execute on function public.autores_de_obra_editorial(uuid) to authenticated,service_role,postgres;
