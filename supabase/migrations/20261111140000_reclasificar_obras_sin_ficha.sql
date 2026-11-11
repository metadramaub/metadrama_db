-- Registros de planificación que el modelo anterior clasificaba como completas.
-- Selección fija cotejada el 11 de noviembre de 2026. Se aborta si alguno ha
-- recibido trabajo editorial desde el cotejo. El registro común sigue intacto.
do $$
declare
  obras_planificadas constant uuid[] := array[
    'd088d03c-fb01-4652-92dc-322abeb1e4f7', -- Abre el ojo
    '6c553125-7401-4523-92b4-3e22905d8718', -- Casa con dos puertas, mala es de guardar
    'c62b1846-491d-43de-bda8-3670058f8302', -- Del rey abajo, ninguno
    '2a90522f-18f3-4c4f-90cd-47de85c120b6', -- Dido y Eneas (Cristóbal de Morales)
    'ce96f67a-3bde-4d59-9ab3-79b94561917f', -- El alcalde de Zalamea
    '989ecdda-65b7-4143-861d-9804ceddec48', -- El anzuelo de Fenisa
    'b9933d48-6211-40a9-b4d7-b08f61f917f0', -- El caballero de Olmedo (Burlesca)
    'f883797e-1e1d-45f2-aaf0-59d8650dc1b5', -- El cerco de Numancia
    '01253ad5-3500-4343-ac5d-2d04f93c5472', -- El conde Alarcos
    '32288743-1287-4d5b-85a4-341f48395de4', -- El galán Castrucho
    '93eb0796-990f-4b14-ad56-22acf93a3a95', -- El gran teatro del mundo
    '6368ea89-4bd6-42b5-9ff4-592152cb9420', -- El lacayo fingido
    'b4f436fe-a12b-4e2c-bce7-ce20f85a4867', -- El mejor alcalde, el rey
    '62230d8a-21ee-4f92-af76-0724d14dc053', -- El perro del hortelano
    '7e4fb84e-6947-4c99-a2c1-bf1002a25d57', -- El príncipe constante
    '0199d561-5fd4-474f-94c7-22c023222577', -- El villano en su rincón
    '408b5d78-9220-4b2d-8a65-72b80b40ec09', -- Entre bobos anda el juego
    'eae802d8-b6b2-448a-85e5-7e84ce6343e4', -- La dama boba
    '61c478c3-16df-4cca-925c-97b453a46de1', -- La dama duende
    '34cee1b2-254b-46d3-bf7e-1d44892b71a3', -- La Estrella de Sevilla
    '22f9c93b-a2a2-45f6-8696-9fc6c3c983ad', -- La hija del aire (I parte)
    '7db4214e-634a-4dd7-9724-927e4acb2bde', -- La hija del aire (II parte)
    '1be06dd9-a4fa-47ea-b61d-9ab3b5907e88', -- La honestidad defendida de Elisa Dido
    '1f8e51dc-7c51-4fc8-811d-301f58edda3f', -- La serrana de la Vera
    '81cadcc7-23db-4476-b333-2d73bb20d6e1', -- La verdad sospechosa
    'a371c9c4-aaec-4ada-9979-3bd4d1b8ed86', -- La viuda valenciana
    '0ec4e592-4863-4eea-94ec-c953a8650f57', -- Las bizarrías de Belisa
    '4d2c6164-7274-4de4-a6ad-5a03b926354f', -- Las lágrimas de David
    'c3c79146-990f-43e1-b0ab-9af33c2e3bcb', -- Las mocedades del Cid (I parte)
    'aa83a9b1-f09d-48b3-a781-78c20f7bc3ea', -- Las mocedades del Cid (II parte)
    'e9c23c19-ab5c-46c7-88ab-4c437cfb0036', -- Las muñecas de Marcela
    'cd8dfc16-498b-4b1d-b664-ed6f88d67898', -- Las paredes oyen
    'f55b10d5-7290-4927-806c-cea1d61e356e', -- Lo que son mujeres
    '10dab489-0d90-4cad-86ab-b7759458506d', -- Los amantes
    '6cdb64f7-fc12-4400-8193-58998a7fcaff', -- Los cabellos de Absalón
    'a9a9951e-76f6-4dd7-aa0b-29ad7d0917e6', -- No hay burlas con el amor
    '01fa05b4-ea80-4dab-913e-ee3037efb871', -- Peribáñez y el Comendador de Ocaña
    '2a28cd29-6259-4bc0-8432-43d4abf056b3' -- Reinar después de morir
  ]::uuid[];
  borrador_id uuid;
  obra_con_trabajo uuid;
  fichas_encontradas integer;
