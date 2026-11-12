-- La básica admite datación abierta y puede tomar la autoría de la obra existente.
alter table public.importaciones_metricas alter column autor_id drop not null;

create or replace function public.esquema_documento_minimo() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-ficha-minima/0.2"},"obra_ref":{"type":"string","minLength":1},"metadatos":{"type":"object","properties":{"titulo":{"type":"string","minLength":1},"autor_nombre":{"type":"string"},"genero":{"type":"string","minLength":1},"edicion_base":{"type":"string","minLength":1},"fecha_inicio":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"fecha_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"inicio_inclusivo":{"type":"boolean"},"fin_inclusivo":{"type":"boolean"},"fecha_aproximada":{"type":"boolean"},"variantes_titulo":{"type":"array","items":{"type":"string","minLength":1}},"propuestas_autoria":{"type":"array","items":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}}},"fuente_fecha":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fundamento_autoria":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","minLength":1}}},"required":["titulo","autor_nombre","genero","edicion_base","fecha_inicio","fecha_fin","fuente_fecha","fundamento_autoria","observaciones"],"additionalProperties":false},"jornadas":{"minItems":1,"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"rotulo_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["numero","v_ini","v_fin","rotulo_literal"],"additionalProperties":false}},"segmentos":{"minItems":1,"type":"array","items":{"type":"object","properties":{"ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"segmentacion":{"type":"string","enum":["provisional","confirmada"]},"origen":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"denominacion_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fuente_id":{"type":"string","minLength":1},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","minLength":1}},"tramos_ref":{"minItems":2,"type":"array","items":{"type":"string","minLength":1}}},"required":["tramo_ref","denominacion_literal","fuente_id","pagina","notas_ref"],"additionalProperties":false},"identificacion":{"anyOf":[{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false},{"type":"null"}]},"candidatas":{"type":"array","items":{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false}},"regla_id":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"detalles_fuente":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"estructura"},"tipo_seccion":{"type":"string","const":"remate"},"nombre":{"type":"string","minLength":1},"n_versos":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"posicion":{"type":"string","const":"final"}},"required":["literal","dimension","tipo_seccion","nombre","n_versos","posicion"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"rasgo_slug":{"type":"string","minLength":1},"valor_slug":{"type":"string","minLength":1}},"required":["rasgo_slug","valor_slug"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"asonancia"}},"required":["literal"],"additionalProperties":false}]}},"desviaciones":{"type":"array","items":{"type":"object","properties":{"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"dimension":{"type":"string","enum":["metro","estructura"]},"relacion_norma":{"type":"string","enum":["menor_que_norma","mayor_que_norma","sobra","falta","otra"]},"metro_observado_slug":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"texto_fuente":{"type":"string","minLength":1},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["v_ini","v_fin","dimension","relacion_norma","nota_ref","texto_fuente","nota"],"additionalProperties":false}},"caracterizaciones":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"termino":{"type":"string","const":"prosa"},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"tramo_ref":{"type":"string","minLength":1},"literal":{"type":"string","minLength":1}},"required":["termino","v_ini","v_fin","tramo_ref","literal"],"additionalProperties":false},{"type":"object","properties":{"termino":{"type":"string","const":"cantado"},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"tramo_ref":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"literal":{"type":"string","minLength":1}},"required":["termino","v_ini","v_fin","tramo_ref","nota_ref","literal"],"additionalProperties":false}]}}},"required":["ref","v_ini","v_fin","segmentacion","origen","identificacion","candidatas","regla_id","nota","detalles_fuente","desviaciones"],"additionalProperties":false}},"comprobacion":{"type":"object","properties":{"avisos_longitud":{"type":"array","items":{"type":"object","properties":{"segmento_ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"mensaje":{"type":"string","minLength":1}},"required":["segmento_ref","v_ini","v_fin","mensaje"],"additionalProperties":false}}},"required":["avisos_longitud"],"additionalProperties":false},"numeracion":{"type":"object","properties":{"tipo":{"type":"string","const":"por_jornada"},"desplazamientos":{"minItems":2,"type":"array","items":{"type":"object","properties":{"jornada":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"desplazamiento":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["jornada","desplazamiento"],"additionalProperties":false}}},"required":["tipo","desplazamientos"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"reglas_version":{"type":"string","minLength":1},"catalogo_revision":{"type":"integer","minimum":0,"maximum":9007199254740991},"extraccion_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},"entradas_sha256":{"type":"object","propertyNames":{"type":"string","minLength":1},"additionalProperties":{"type":"string","pattern":"^[a-f0-9]{64}$"}},"ejecucion":{"type":"object","properties":{"generador":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]}},"required":["generador","modelo","prompt_version"],"additionalProperties":false}},"required":["reglas_version","catalogo_revision","extraccion_sha256","entradas_sha256"],"additionalProperties":false}},"required":["esquema","obra_ref","metadatos","jornadas","segmentos","procedencia"],"additionalProperties":false}$schema$::json;
$func$;

CREATE OR REPLACE FUNCTION public.guardar_ficha_basica(p_peticion uuid, p_autor uuid, p_datos jsonb, p_entrada_original jsonb, p_coincidencias_revisadas uuid[] DEFAULT '{}'::uuid[], p_obra uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
<<importar>>
declare
  v_actor uuid:=auth.uid(); v_obra uuid:=coalesce(p_obra,gen_random_uuid()); v_importacion uuid:=gen_random_uuid();
  v_grupo uuid:=gen_random_uuid(); v_atribucion uuid:=gen_random_uuid(); v_secuencia uuid;
  v_anterior public.importaciones_metricas%rowtype;
  v_genero uuid; v_borrador uuid; v_tradicional uuid; v_unica uuid; v_individual uuid;
  v_meta jsonb; v_fila jsonb; v_candidata jsonb; v_detalle jsonb; v_desviacion jsonb;
  v_forma uuid; v_arquitectura uuid; v_inicio integer; v_fin integer;
  v_prev integer; v_num integer; v_total bigint:=0; v_ahora timestamptz:=now();
  v_revisadas uuid[]; v_coincidencias uuid[]; v_desplazamientos jsonb;
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede importar métrica';
  end if;
  if p_peticion is null or (p_autor is null and not (
    public.auth_is_admin_or_ip() and (p_obra is not null or p_datos#>'{metadatos,propuestas_autoria}' is not null)
  ))
    or p_datos is null or p_entrada_original is null
    or jsonb_typeof(p_entrada_original)<>'object' or pg_column_size(p_entrada_original)>10485760
    or pg_column_size(p_datos)>10485760 then
    raise exception using errcode='22023',message='Petición incompleta o documento demasiado grande';
  end if;
  select coalesce(array_agg(distinct id order by id),array[]::uuid[]) into v_revisadas
    from unnest(coalesce(p_coincidencias_revisadas,array[]::uuid[])) ids(id) where id is not null;
  -- La misma clave se serializa incluso entre dos transacciones simultáneas.
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text||':'||p_peticion::text,0));
  select * into v_anterior from public.importaciones_metricas
    where importado_por=v_actor and peticion_id=p_peticion;
  if found then
    if (p_obra is not null and v_anterior.obra_id<>p_obra) or v_anterior.datos_confirmados is distinct from p_datos
      or v_anterior.autor_id is distinct from p_autor
      or v_anterior.entrada_original is distinct from p_entrada_original
      or v_anterior.coincidencias_revisadas is distinct from v_revisadas then
      raise exception using errcode='23505',message='La petición ya se usó con otros datos';
    end if;
    return jsonb_build_object('obra_id',v_anterior.obra_id,'importacion_id',v_anterior.importacion_id,'repetida',true);
  end if;
  if p_obra is not null then
    perform 1 from public.obras where obra_id=p_obra for update;
    if not found then raise exception 'Obra de destino no encontrada' using errcode='P0002'; end if;
    if exists(select 1 from public.fichas_completas where obra_id=p_obra)
      or exists(select 1 from public.importaciones_metricas where obra_id=p_obra)
      or exists(select 1 from public.secuencias_metricas where obra_id=p_obra)
      or exists(select 1 from public.jornadas where obra_id=p_obra) then
      raise exception 'La obra ya tiene ficha o estructura; no se sobrescribe' using errcode='23514';
    end if;
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos) then
    raise exception using errcode='23514',message='El documento no cumple el contrato de ficha mínima';
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_extraccion_minima(),p_entrada_original)
    or (p_entrada_original->>'obra_ref') is distinct from (p_datos->>'obra_ref') then
    raise exception using errcode='23514',message='Falta la extracción original de esta obra';
  end if;
  -- Ediciones que numeran cada jornada desde 1: desplazamientos recalculados desde el original.
  v_desplazamientos:=public.comprobar_numeracion_minima(p_datos,p_entrada_original);
  v_meta:=p_datos->'metadatos';
  if (v_meta ? 'propuestas_autoria' or v_meta ? 'variantes_titulo')
    and (p_obra is not null or p_autor is not null or not public.auth_is_admin_or_ip()) then
    raise exception 'Los metadatos del borrador solo se pueden guardar al crear una obra' using errcode='42501';
  end if;
  if btrim(v_meta->>'titulo')='' or btrim(v_meta->>'edicion_base')='' then
    raise exception using errcode='23514',message='Título y edición no pueden estar vacíos';
  end if;
  if p_autor is not null and not exists (select 1 from public.autores where autor_id=p_autor
    and btrim(nombre_completo)=btrim(v_meta->>'autor_nombre')) then
    raise exception using errcode='23514',message='Selecciona un autor del catálogo y su nombre vigente';
  end if;
  select termino_id into v_genero from public.vocabularios
    where categoria='genero' and termino=v_meta->>'genero' and coalesce(activo,true);
  select termino_id into v_borrador from public.vocabularios where categoria='estado' and termino='borrador';
  select termino_id into v_tradicional from public.vocabularios where categoria='tipo_atribucion' and termino='tradicional';
  select termino_id into v_unica from public.vocabularios where categoria='modalidad_atribucion' and termino='unica';
  select termino_id into v_individual from public.vocabularios where categoria='composicion_autoria' and termino='individual';
  if v_genero is null or v_borrador is null or v_tradicional is null or v_unica is null or v_individual is null then
    raise exception using errcode='23514',message='Faltan referencias del vocabulario';
  end if;
  if (v_meta->>'fecha_inicio')::integer + (case when (v_meta->>'inicio_inclusivo')::boolean is false then 1 else 0 end)
    > (v_meta->>'fecha_fin')::integer - (case when (v_meta->>'fin_inclusivo')::boolean is false then 1 else 0 end) then
    raise exception using errcode='23514',message='Fechas invertidas';
  end if;
  -- Un título coincidente pide revisión; no impone identidad, ni siquiera con el mismo autor.
  perform pg_advisory_xact_lock(hashtextextended(public.normalizar_titulo_importacion(v_meta->>'titulo'),1));
  select coalesce(array_agg(c.obra_id order by c.obra_id),array[]::uuid[]) into v_coincidencias
    from public.coincidencias_importacion_metrica(v_meta->>'titulo') c;
  if v_coincidencias is distinct from v_revisadas then
    raise exception using errcode='23505',message='Revisa las coincidencias antes de confirmar que se trata de otra obra';
  end if;
  v_prev:=null; v_num:=0;
  for v_fila in select value from jsonb_array_elements(p_datos->'jornadas') loop
    v_num:=v_num+1; v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if (v_fila->>'numero')::integer<>v_num or v_fin<v_inicio
      or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) then
      raise exception using errcode='23514',message='Jornadas desordenadas, discontinuas o con rangos invertidos';
    end if;
    v_prev:=v_fin;
  end loop;
  if (p_datos#>>'{segmentos,0,v_ini}')::integer<>(p_datos#>>'{jornadas,0,v_ini}')::integer or
    (p_datos->'segmentos'->-1->>'v_fin')::integer<>v_prev then
    raise exception using errcode='23514',message='Jornadas y segmentos no cubren el mismo rango';
  end if;
  if (select count(*)<>count(distinct value->>'ref') from jsonb_array_elements(p_datos->'segmentos')) then
    raise exception using errcode='23514',message='Referencias de segmento repetidas';
  end if;

  if p_obra is null then
  insert into public.obras_editoriales(obra_id,titulo,estado,tipo_ficha,visible_publico,genero_id,
    edicion,observaciones,variantes_titulo)
  values(v_obra,v_meta->>'titulo',v_borrador,'basica',false,v_genero,v_meta->>'edicion_base',
    (select string_agg(value,E'\n' order by ord) from jsonb_array_elements_text(v_meta->'observaciones') with ordinality as o(value,ord)),
    array(select jsonb_array_elements_text(v_meta->'variantes_titulo')));
  else
    update public.obras set genero_id=coalesce(genero_id,v_genero) where obra_id=p_obra;
  end if;
  insert into public.obras_dataciones(obra_id,clase,inicio,fin,fuente,inicio_inclusivo,fin_inclusivo,aproximada)
  select v_obra,'referencia',(v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha',
    coalesce((v_meta->>'inicio_inclusivo')::boolean,true),
    coalesce((v_meta->>'fin_inclusivo')::boolean,true),
    coalesce((v_meta->>'fecha_aproximada')::boolean,false)
    where (v_meta->>'fecha_inicio' is not null or v_meta->>'fecha_fin' is not null or nullif(v_meta->>'fuente_fecha','') is not null)
    on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
      fuente=coalesce(obras_dataciones.fuente,excluded.fuente),
      inicio_inclusivo=excluded.inicio_inclusivo,fin_inclusivo=excluded.fin_inclusivo,
      aproximada=excluded.aproximada
    where obras_dataciones.inicio is null and obras_dataciones.fin is null;
  if p_autor is not null and not exists(select 1 from public.atribuciones where obra_id=v_obra) then
  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id) values(v_grupo,v_obra);
  insert into public.atribuciones(atribucion_id,obra_id,grupo_atribucion_id,tipo_atribucion_id,
    modalidad_atribucion_id,composicion_autoria_id,perfil_metrico,fuente_autoria)
  values(v_atribucion,v_obra,v_grupo,v_tradicional,v_unica,v_individual,true,v_meta->>'fundamento_autoria');
  insert into public.atribucion_autores(atribucion_id,autor_id,orden) values(v_atribucion,p_autor,1);
  insert into public.atribucion_evidencias(atribucion_id,tipo_atribucion_id,fuente_autoria,orden)
    values(v_atribucion,v_tradicional,v_meta->>'fundamento_autoria',1);
  end if;
  insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin)
    select v_obra,(j->>'numero')::integer,(j->>'v_ini')::integer,(j->>'v_fin')::integer
    from jsonb_array_elements(p_datos->'jornadas') as r(j);
  insert into public.importaciones_metricas(importacion_id,obra_id,peticion_id,importado_por,
    importado_en,autor_id,genero_id,entrada_original,datos_confirmados,sha256_jsonb,coincidencias_revisadas)
  values(v_importacion,v_obra,p_peticion,v_actor,v_ahora,p_autor,v_genero,
    p_entrada_original,p_datos,encode(extensions.digest(convert_to(p_datos::text,'UTF8'),'sha256'),'hex'),v_revisadas);
  if v_meta ? 'propuestas_autoria' then
    perform public.guardar_autoria_global_previa(v_obra, v_meta->'propuestas_autoria');
  end if;

  v_prev:=null;
  for v_fila in select value from jsonb_array_elements(p_datos->'segmentos') loop
    v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if v_fin<v_inicio or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) or not exists (
      select 1 from public.jornadas j where j.obra_id=v_obra and v_inicio>=j.v_ini
        and importar.v_fin<=j.v_fin) then
      raise exception using errcode='23514',message='Segmentos discontinuos, invertidos o fuera de jornada';
    end if;
    v_prev:=v_fin; v_total:=v_total+v_fin::bigint-v_inicio+1;
    perform public.comprobar_origen_minimo(v_fila,p_entrada_original,v_desplazamientos);
    perform public.comprobar_destino_minimo(v_fila->'identificacion');
    v_forma:=null; v_arquitectura:=null;
    if v_fila->'identificacion'<>'null'::jsonb then
      select forma_id into v_forma from public.formas_metricas where slug=v_fila#>>'{identificacion,forma_slug}';
      select arquitectura_id into v_arquitectura from public.arquitecturas_forma where forma_id=v_forma
        and slug=v_fila#>>'{identificacion,arquitectura_slug}';
    end if;
    if v_arquitectura is not null and jsonb_array_length(v_fila->'candidatas')>0 then
      raise exception using errcode='23514',message='Una arquitectura identificada no mantiene candidatas';
    end if;
    if (select count(*)<>count(distinct value) from jsonb_array_elements(v_fila->'candidatas')) then
      raise exception using errcode='23514',message='Candidatas repetidas';
    end if;
    for v_candidata in select value from jsonb_array_elements(v_fila->'candidatas') loop
      perform public.comprobar_destino_minimo(v_candidata);
      if v_forma is not null and ((v_candidata->>'forma_slug') is distinct from
        (v_fila#>>'{identificacion,forma_slug}') or v_candidata->>'arquitectura_slug' is null) then
        raise exception using errcode='23514',message='Candidata incompatible con la forma identificada';
      end if;
    end loop;
    for v_detalle in select value from jsonb_array_elements(v_fila->'detalles_fuente') loop
      if v_detalle ? 'rasgo_slug' and (v_forma is null or
        (v_detalle->>'rasgo_slug'='distico_final' and v_fin::bigint-v_inicio+1<2) or not exists (
          select 1 from public.rasgos_metricos r join public.rasgo_valores rv using(rasgo_id)
          join public.arquitectura_rasgos ar using(rasgo_id)
          join public.arquitecturas_forma a using(arquitectura_id)
          where r.slug=v_detalle->>'rasgo_slug' and rv.slug=v_detalle->>'valor_slug'
            and r.activo and rv.activo and a.activo and a.forma_id=v_forma
            and (ar.valor_id is null or ar.valor_id=rv.valor_id)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Rasgo o valor ajeno a la forma y arquitectura conocidas';
      end if;
      if v_detalle->>'tipo_seccion'='remate' and (
        (v_detalle->>'n_versos')::integer>v_fin::bigint-v_inicio+1 or v_forma is null or not exists (
          select 1 from public.estructuras_secciones s join public.arquitecturas_forma a using(arquitectura_id)
          where a.forma_id=v_forma and a.activo and s.tipo_seccion=v_detalle->>'tipo_seccion'
            and (s.versos_min is null or (v_detalle->>'n_versos')::integer>=s.versos_min)
            and (s.versos_max is null or (v_detalle->>'n_versos')::integer<=s.versos_max)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Detalle revisado sin contexto de catálogo o fuera del pasaje';
      end if;
    end loop;
    for v_desviacion in select value from jsonb_array_elements(v_fila->'desviaciones') loop
      if (v_desviacion->>'v_ini')::integer<v_inicio or (v_desviacion->>'v_fin')::integer>v_fin
        or (v_desviacion->>'v_fin')::integer<(v_desviacion->>'v_ini')::integer
        or not (v_fila#>'{origen,notas_ref}' ? (v_desviacion->>'nota_ref'))
        or not exists (select 1 from jsonb_array_elements(p_entrada_original->'notas') n
          where n->>'id'=v_desviacion->>'nota_ref'
            and n->>'texto_literal'=v_desviacion->>'texto_fuente')
        or (v_desviacion->>'dimension'='metro' and v_desviacion->>'relacion_norma' in ('sobra','falta'))
        or (v_desviacion->>'dimension'='estructura' and v_desviacion->>'relacion_norma' in ('menor_que_norma','mayor_que_norma'))
        or (v_desviacion->>'metro_observado_slug' is not null and not exists (
          select 1 from public.metros where slug=v_desviacion->>'metro_observado_slug' and activo)) then
        raise exception using errcode='23514',message='Desviación fuera del pasaje o sin referencia válida';
      end if;
    end loop;
    v_secuencia:=gen_random_uuid();
    insert into public.secuencias_metricas(secuencia_id,obra_id,v_ini,v_fin,n_versos)
      values(v_secuencia,v_obra,v_inicio,v_fin,v_fin-v_inicio+1);
    insert into public.metrica_minima_secuencias(secuencia_id,importacion_id,segmento_ref,forma_id,
      arquitectura_id,segmentacion,datos_minimos)
    values(v_secuencia,v_importacion,v_fila->>'ref',v_forma,v_arquitectura,v_fila->>'segmentacion',
      v_fila - array['ref','v_ini','v_fin','identificacion','segmentacion']);
  end loop;
  update public.obras_editoriales set total_versos=v_total::integer where obra_id=v_obra;
  return jsonb_build_object('obra_id',v_obra,'importacion_id',v_importacion,'repetida',false);
end;
$function$
;
