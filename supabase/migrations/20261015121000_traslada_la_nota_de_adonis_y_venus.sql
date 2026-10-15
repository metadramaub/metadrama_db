-- Obra ya anotada en V2: conserva la caracterización y su texto histórico.
begin;

create temporary table caracterizaciones_antes on commit drop as
select caracterizacion_rango_id, to_jsonb(r) as fila
from public.secuencias_caracterizaciones_rango r;

do $guardas$
declare
  v_id uuid := 'd73527b8-210f-4e16-a7ed-600fa817b796';
  v_obra uuid := '0eec854e-f2e9-455b-9fbd-49c63c427d14';
  v_secuencia uuid := 'ce1ef3f6-d89a-4491-9c3e-ac6706a8dabf';
  v_autor uuid := 'b30b5800-8acc-4574-b6d2-40c2b300ef4d';
  v_actor uuid := 'fc61b25d-f171-4848-93d8-ea923501f7a7';
  v_texto text := 'Véase la justificación de estos versos cantados en la bibliografía (Gilabert, 2021: 65-87).';
  v_comentario uuid;
  v_ficha jsonb;
  v_publica jsonb;
  v_creados integer;
begin
  if not exists (
    select 1 from public.secuencias_caracterizaciones_rango r
    join public.secuencias_metricas s using (secuencia_id)
    join public.obras o using (obra_id)
    where r.caracterizacion_rango_id = v_id and r.secuencia_id = v_secuencia
      and o.obra_id = v_obra and o.editor_asignado = v_autor
      and r.v_ini = 1229 and r.v_fin = 1287 and r.observaciones = v_texto
      and s.estrofa_tipo_id is null
  ) then raise exception 'Ha cambiado la nota revisada de Adonis y Venus'; end if;

  v_creados := public.trasladar_observaciones_a_comentarios(array[v_id], v_actor);
  if v_creados not in (0, 1) then raise exception 'Recuento de traslado inesperado'; end if;
  if public.trasladar_observaciones_a_comentarios(array[v_id], v_actor) <> 0 then
    raise exception 'Repetir el traslado duplica el comentario'; end if;

  select t.comentario_id into v_comentario
  from public.traslados_observaciones_caracterizacion t
  join public.comentarios_internos c using (comentario_id)
  join public.vocabularios v on v.termino_id = c.tipo_comentario_id
  where t.caracterizacion_rango_id = v_id and c.user_id = v_autor
    and c.publicado_por = v_actor and c.visible_publico
    and c.obra_id = v_obra and c.secuencia_id = v_secuencia
    and v.termino = 'observacion_publica'
    and c.comentario = '**Vv. 1229–1287.**' || E'\n\n' || v_texto;
  if v_comentario is null then raise exception 'Falla autoría, texto o contexto del comentario'; end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_actor)::text, true);
  v_ficha := public.ficha_publica_base_json(v_obra, true);
  if not exists (
    select 1 from jsonb_array_elements(v_ficha #> '{metrica,secuencias}') s,
      jsonb_array_elements(s -> 'caracterizaciones_rango') r
    where r ->> 'caracterizacion_rango_id' = v_id::text
      and r ->> 'observaciones' is null
  ) then raise exception 'La ficha no conserva el canto sin duplicar su nota'; end if;

  if public.can_view_obra_ficha_publica(v_obra, true) then
    v_publica := public.get_obra_comentarios_publicos(v_obra, true);
    if not exists (select 1 from jsonb_array_elements(v_publica) c
      where c ->> 'comentario_id' = v_comentario::text)
    then raise exception 'El lector público no devuelve el comentario'; end if;
  end if;

  if exists (
    select 1 from caracterizaciones_antes a
    full join public.secuencias_caracterizaciones_rango r using (caracterizacion_rango_id)
    where a.fila is distinct from to_jsonb(r)
  ) then raise exception 'Se ha modificado una caracterización original'; end if;
end;
$guardas$;

commit;
