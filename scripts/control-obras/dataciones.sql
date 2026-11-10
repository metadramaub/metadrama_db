-- Expansión: el registro conserva las columnas históricas, congeladas para recuperación.
create table if not exists public.obras_dataciones (
 obra_id uuid not null references public.obras(obra_id) on delete cascade,
 clase text not null check(clase in ('referencia','metrica')),
 inicio integer, fin integer,
 inicio_inclusivo boolean not null default true,
 fin_inclusivo boolean not null default true,
 aproximada boolean not null default false,
 fuente text,
 primary key(obra_id,clase),
 check(inicio is null or inicio between 1 and 9999),
 check(fin is null or fin between 1 and 9999),
 check(inicio is null or fin is null or inicio + case when inicio_inclusivo then 0 else 1 end
   <= fin - case when fin_inclusivo then 0 else 1 end),
 check(inicio is not null or fin is not null or nullif(fuente,'') is not null)
);
alter table public.obras_dataciones enable row level security;
revoke all on public.obras_dataciones from public,anon,authenticated;
grant select on public.obras_dataciones to authenticated;
grant all on public.obras_dataciones to service_role;
drop policy if exists dataciones_consulta on public.obras_dataciones;
create policy dataciones_consulta on public.obras_dataciones for select to authenticated using (
 public.auth_puede_ver_obra(obra_id) or
 (exists(select 1 from public.importaciones_metricas i where i.obra_id=obras_dataciones.obra_id)
  and public.auth_puede_consultar_importacion(obra_id))
);
-- Copia literal: ninguna procedencia ni marca de revisión. La segunda ejecución no repone fechas borradas.
do $$ begin
 if not exists(select 1 from pg_description where objoid='public.obras_dataciones'::regclass and objsubid=0) then
  insert into public.obras_dataciones(obra_id,clase,inicio,fin,fuente)
  select obra_id,'referencia',fecha_inicio_trad,fecha_fin_trad,fuente_fecha from public.obras
   where fecha_inicio_trad is not null or fecha_fin_trad is not null or nullif(fuente_fecha,'') is not null;
  insert into public.obras_dataciones(obra_id,clase,inicio,fin)
  select obra_id,'metrica',fecha_inicio_metadrama,fecha_fin_metadrama from public.obras
   where fecha_inicio_metadrama is not null or fecha_fin_metadrama is not null;
  comment on table public.obras_dataciones is 'Dataciones de referencia y métrica; expansión inicial copiada.';
 end if;
end $$;

-- Corrección expresamente confirmada por el IP: el 1612 de esta edición es un límite superior.
-- Se conserva la fuente; si el dato cambia antes del despliegue se exige volver a cotejarlo.
do $$ declare d public.obras_dataciones%rowtype; begin
 select * into d from public.obras_dataciones where obra_id='443d1994-5ded-436e-a89f-54dcd538d732' and clase='referencia';
 if found then
  if d.inicio=1612 and d.fin is null then
   if encode(extensions.digest(convert_to(coalesce(d.fuente,''),'UTF8'),'sha256'),'hex')<>'90081a0b1319129d5b309da7fc11c49f315477b47ff9767035c25704efee8bed' then
    raise exception 'Ha cambiado la fuente de El esclavo del demonio; volver a cotejar antes de desplegar';
   end if;
   update public.obras_dataciones set inicio=null,fin=1612,inicio_inclusivo=true,fin_inclusivo=true
    where obra_id=d.obra_id and clase=d.clase;
  elsif d.inicio is null and d.fin=1612 and d.fin_inclusivo then null;
  else raise exception 'Ha cambiado la datación de El esclavo del demonio; volver a cotejar antes de desplegar';
  end if;
 end if;
end $$;

-- Operación interna atómica: el trigger de la proyección y el importador comprueban sus propios permisos.
-- No se concede EXECUTE a usuarios ni a PostgREST.
create or replace function public.escribir_dataciones_obra(p_obra uuid,p_dataciones jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare d jsonb;
begin
 if jsonb_typeof(p_dataciones) is distinct from 'array' or jsonb_array_length(p_dataciones)>2 then
  raise exception 'Se admite una datación por clase' using errcode='22023'; end if;
 if exists(select 1 from jsonb_array_elements(p_dataciones) x group by x->>'clase' having count(*)>1) then
  raise exception 'Clase de datación repetida' using errcode='22023'; end if;
 delete from public.obras_dataciones where obra_id=p_obra and clase not in
  (select x->>'clase' from jsonb_array_elements(p_dataciones) x);
 for d in select value from jsonb_array_elements(p_dataciones) loop
  if d->>'clase' is null or d->>'clase' not in ('referencia','metrica') then
   raise exception 'Clase de datación inválida' using errcode='22023'; end if;
  if d->>'inicio' is null and d->>'fin' is null and coalesce(d->>'fuente','')='' then
   delete from public.obras_dataciones where obra_id=p_obra and clase=d->>'clase';
  else
   insert into public.obras_dataciones(obra_id,clase,inicio,fin,inicio_inclusivo,fin_inclusivo,aproximada,fuente)
   values(p_obra,d->>'clase',(d->>'inicio')::integer,(d->>'fin')::integer,
    coalesce((d->>'inicio_inclusivo')::boolean,true),coalesce((d->>'fin_inclusivo')::boolean,true),
    coalesce((d->>'aproximada')::boolean,false),d->>'fuente')
   on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
    inicio_inclusivo=excluded.inicio_inclusivo,fin_inclusivo=excluded.fin_inclusivo,
    aproximada=excluded.aproximada,fuente=excluded.fuente
   where (obras_dataciones.inicio,obras_dataciones.fin,obras_dataciones.inicio_inclusivo,
    obras_dataciones.fin_inclusivo,obras_dataciones.aproximada,obras_dataciones.fuente)
    is distinct from (excluded.inicio,excluded.fin,excluded.inicio_inclusivo,excluded.fin_inclusivo,excluded.aproximada,excluded.fuente);
  end if;
 end loop;
end $$;
revoke all on function public.escribir_dataciones_obra(uuid,jsonb) from public,anon,authenticated;

create or replace function public.datacion_marca_suciedad() returns trigger
language plpgsql security definer set search_path='' as $$
declare id uuid:=coalesce(new.obra_id,old.obra_id);
begin
 -- Reutilizar la ruta de invalidación real del registro (sin modificar sus fechas históricas).
 update public.obras set updated_at=now() where obra_id=id;
 update public.obras_resumen set metrica_sucia=true where obra_id=id;
 update public.autores_resumen set metrica_sucia=true where autor_id in (
  select aa.autor_id from public.atribuciones a join public.atribucion_autores aa using(atribucion_id) where a.obra_id=id);
 return coalesce(new,old);
end $$;
revoke all on function public.datacion_marca_suciedad() from public,anon,authenticated;
drop trigger if exists dataciones_suciedad on public.obras_dataciones;
create trigger dataciones_suciedad after insert or update or delete on public.obras_dataciones
 for each row execute function public.datacion_marca_suciedad();
