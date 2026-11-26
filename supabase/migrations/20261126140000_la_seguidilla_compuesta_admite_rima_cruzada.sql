-- El cuerpo y el bordón tienen rimas independientes. La rima de la cuarteta
-- admite la disposición habitual en asonante y la cruzada consonante.
begin;

do $seguidilla$
declare
  v_arquitectura uuid;
  v_cuerpo uuid;
  v_bordon uuid;
  v_asonante uuid;
  v_consonante uuid;
  v_grupo uuid;
  v_ficha jsonb;
  v_filas integer;
  v_fuente_anterior text := 'Presenta como norma simple 7-5-7-5 con asonancia en los pares, aunque recoge fluctuación métrica, consonancia y rima de los impares. La simple puede funcionar como estrofa o como poema; distingue asimismo la compuesta, la chamberga y la gitana.';
  v_fuente_nueva text := 'Describe la cuarteta habitual de heptasílabos y pentasílabos con asonancia en los pares. Entre sus modificaciones corrientes incluye la fluctuación de la medida, la rima consonante y la posibilidad de que rimen también los dos heptasílabos. La seguidilla puede constituir un poema o funcionar como estrofa. En la compuesta, la cuarteta va seguida de un bordón separado por la rima y el sentido: sus dos pentasílabos extremos riman en asonante y el heptasílabo central queda suelto. Distingue también la chamberga y la gitana.';
