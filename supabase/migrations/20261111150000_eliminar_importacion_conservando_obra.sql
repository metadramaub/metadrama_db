create or replace function public.eliminar_ficha_basica(p_importacion uuid, p_confirmacion text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  importacion public.importaciones_metricas%rowtype;
  obra_destino uuid;
  jornadas_guardadas jsonb;
  jornadas_importadas jsonb;
begin
  if not public.auth_is_admin_or_ip() or not public.auth_puede_importar_metrica() then
    raise exception using errcode = '42501', message = 'Solo admin o IP pueden eliminar fichas básicas';
  end if;

  -- El guardado de básicas y el inicio de completas bloquean primero la obra.
  select o.obra_id into obra_destino
    from public.obras o join public.importaciones_metricas i using (obra_id)
    where i.importacion_id = p_importacion
    for update of o;
  select * into importacion
    from public.importaciones_metricas
    where importacion_id = p_importacion and obra_id = obra_destino
    for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'La ficha ya no está disponible';
  end if;
  if not importacion.usada_en_corpus
    or exists (select 1 from public.fichas_completas where obra_id = obra_destino) then
    raise exception using errcode = '23514', message = 'La obra ya no tiene una ficha básica vigente';
  end if;
  if btrim(p_confirmacion) is distinct from btrim(importacion.datos_confirmados #>> '{metadatos,titulo}') then
    raise exception using errcode = '22023', message = 'Escribe el título de la obra para confirmar';
  end if;

  perform 1 from public.jornadas where obra_id = obra_destino for update;
  perform 1 from public.secuencias_metricas where obra_id = obra_destino for update;

  select jsonb_agg(jsonb_build_array(jornada_num, v_ini, v_fin) order by jornada_num)
    into jornadas_guardadas from public.jornadas where obra_id = obra_destino;
  select jsonb_agg(jsonb_build_array((j->>'numero')::int, (j->>'v_ini')::int, (j->>'v_fin')::int)
    order by (j->>'numero')::int)
    into jornadas_importadas from jsonb_array_elements(importacion.datos_confirmados->'jornadas') j;

  -- Las jornadas no tienen FK a la importación. Cotejamos sus rangos y
  -- comprobamos las dependencias antes de retirar la estructura importada.
  if jornadas_guardadas is distinct from jornadas_importadas
    or exists (
      select 1 from public.jornadas j where j.obra_id = obra_destino and (
        exists (select 1 from public.cuadros where jornada_id = j.jornada_id)
        or exists (select 1 from public.atribuciones where jornada_id = j.jornada_id)
        or exists (select 1 from public.grupos_atribucion where jornada_id = j.jornada_id)
        or exists (select 1 from public.comentarios_internos where jornada_id = j.jornada_id)
      )
    )
    or exists (
      select 1 from public.secuencias_metricas s where s.obra_id = obra_destino and (
        not exists (select 1 from public.metrica_minima_secuencias m
          where m.secuencia_id = s.secuencia_id and m.importacion_id = p_importacion)
        or num_nonnulls(s.estrofa_tipo_id, s.inaugura_espacio, s.intervencion_personajes_femeninos,
          s.intervencion_figuras_donaire, s.intervencion_personajes_sobrenaturales, s.sinopsis,
          s.versos_partidos, s.evento_sobrenatural, s.generos_intervinientes) > 0
        or exists (select 1 from public.anotaciones_metricas where secuencia_id = s.secuencia_id)
        or exists (select 1 from public.comentarios_internos where secuencia_id = s.secuencia_id)
        or exists (select 1 from public.migracion_secuencias where secuencia_id = s.secuencia_id)
        or exists (select 1 from public.secuencias_subtipos_estrofa where secuencia_id = s.secuencia_id)
        or exists (select 1 from public.secuencias_caracterizaciones_rango where secuencia_id = s.secuencia_id)
      )
    ) then
    raise exception using errcode = '23514',
      message = 'La obra contiene estructura o anotaciones ajenas a la importación';
  end if;

  delete from public.secuencias_metricas s using public.metrica_minima_secuencias m
    where s.obra_id = obra_destino and s.secuencia_id = m.secuencia_id and m.importacion_id = p_importacion;
  delete from public.jornadas where obra_id = obra_destino;
  delete from public.importaciones_metricas where importacion_id = p_importacion;
  update public.obras set total_versos = null where obra_id = obra_destino;

  return jsonb_build_object('eliminada', true, 'obra_id', obra_destino);
end;
$$;
