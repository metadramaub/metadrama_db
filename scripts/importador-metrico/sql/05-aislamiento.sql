-- BORRADOR LOCAL. Las básicas no entran todavía en el editor v2 ni en sus productores.
begin;

create or replace function public.auth_obra_es_detallada(p_obra uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.obras where obra_id=p_obra and tipo_ficha='completa');
$$;
revoke all on function public.auth_obra_es_detallada(uuid) from public,anon;
grant execute on function public.auth_obra_es_detallada(uuid) to authenticated;

create or replace function public.auth_puede_editar_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists (
  select 1 from public.obras o
  join public.editores e on e.user_id=auth.uid()
  join public.vocabularios vr on vr.termino_id=e.role
  where o.obra_id=p_obra_id and o.tipo_ficha='completa' and coalesce(e.activo,true)
   and (lower(vr.termino) in ('admin','ip')
     or (lower(vr.termino)='editor' and o.editor_asignado=e.user_id)));
$$;

-- Las políticas permisivas antiguas de admin/IP se combinan con OR. Este límite es AND.
-- La operación de importación, SECURITY DEFINER, sigue pudiendo crear la estructura inicial.
do $$
declare t text; operacion text; expresion text;
begin
 for t,expresion in values
  ('obras', 'tipo_ficha=''completa'''),
  ('jornadas','public.auth_obra_es_detallada(obra_id)'),
  ('secuencias_metricas','public.auth_obra_es_detallada(obra_id)'),
  ('cuadros','exists(select 1 from public.jornadas j where j.jornada_id=cuadros.jornada_id and public.auth_obra_es_detallada(j.obra_id))')
 loop
  foreach operacion in array array['insert','update','delete'] loop
   execute format('drop policy if exists %I on public.%I',t||'_basicas_'||operacion,t);
   execute format('create policy %I on public.%I as restrictive for %s to authenticated %s',
    t||'_basicas_'||operacion,t,operacion,
    case operacion when 'insert' then 'with check ('||expresion||')'
     when 'delete' then 'using ('||expresion||')'
     else 'using ('||expresion||') with check ('||expresion||')' end);
  end loop;
 end loop;
end;
$$;

-- Una llamada directa a guardar_anotacion_metrica también queda protegida por el predicado.
-- El trigger cubre además INSERT directo con las políticas generales de admin/IP.
create or replace function public.impedir_v2_en_basica() returns trigger
language plpgsql set search_path = '' as $$
begin
 if new.secuencia_id is not null and exists (
  select 1 from public.secuencias_metricas s join public.obras o using(obra_id)
  where s.secuencia_id=new.secuencia_id and o.tipo_ficha='minima') then
  raise exception using errcode='23514',message='La métrica de una ficha básica se registra mediante el importador';
 end if;
 return new;
end;
$$;
drop trigger if exists impedir_v2_en_basica on public.anotaciones_metricas;
create trigger impedir_v2_en_basica before insert or update on public.anotaciones_metricas
 for each row execute function public.impedir_v2_en_basica();

-- Adaptaciones pequeñas sobre las definiciones existentes, preservando el cálculo detallado.
-- Cada ancla debe ser única: un cambio de implementación exige revisar el borrador.
do $adaptacion$
declare nombre text; ancla text; cambio text; definicion text; firma regprocedure;
begin
 for nombre,ancla,cambio in values
  ('public.formas_de_la_obra(uuid)', 'where sm.obra_id = p_obra_id',
   'where sm.obra_id = p_obra_id and public.auth_obra_es_detallada(sm.obra_id) /* importador:aislado */'),
  ('public.perfil_metrico_unidades()', 'left join public.jornadas j on j.jornada_id = g.jornada_id;',
   'left join public.jornadas j on j.jornada_id = g.jornada_id where public.auth_obra_es_detallada(coalesce(g.obra_id,j.obra_id)); /* importador:aislado */'),
  ('public.gestionar_asignaciones_lote(text,uuid,jsonb)', 'select coalesce(array_agg(r.revisor_id order by r.revisor_id), ''{}''::uuid[]) into v_anteriores',
   'if v_obra.tipo_ficha=''minima'' then raise exception using errcode=''42501'',message=''La asignación de una básica requiere el recorrido de elaboración detallada''; end if; /* importador:aislado */ select coalesce(array_agg(r.revisor_id order by r.revisor_id), ''{}''::uuid[]) into v_anteriores')
 loop
  firma:=nombre::regprocedure;
  definicion:=pg_get_functiondef(firma);
  if position('importador:aislado' in definicion)>0 then continue; end if;
  if (length(definicion)-length(replace(definicion,ancla,'')))/length(ancla) <> 1 then
   raise exception 'Revisar adaptación de %: el ancla ha cambiado',nombre;
  end if;
  execute replace(definicion,ancla,cambio);
 end loop;
 for nombre in select unnest(array[
  'public.recompute_obra_resumen_metricas(uuid)',
  'public.recompute_obra_resumen_estructura(uuid)',
  'public.recompute_artefactos_obra(uuid)',
  'public.analisis_obra_publico_json(uuid)',
  'public.ficha_publica_base_json(uuid,boolean)',
  'public.ficha_publica_dominio_json(uuid,boolean)',
  'public.perfil_artefacto_obra_rango(uuid,integer,integer,text)'])
 loop
  definicion:=pg_get_functiondef(nombre::regprocedure);
  if position('importador:aislado' in definicion)>0 then continue; end if;
  -- La primera entrada al cuerpo PL/pgSQL; no se modifican consultas ni denominadores.
  if position(E'begin\n' in definicion)=0 then raise exception 'Revisar cuerpo de %',nombre; end if;
  definicion:=regexp_replace(definicion,E'begin\n',E'begin\n'
    ||' if exists(select 1 from public.obras where obra_id=p_obra_id and tipo_ficha=''minima'') then'
    ||E'\n  raise exception using errcode=''42501'',message=''La ficha básica requiere el productor combinado, todavía no habilitado'';'
    ||E'\n end if; /* importador:aislado */\n');
  execute definicion;
 end loop;
end;
$adaptacion$;
commit;