begin
  select termino_id into strict v_asonante
  from public.vocabularios where categoria = 'tipo_rima' and termino = 'asonante' and activo;

  select termino_id into strict v_consonante
  from public.vocabularios where categoria = 'tipo_rima' and termino = 'consonante' and activo;

  select a.arquitectura_id into strict v_arquitectura
  from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
  where f.slug = 'seguidilla' and f.activo and a.slug = 'compuesta' and a.activo
    and a.unidad_versos_min = 7 and a.unidad_versos_max = 7
    and (a.tipo_rima_id = v_asonante or a.tipo_rima_id is null);

  select seccion_id into strict v_cuerpo
  from public.estructuras_secciones
  where arquitectura_id = v_arquitectura and slug = 'seguidilla_simple'
    and versos_min = 4 and versos_max = 4 and arquitectura_referenciada_id is not null;

  select seccion_id into strict v_bordon
  from public.estructuras_secciones
  where arquitectura_id = v_arquitectura and slug = 'estribillo'
    and versos_min = 3 and versos_max = 3;

  if exists (
    select 1 from public.esquemas_rima
    where arquitectura_id = v_arquitectura and seccion_id is null
      and (slug, notacion, tipo_rima_id) is distinct from ('-a-ab-b', '-a-ab-b', v_asonante)
  ) then
    raise exception 'Ha cambiado el esquema general de la seguidilla compuesta';
  end if;

  if exists (
    select 1 from public.esquemas_rima r
    where r.arquitectura_id = v_arquitectura and r.slug = '-a-ab-b'
      and (exists (select 1 from public.afirmaciones_fuentes_metricas a where a.esquema_rima_id = r.esquema_rima_id)
        or exists (select 1 from public.denominaciones_metricas d where d.esquema_rima_id = r.esquema_rima_id))
  ) then
    raise exception 'El esquema general tiene fuentes o denominaciones que deben reasignarse';
  end if;

  delete from public.esquemas_rima
  where arquitectura_id = v_arquitectura and slug = '-a-ab-b' and seccion_id is null;

  update public.arquitecturas_forma
  set tipo_rima_id = null,
    descripcion = 'La cuarteta de la seguidilla se prolonga con un bordón de tres versos. La cuarteta puede rimar en asonante en los pares o presentar rima cruzada consonante. El bordón conserva su propia asonancia y se separa del cuerpo por la rima y por el sentido. La forma se documenta ya en el teatro áureo y se difunde a partir del siglo XVIII.'
  where arquitectura_id = v_arquitectura and tipo_rima_id = v_asonante;

  insert into public.esquemas_rima
    (arquitectura_id, seccion_id, slug, nombre, notacion, modalidad, tipo_rima_id, tipo_secuencia)
  values
    (v_arquitectura, v_cuerpo, 'cuerpo-asonante', 'Rima en los pares', '-a-a', 'habitual', v_asonante, 'secuencia'),
    (v_arquitectura, v_cuerpo, 'cuerpo-cruzado-consonante', 'Rima cruzada', 'abab', 'admitida', v_consonante, 'secuencia'),
    (v_arquitectura, v_bordon, 'bordon-asonante', null, 'a-a', 'definitoria', v_asonante, 'secuencia')
  on conflict (arquitectura_id, slug) do nothing;

  insert into public.esquema_rima_posiciones
    (esquema_rima_id, bloque, posicion, ubicacion, clase_rima, suelto)
  select r.esquema_rima_id, 1, p, 'final', nullif(substr(r.notacion, p, 1), '-'),
    substr(r.notacion, p, 1) = '-'
  from public.esquemas_rima r
  cross join lateral generate_series(1, length(r.notacion)) p
  where r.arquitectura_id = v_arquitectura
    and r.slug in ('cuerpo-asonante', 'cuerpo-cruzado-consonante', 'bordon-asonante')
  on conflict (esquema_rima_id, bloque, posicion, ubicacion) do nothing;

  insert into public.grupos_eleccion_metrica
    (arquitectura_id, slug, dimension, alcance, seccion_tratada_id, tipo_control,
      selecciones_min, selecciones_max, orden, activo)
  values
    (v_arquitectura, 'rima_cuarteta', 'rima', 'unidad', v_cuerpo, 'opciones_y_esquema', 1, 1, 1, true)
  on conflict (arquitectura_id, slug) do nothing;

  select grupo_eleccion_id into strict v_grupo
  from public.preguntas_metricas
  where arquitectura_id = v_arquitectura and slug = 'rima_cuarteta'
    and activo and dimension = 'rima' and alcance = 'unidad'
    and seccion_id is null and seccion_tratada_id = v_cuerpo
    and tipo_control = 'opciones_y_esquema' and selecciones_min = 1 and selecciones_max = 1;

  update public.afirmaciones_fuentes_metricas
  set resumen = v_fuente_nueva
  where afirmacion_id = 'f776aada-4def-45b1-add8-f711b9affc48'
    and fuente_id = '1f0765c9-3851-451b-9f63-55dbf9ac28fb'
    and localizador = 'pp. 192-195'
    and resumen in (v_fuente_anterior, v_fuente_nueva);
  get diagnostics v_filas = row_count;
  if v_filas <> 1 then
    raise exception 'Ha cambiado la afirmación de Métrica española sobre la seguidilla';
  end if;

  if (select array_agg(r.notacion order by r.notacion) from public.opciones_eleccion_metrica o
      join public.esquemas_rima r using (esquema_rima_id)
      where o.grupo_eleccion_id = v_grupo and o.activo)
    is distinct from array['-a-a', 'abab'] then
    raise exception 'La pregunta de la cuarteta debe ofrecer sus dos esquemas';
  end if;

  v_ficha := public.get_forma_metrica_publica_jerarquica('seguidilla');
  if (select count(*)
      from (values (v_cuerpo, '-a-a', v_asonante), (v_cuerpo, 'abab', v_consonante),
        (v_bordon, 'a-a', v_asonante)) as esperado(parte, notacion, regimen)
      where exists (
        select 1 from jsonb_array_elements(v_ficha->'esquemasRima') e
        where (e->>'seccion_id')::uuid = esperado.parte and e->>'notacion' = esperado.notacion
          and (e->>'tipo_rima_id')::uuid = esperado.regimen
      )) <> 3 then
    raise exception 'La ficha pública no recoge los esquemas y regímenes de las dos secciones';
  end if;
end;
$seguidilla$;

commit;