begin
  perform set_config('lock_timeout', '3s', true);
  select termino_id into strict borrador_id
    from public.vocabularios where categoria = 'estado' and termino = 'borrador';

  perform 1 from public.obras where obra_id = any(obras_planificadas) order by obra_id for update;
  perform 1 from public.fichas_completas where obra_id = any(obras_planificadas) order by obra_id for update;
  select count(*) into fichas_encontradas
    from public.fichas_completas where obra_id = any(obras_planificadas);
  if fichas_encontradas not in (0, cardinality(obras_planificadas)) then
    raise exception 'Se esperaban % fichas completas de planificación y se encontraron %.',
      cardinality(obras_planificadas), fichas_encontradas;
  end if;

  select f.obra_id into obra_con_trabajo
    from public.fichas_completas f
    where f.obra_id = any(obras_planificadas) and (
      f.procedencia_registro <> 'legado'
      or f.editor_asignado is not null
      or f.fecha_asignacion is not null
      or f.inicio_elaboracion is not null
      or nullif(btrim(f.edicion_base), '') is not null
      or nullif(btrim(f.bibliografia), '') is not null
      or nullif(btrim(f.observaciones), '') is not null
      or f.sin_figuras_donaire or f.sin_personajes_sobrenaturales or f.sin_eventos_sobrenaturales
      or f.estado is distinct from borrador_id or f.visible_publico
      or f.fecha_cambio_estado is not null or f.fecha_publicacion is not null
      or f.autor_ficha_publico is not null
      or exists (select 1 from public.obras_revisores t where t.obra_id = f.obra_id)
      or exists (select 1 from public.asignaciones_historial t where t.obra_id = f.obra_id)
      or exists (select 1 from public.comentarios_internos t where t.obra_id = f.obra_id)
      or exists (select 1 from public.importaciones_metricas t where t.obra_id = f.obra_id)
      or exists (select 1 from public.jornadas t where t.obra_id = f.obra_id)
      or exists (select 1 from public.secuencias_metricas t where t.obra_id = f.obra_id)
      or exists (select 1 from public.migracion_secuencias t where t.obra_id = f.obra_id)
      or exists (select 1 from public.propuesta_metrica_secuencia t where t.obra_id = f.obra_id)
      or exists (select 1 from public.traslados_observaciones_caracterizacion t where t.obra_id = f.obra_id)
      or exists (select 1 from public.obras_resumen t where t.obra_id = f.obra_id and t.ficha is not null)
      or exists (select 1 from public.artefactos_publicos t where t.clave = 'obras/' || f.obra_id || '/ficha/publico.json')
    ) limit 1;
  if obra_con_trabajo is not null then
    raise exception 'La obra % tiene actividad editorial. No se reclasificó ninguna ficha.', obra_con_trabajo;
  end if;

  delete from public.fichas_completas where obra_id = any(obras_planificadas);

  if exists (
    select 1 from public.obras_editoriales o
    where o.obra_id = any(obras_planificadas) and o.tipo_ficha <> 'sin_ficha'
  ) then
    raise exception 'Una obra planificada conserva un tipo de ficha. Se revierte la reclasificación.';
  end if;
end
$$;
