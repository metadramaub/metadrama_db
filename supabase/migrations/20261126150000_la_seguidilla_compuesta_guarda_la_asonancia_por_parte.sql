begin;

-- Una asonancia subordinada a una rima de sección depende de esa misma
-- sección y de esa misma unidad. Los condicionamientos de secuencia conservan
-- la comprobación anterior.
create or replace function public.anotacion_afirma_tipo_rima(
  p_anotacion uuid, p_tipo uuid, p_seccion uuid, p_realizacion uuid
)
returns boolean
language sql stable
set search_path to 'public'
as $funcion$
  select case when p_seccion is null then public.anotacion_afirma_tipo_rima(p_anotacion, p_tipo)
    else exists (
      select 1
      from public.anotacion_elecciones e
      left join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
      where e.anotacion_id = p_anotacion and e.dimension = 'rima'
        and e.seccion_tratada_id = p_seccion and e.realizacion_id = p_realizacion
        and (
          er.tipo_rima_id = p_tipo
          or (e.esquema_rima_id is null
            and btrim(split_part(e.valor_texto, '·', 2)) = (
              select v.termino from public.vocabularios v where v.termino_id = p_tipo
            ))
        )
    )
  end;
$funcion$;

do $guardado$
declare
  v_funcion text := pg_get_functiondef('public.guardar_anotacion_metrica(jsonb)'::regprocedure);
  v_inicio integer;
  v_antes text := 'v_secuencia_id, v_grupo.solo_si_tipo_rima_id';
  v_despues text := 'v_secuencia_id, v_grupo.solo_si_tipo_rima_id, v_grupo.seccion_tratada_id, v_grupo.realizacion_id';
  v_unidad text;
begin
  v_inicio := strpos(v_funcion, '-- Una pregunta sin sección se aplica a la unidad entera');
  if v_inicio = 0 then raise exception 'Ha cambiado el guardado de las preguntas de unidad'; end if;
  v_unidad := substr(v_funcion, v_inicio);
  if strpos(v_unidad, v_despues) > 0 then return; end if;
  if length(v_unidad) - length(replace(v_unidad, v_antes, '')) <> length(v_antes) then
    raise exception 'Ha cambiado la comprobación del régimen de las preguntas de unidad';
  end if;
  v_unidad := replace(v_unidad, v_antes, v_despues);
  execute left(v_funcion, v_inicio - 1) || v_unidad;
end;
$guardado$;

do $preguntas$
declare
  v_arquitectura uuid;
  v_asonante uuid;
  v_anterior public.grupos_eleccion_metrica%rowtype;
  v_numero integer;
begin
  select a.arquitectura_id into strict v_arquitectura
  from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
  where f.slug = 'seguidilla' and a.slug = 'compuesta' and f.activo and a.activo;

  select termino_id into strict v_asonante
  from public.vocabularios where categoria = 'tipo_rima' and termino = 'asonante' and activo;

  select g.* into strict v_anterior
  from public.grupos_eleccion_metrica g join public.rasgos_metricos r using (rasgo_id)
  where g.arquitectura_id = v_arquitectura and r.slug = 'vocales_asonancia'
    and g.slug = 'vocales_asonancia' and g.dimension = 'rasgo' and g.alcance = 'secuencia'
    and g.seccion_tratada_id is null and g.seccion_id is null;

  if exists (
    select 1 from public.anotacion_elecciones e
    join public.anotaciones_metricas a using (anotacion_id)
    join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
    where a.arquitectura_id = v_arquitectura and rv.rasgo_id = v_anterior.rasgo_id
      and e.seccion_tratada_id is null
  ) then
    raise exception 'Hay seguidillas compuestas con una asonancia sin sección por revisar';
  end if;

  insert into public.grupos_eleccion_metrica
    (arquitectura_id, slug, dimension, alcance, seccion_tratada_id, tipo_control, rasgo_id,
      selecciones_min, selecciones_max, orden, activo, solo_si_tipo_rima_id)
  select v_arquitectura, p.slug, 'rasgo', 'unidad', s.seccion_id, 'opciones', v_anterior.rasgo_id,
    1, 1, p.orden, true, p.condicion
  from (values
    ('seguidilla_simple', 'asonancia_cuarteta', 2, v_asonante),
    ('estribillo', 'asonancia_bordon', 3, null::uuid)
  ) p(seccion, slug, orden, condicion)
  join public.estructuras_secciones s on s.arquitectura_id = v_arquitectura and s.slug = p.seccion
  on conflict (arquitectura_id, slug) do nothing;

  update public.grupos_eleccion_metrica
  set activo = false where grupo_eleccion_id = v_anterior.grupo_eleccion_id and activo;

  select count(*) into v_numero
  from public.preguntas_metricas
  where arquitectura_id = v_arquitectura and rasgo_id = v_anterior.rasgo_id and activo
    and alcance = 'unidad' and seccion_id is null and seccion_tratada_id is not null
    and ((slug = 'asonancia_bordon' and solo_si_tipo_rima_id is null)
      or (slug = 'asonancia_cuarteta' and solo_si_tipo_rima_id = v_asonante));
  if v_numero <> 2 then raise exception 'La seguidilla compuesta debe tener dos preguntas de asonancia'; end if;
end;
$preguntas$;

commit;
