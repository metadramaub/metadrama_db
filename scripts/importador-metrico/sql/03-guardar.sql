-- BORRADOR LOCAL. Crea obras nuevas; no reimporta ni sobrescribe una obra existente.
begin;
create or replace function public.comprobar_destino_minimo(p_destino jsonb) returns void
language plpgsql stable security definer set search_path = '' as $$
declare v_forma uuid;
begin
  if p_destino is null or p_destino='null'::jsonb then return; end if;
  select forma_id into v_forma from public.formas_metricas
    where slug=p_destino->>'forma_slug' and activo;
  if v_forma is null then raise exception using errcode='23514',message='Forma desconocida o inactiva'; end if;
  if p_destino->>'arquitectura_slug' is not null and not exists (
    select 1 from public.arquitecturas_forma a where a.forma_id=v_forma and a.activo
      and a.slug=p_destino->>'arquitectura_slug') then
    raise exception using errcode='23514',message='Arquitectura ajena a la forma, desconocida o inactiva';
  end if;
end;
$$;
revoke all on function public.comprobar_destino_minimo(jsonb) from public,anon,authenticated;

create or replace function public.guardar_ficha_minima(
  p_peticion uuid,p_autor uuid,p_datos jsonb,p_entrada_original jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
<<importar>>
declare
  v_actor uuid:=auth.uid(); v_obra uuid:=gen_random_uuid(); v_importacion uuid:=gen_random_uuid();
  v_grupo uuid:=gen_random_uuid(); v_atribucion uuid:=gen_random_uuid(); v_secuencia uuid;
  v_anterior public.importaciones_metricas%rowtype;
  v_genero uuid; v_borrador uuid; v_tradicional uuid; v_unica uuid; v_individual uuid;
  v_meta jsonb; v_fila jsonb; v_candidata jsonb; v_detalle jsonb; v_desviacion jsonb;
  v_forma uuid; v_arquitectura uuid; v_inicio integer; v_fin integer;
  v_prev integer; v_num integer; v_total bigint:=0; v_ahora timestamptz:=now();
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede importar métrica';
  end if;
  if p_peticion is null or p_autor is null or p_datos is null or p_entrada_original is null
    or jsonb_typeof(p_entrada_original)<>'object' or pg_column_size(p_entrada_original)>10485760
    or pg_column_size(p_datos)>10485760 then
    raise exception using errcode='22023',message='Petición incompleta o documento demasiado grande';
  end if;
  -- La misma clave se serializa incluso entre dos transacciones simultáneas.
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text||':'||p_peticion::text,0));
  select * into v_anterior from public.importaciones_metricas
    where importado_por=v_actor and peticion_id=p_peticion;
  if found then
    if v_anterior.datos_confirmados is distinct from p_datos or v_anterior.autor_id<>p_autor
      or v_anterior.entrada_original is distinct from p_entrada_original then
      raise exception using errcode='23505',message='La petición ya se usó con otros datos';
    end if;
    return jsonb_build_object('obra_id',v_anterior.obra_id,'importacion_id',v_anterior.importacion_id,'repetida',true);
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos) then
    raise exception using errcode='23514',message='El documento no cumple el contrato de ficha mínima';
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_extraccion_minima(),p_entrada_original)
    or (p_entrada_original->>'obra_ref') is distinct from (p_datos->>'obra_ref') then
    raise exception using errcode='23514',message='Falta la extracción original de esta obra';
  end if;
  v_meta:=p_datos->'metadatos';
  if btrim(v_meta->>'titulo')='' or btrim(v_meta->>'edicion_base')='' then
    raise exception using errcode='23514',message='Título y edición no pueden estar vacíos';
  end if;
  if not exists (select 1 from public.autores where autor_id=p_autor
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
  if (v_meta->>'fecha_inicio')::integer>(v_meta->>'fecha_fin')::integer then
    raise exception using errcode='23514',message='Fechas invertidas';
  end if;
  -- Evita doble clic con otra clave: no decide que dos títulos parecidos sean la misma obra.
  perform pg_advisory_xact_lock(hashtextextended(p_autor::text||':'||lower(btrim(v_meta->>'titulo')),1));
  if exists (select 1 from public.obras o join public.atribuciones a on a.obra_id=o.obra_id
    join public.atribucion_autores aa on aa.atribucion_id=a.atribucion_id
    where aa.autor_id=p_autor and lower(btrim(o.titulo))=lower(btrim(v_meta->>'titulo'))) then
    raise exception using errcode='23505',message='Ya existe ese título para el autor; revisar antes de importar';
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

  insert into public.obras(obra_id,titulo,estado,tipo_ficha,visible_publico,genero_id,
    edicion,fecha_inicio_trad,fecha_fin_trad,fuente_fecha,observaciones)
  values(v_obra,v_meta->>'titulo',v_borrador,'minima',false,v_genero,v_meta->>'edicion_base',
    (v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha',
    (select string_agg(value,E'\n' order by ord) from jsonb_array_elements_text(v_meta->'observaciones') with ordinality as o(value,ord)));
  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id) values(v_grupo,v_obra);
  insert into public.atribuciones(atribucion_id,obra_id,grupo_atribucion_id,tipo_atribucion_id,
    modalidad_atribucion_id,composicion_autoria_id,perfil_metrico,fuente_autoria)
  values(v_atribucion,v_obra,v_grupo,v_tradicional,v_unica,v_individual,true,v_meta->>'fundamento_autoria');
  insert into public.atribucion_autores(atribucion_id,autor_id,orden) values(v_atribucion,p_autor,1);
  insert into public.atribucion_evidencias(atribucion_id,tipo_atribucion_id,fuente_autoria,orden)
    values(v_atribucion,v_tradicional,v_meta->>'fundamento_autoria',1);
  insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin)
    select v_obra,(j->>'numero')::integer,(j->>'v_ini')::integer,(j->>'v_fin')::integer
    from jsonb_array_elements(p_datos->'jornadas') as r(j);
  insert into public.importaciones_metricas(importacion_id,obra_id,peticion_id,importado_por,
    confirmado_por,importado_en,confirmado_en,autor_id,genero_id,entrada_original,datos_confirmados,sha256_jsonb)
  values(v_importacion,v_obra,p_peticion,v_actor,v_actor,v_ahora,v_ahora,p_autor,v_genero,
    p_entrada_original,p_datos,encode(extensions.digest(convert_to(p_datos::text,'UTF8'),'sha256'),'hex'));

  v_prev:=null;
  for v_fila in select value from jsonb_array_elements(p_datos->'segmentos') loop
    v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if v_fin<v_inicio or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) or not exists (
      select 1 from public.jornadas j where j.obra_id=v_obra and v_inicio>=j.v_ini
        and importar.v_fin<=j.v_fin) then
      raise exception using errcode='23514',message='Segmentos discontinuos, invertidos o fuera de jornada';
    end if;
    v_prev:=v_fin; v_total:=v_total+v_fin::bigint-v_inicio+1;
    if not exists (select 1 from jsonb_array_elements(p_entrada_original->'tramos') as r(t)
      where t->>'id'=v_fila#>>'{origen,tramo_ref}' and t->>'fuente_id'=v_fila#>>'{origen,fuente_id}'
        and (t->>'denominacion_literal') is not distinct from (v_fila#>>'{origen,denominacion_literal}')
        and (t->>'v_ini')::integer<=v_inicio and (t->>'v_fin')::integer>=importar.v_fin) then
      raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
    end if;
    if exists (select 1 from jsonb_array_elements_text(v_fila#>'{origen,notas_ref}') as r(ref)
      where not exists (select 1 from jsonb_array_elements(p_entrada_original->'notas') as n(nota)
        where nota->>'id'=ref and nota->'tramos_ref' ? (v_fila#>>'{origen,tramo_ref}'))) then
      raise exception using errcode='23514',message='Nota sin correspondencia con el tramo original';
    end if;
    perform public.comprobar_destino_minimo(v_fila->'identificacion_revisada');
    perform public.comprobar_destino_minimo(v_fila->'propuesta');
    v_forma:=null; v_arquitectura:=null;
    if v_fila->'identificacion_revisada'<>'null'::jsonb then
      select forma_id into v_forma from public.formas_metricas where slug=v_fila#>>'{identificacion_revisada,forma_slug}';
      select arquitectura_id into v_arquitectura from public.arquitecturas_forma where forma_id=v_forma
        and slug=v_fila#>>'{identificacion_revisada,arquitectura_slug}';
    end if;
    if (v_forma is null)<>(v_fila->'aprobacion'='null'::jsonb) or
      (v_forma is not null and v_fila->'propuesta'<>'null'::jsonb) or
      (v_arquitectura is not null and jsonb_array_length(v_fila->'candidatas')>0) then
      raise exception using errcode='23514',message='Identificación, aprobación y propuestas incoherentes';
    end if;
    if jsonb_array_length(v_fila->'candidatas')=0 and v_fila->>'exhaustividad' is not null then
      raise exception using errcode='23514',message='Exhaustividad sin candidatas';
    end if;
    if (select count(*)<>count(distinct value) from jsonb_array_elements(v_fila->'candidatas')) then
      raise exception using errcode='23514',message='Candidatas repetidas';
    end if;
    for v_candidata in select value from jsonb_array_elements(v_fila->'candidatas') loop
      perform public.comprobar_destino_minimo(v_candidata);
      if v_forma is not null and ((v_candidata->>'forma_slug') is distinct from
        (v_fila#>>'{identificacion_revisada,forma_slug}') or v_candidata->>'arquitectura_slug' is null) then
        raise exception using errcode='23514',message='Candidata incompatible con la forma identificada';
      end if;
    end loop;
    for v_detalle in select value from jsonb_array_elements(v_fila->'detalles_fuente') loop
      if v_detalle->>'estado'='interpretacion_revisada' and (
        (v_detalle->>'n_versos')::integer>v_fin::bigint-v_inicio+1 or v_forma is null or not exists (
          select 1 from public.estructuras_secciones s join public.arquitecturas_forma a using(arquitectura_id)
          where a.forma_id=v_forma and a.activo and s.tipo_seccion=v_detalle->>'tipo_seccion'
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Detalle revisado sin contexto de catálogo o fuera del pasaje';
      end if;
    end loop;
    for v_desviacion in select value from jsonb_array_elements(v_fila->'desviaciones') loop
      if (v_desviacion->>'v_ini')::integer<v_inicio or (v_desviacion->>'v_fin')::integer>v_fin
        or (v_desviacion->>'v_fin')::integer<(v_desviacion->>'v_ini')::integer
        or not (v_fila#>'{origen,notas_ref}' ? (v_desviacion->>'nota_ref'))
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
      arquitectura_id,segmentacion,segmento_original)
    values(v_secuencia,v_importacion,v_fila->>'ref',v_forma,v_arquitectura,v_fila->>'segmentacion',v_fila);
  end loop;
  update public.obras set total_versos=v_total::integer where obra_id=v_obra;
  return jsonb_build_object('obra_id',v_obra,'importacion_id',v_importacion,'repetida',false);
end;
$$;
revoke all on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb) from public,anon;
grant execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb) to authenticated;
commit;
