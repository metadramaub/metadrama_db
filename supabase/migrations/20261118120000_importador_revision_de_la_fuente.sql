-- La copia editorial conserva las correcciones numéricas junto a su fila de origen.
-- El JSON original conserva la transcripción y permite cotejar el motivo y los valores.
create or replace function public.esquema_documento_minimo() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-ficha-minima/0.2"},"obra_ref":{"type":"string","minLength":1},"metadatos":{"type":"object","properties":{"titulo":{"type":"string","minLength":1},"autor_nombre":{"type":"string"},"genero":{"type":"string","minLength":1},"edicion_base":{"type":"string","minLength":1},"fecha_inicio":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"fecha_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"inicio_inclusivo":{"type":"boolean"},"fin_inclusivo":{"type":"boolean"},"fecha_aproximada":{"type":"boolean"},"variantes_titulo":{"type":"array","items":{"type":"string","minLength":1}},"propuestas_autoria":{"type":"array","items":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{}}},"fuente_fecha":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fundamento_autoria":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","minLength":1}}},"required":["titulo","autor_nombre","genero","edicion_base","fecha_inicio","fecha_fin","fuente_fecha","fundamento_autoria","observaciones"],"additionalProperties":false},"jornadas":{"minItems":1,"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"rotulo_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["numero","v_ini","v_fin","rotulo_literal"],"additionalProperties":false}},"segmentos":{"minItems":1,"type":"array","items":{"type":"object","properties":{"ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"segmentacion":{"type":"string","enum":["provisional","confirmada"]},"origen":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"denominacion_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fuente_id":{"type":"string","minLength":1},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","minLength":1}},"tramos_ref":{"minItems":2,"type":"array","items":{"type":"string","minLength":1}},"correcciones":{"type":"array","minItems":1,"items":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"motivo":{"type":"string","minLength":1,"maxLength":2000}},"required":["tramo_ref","v_ini","v_fin","n_versos_fuente","motivo"],"additionalProperties":false}}},"required":["tramo_ref","denominacion_literal","fuente_id","pagina","notas_ref"],"additionalProperties":false},"identificacion":{"anyOf":[{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false},{"type":"null"}]},"candidatas":{"type":"array","items":{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false}},"regla_id":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"detalles_fuente":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"estructura"},"tipo_seccion":{"type":"string","const":"remate"},"nombre":{"type":"string","minLength":1},"n_versos":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"posicion":{"type":"string","const":"final"}},"required":["literal","dimension","tipo_seccion","nombre","n_versos","posicion"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"rasgo_slug":{"type":"string","minLength":1},"valor_slug":{"type":"string","minLength":1}},"required":["rasgo_slug","valor_slug"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"asonancia"}},"required":["literal"],"additionalProperties":false}]}},"desviaciones":{"type":"array","items":{"type":"object","properties":{"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"dimension":{"type":"string","enum":["metro","estructura"]},"relacion_norma":{"type":"string","enum":["menor_que_norma","mayor_que_norma","sobra","falta","otra"]},"metro_observado_slug":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"texto_fuente":{"type":"string","minLength":1},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["v_ini","v_fin","dimension","relacion_norma","nota_ref","texto_fuente","nota"],"additionalProperties":false}},"caracterizaciones":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"termino":{"type":"string","const":"prosa"},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"tramo_ref":{"type":"string","minLength":1},"literal":{"type":"string","minLength":1}},"required":["termino","v_ini","v_fin","tramo_ref","literal"],"additionalProperties":false},{"type":"object","properties":{"termino":{"type":"string","const":"cantado"},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"tramo_ref":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"literal":{"type":"string","minLength":1}},"required":["termino","v_ini","v_fin","tramo_ref","nota_ref","literal"],"additionalProperties":false}]}}},"required":["ref","v_ini","v_fin","segmentacion","origen","identificacion","candidatas","regla_id","nota","detalles_fuente","desviaciones"],"additionalProperties":false}},"comprobacion":{"type":"object","properties":{"avisos_longitud":{"type":"array","items":{"type":"object","properties":{"segmento_ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"mensaje":{"type":"string","minLength":1}},"required":["segmento_ref","v_ini","v_fin","mensaje"],"additionalProperties":false}}},"required":["avisos_longitud"],"additionalProperties":false},"numeracion":{"type":"object","properties":{"tipo":{"type":"string","const":"por_jornada"},"desplazamientos":{"minItems":2,"type":"array","items":{"type":"object","properties":{"jornada":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"desplazamiento":{"type":"integer","minimum":0,"maximum":9007199254740991}},"required":["jornada","desplazamiento"],"additionalProperties":false}}},"required":["tipo","desplazamientos"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"reglas_version":{"type":"string","minLength":1},"catalogo_revision":{"type":"integer","minimum":0,"maximum":9007199254740991},"extraccion_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},"entradas_sha256":{"type":"object","propertyNames":{"type":"string","minLength":1},"additionalProperties":{"type":"string","pattern":"^[a-f0-9]{64}$"}},"ejecucion":{"type":"object","properties":{"generador":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]}},"required":["generador","modelo","prompt_version"],"additionalProperties":false}},"required":["reglas_version","catalogo_revision","extraccion_sha256","entradas_sha256"],"additionalProperties":false}},"required":["esquema","obra_ref","metadatos","jornadas","segmentos","procedencia"],"additionalProperties":false}$schema$::json;
$func$;

-- El cálculo de desplazamientos usa las filas corregidas que comparten los segmentos.
create or replace function public.comprobar_numeracion_minima(p_datos jsonb,p_original jsonb)
returns jsonb language plpgsql set search_path='' as $$
declare
 v_calc jsonb:='[]'::jsonb; v_acum integer:=0; v_k integer:=0; v_prev integer; v_fila jsonb;
 v_j integer; v_primero integer; v_max integer;
 v_correcciones jsonb; v_num_correcciones integer; v_num_refs integer;
 v_tramos jsonb:=p_original->'tramos';
begin
 select jsonb_object_agg(c->>'tramo_ref',c),count(*),count(distinct c->>'tramo_ref')
   into v_correcciones,v_num_correcciones,v_num_refs
   from (select distinct c from jsonb_array_elements(p_datos->'segmentos') s
     cross join lateral jsonb_array_elements(coalesce(s#>'{origen,correcciones}','[]')) c) cambios;
 if v_num_correcciones<>v_num_refs then
  raise exception using errcode='23514',message='Una fila de origen tiene correcciones contradictorias';
 end if;
 if v_num_correcciones>0 and exists (
    select 1 from jsonb_array_elements(p_datos->'segmentos') s
    cross join lateral jsonb_array_elements_text(coalesce(s#>'{origen,tramos_ref}',jsonb_build_array(s#>>'{origen,tramo_ref}'))) r(ref)
    where v_correcciones ? r.ref and not coalesce(s#>'{origen,correcciones}','[]') @> jsonb_build_array(v_correcciones->r.ref)
 ) then
  raise exception using errcode='23514',message='Toda parte de una fila corregida debe conservar su corrección';
 end if;
 if p_datos->'numeracion' is null then return '[]'::jsonb; end if;
 if v_num_correcciones>0 then
  select jsonb_agg(t||coalesce(v_correcciones->(t->>'id'), '{}') order by orden) into v_tramos
   from jsonb_array_elements(v_tramos) with ordinality x(t,orden);
 end if;
 for v_fila in select t from jsonb_array_elements(v_tramos) with ordinality x(t,o)
   where t->>'v_ini' is not null and t->>'v_fin' is not null order by o loop
  if v_fila->>'jornada' is null or (v_prev is not null and (v_fila->>'jornada')::integer<v_prev) then
   raise exception using errcode='23514',message='La numeración por jornada exige filas con jornada y en orden';
  end if;
  v_prev:=(v_fila->>'jornada')::integer;
 end loop;
 for v_j in select (t->>'jornada')::integer from jsonb_array_elements(v_tramos) with ordinality x(t,o)
   where t->>'v_ini' is not null and t->>'v_fin' is not null
   group by (t->>'jornada')::integer order by min(o) loop
  select (t->>'v_ini')::integer into v_primero from jsonb_array_elements(v_tramos) with ordinality x(t,o)
    where (t->>'jornada')::integer=v_j and t->>'v_ini' is not null order by o limit 1;
  select max((t->>'v_fin')::integer) into v_max from jsonb_array_elements(v_tramos) t
    where (t->>'jornada')::integer=v_j and t->>'v_fin' is not null;
  if v_k>0 and v_primero<>1 then
   raise exception using errcode='23514',message='Numeración por jornada declarada en una edición que no la reinicia';
  end if;
  v_calc:=v_calc||jsonb_build_array(jsonb_build_object('jornada',v_j,'desplazamiento',v_acum));
  v_acum:=v_acum+v_max; v_k:=v_k+1;
 end loop;
 if v_k<2 or v_calc is distinct from p_datos#>'{numeracion,desplazamientos}' then
  raise exception using errcode='23514',message='Los desplazamientos de la numeración no coinciden con la transcripción';
 end if;
 return v_calc;
end;
$$;
revoke all on function public.comprobar_numeracion_minima(jsonb,jsonb) from public,anon,authenticated;

create or replace function public.comprobar_origen_minimo(p_fila jsonb,p_original jsonb,p_desplazamientos jsonb default '[]'::jsonb)
returns void language plpgsql set search_path='' as $$
declare
 refs jsonb:=coalesce(p_fila#>'{origen,tramos_ref}',jsonb_build_array(p_fila#>>'{origen,tramo_ref}'));
 correcciones jsonb:=coalesce(p_fila#>'{origen,correcciones}','[]'::jsonb);
 rangos jsonb:='[]'::jsonb;
 r jsonb; anterior jsonb; prosa jsonb; c jsonb; v_nota jsonb; correccion jsonb;
 literal_prosa text; localizador text[];
 n integer:=0; m integer:=0;
 ord bigint; prev_ord bigint; jornada integer; lo integer; hi integer; d integer;
 r_ini integer; r_fin integer; anterior_fin integer;
 inicio integer:=(p_fila->>'v_ini')::integer; fin integer:=(p_fila->>'v_fin')::integer;
begin
 if jsonb_array_length(refs)<>(select count(distinct value) from jsonb_array_elements(refs))
   or refs->>0 is distinct from p_fila#>>'{origen,tramo_ref}' then
  raise exception using errcode='23514',message='Referencias de origen inválidas';
 end if;
 if jsonb_array_length(correcciones)<>(select count(distinct value->>'tramo_ref') from jsonb_array_elements(correcciones))
   or exists(select 1 from jsonb_array_elements(correcciones) x where
      not (refs ? (x->>'tramo_ref')) or x->>'motivo' !~ '[^[:space:]]'
      or (x->>'v_fin')::integer<(x->>'v_ini')::integer
      or ((x->>'n_versos_fuente')::integer is not null and
          (x->>'n_versos_fuente')::integer<>(x->>'v_fin')::bigint-(x->>'v_ini')::bigint+1)) then
  raise exception using errcode='23514',message='Corrección de origen sin referencia, motivo o recuento coherente';
 end if;
 if (select count(*)<>count(distinct p->>'tramo_ref')
     from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) p where p->>'termino'='prosa') then
  raise exception using errcode='23514',message='Caracterización de prosa repetida';
 end if;
 for c in select value from jsonb_array_elements(refs) loop
  select t,orden into r,ord from jsonb_array_elements(p_original->'tramos') with ordinality as x(t,orden)
    where t->>'id'=c#>>'{}';
  select x into correccion from jsonb_array_elements(correcciones) x where x->>'tramo_ref'=r->>'id';
  if correccion is not null then
   r:=r||jsonb_build_object('v_ini',correccion->'v_ini','v_fin',correccion->'v_fin',
      'n_versos_fuente',correccion->'n_versos_fuente');
  end if;
  if r is null or r->>'v_ini' is null or r->>'v_fin' is null then
   raise exception using errcode='23514',message='Fila métrica de origen inexistente o sin rango';
  end if;
  d:=public.desplazamiento_jornada_minima(p_desplazamientos,(r->>'jornada')::integer);
  r_ini:=(r->>'v_ini')::integer+d; r_fin:=(r->>'v_fin')::integer+d;
  rangos:=rangos||jsonb_build_array(jsonb_build_object('ini',r_ini,'fin',r_fin,'jornada',r->'jornada'));
  if anterior is null then
   lo:=r_ini; jornada:=(r->>'jornada')::integer;
   if (r->>'fuente_id') is distinct from (p_fila#>>'{origen,fuente_id}') or
      (r->>'denominacion_literal') is distinct from (p_fila#>>'{origen,denominacion_literal}') then
    raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
   end if;
  else
   prosa:=p_original->'tramos'->(prev_ord::integer);
   if ord<>prev_ord+2 or (r->>'v_ini')::integer<>(anterior->>'v_fin')::integer+1 or
      (r->>'jornada')::integer is distinct from jornada or jornada is null or
      (prosa->>'jornada')::integer is distinct from jornada or
      lower(btrim(prosa->>'denominacion_literal')) !~ '^(carta en |pasaje en )?prosa$' or
      prosa->>'denominacion_literal' is null or prosa->>'v_ini' is not null or
      prosa->>'v_fin' is not null or prosa->>'n_versos_fuente' is not null then
    raise exception using errcode='23514',message='La unión requiere prosa sin numeración entre filas consecutivas de una jornada';
   end if;
   if anterior_fin>=inicio and r_ini<=fin then
    n:=n+1;
    if not exists(select 1 from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) p
      where p->>'termino'='prosa' and p->>'tramo_ref'=prosa->>'id'
       and p->>'literal'=prosa->>'denominacion_literal'
       and (p->>'v_ini')::integer=anterior_fin
       and (p->>'v_fin')::integer=r_ini) then
     raise exception using errcode='23514',message='Falta localizar la prosa de la unión';
    end if;
   end if;
  end if;
  hi:=r_fin; anterior:=r; anterior_fin:=r_fin; prev_ord:=ord;
 end loop;
 if lo>inicio or hi<fin or lo is null or hi is null then
  raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
 end if;
 -- Una acotación puede imprimir el localizador dentro de una fila métrica.
 for c in select value from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) where value->>'termino'='prosa' loop
  select t into prosa from jsonb_array_elements(p_original->'tramos') t where t->>'id'=c->>'tramo_ref';
  literal_prosa:=btrim(prosa->>'denominacion_literal');
  if left(literal_prosa,1)='[' and right(literal_prosa,1)=']' then
   literal_prosa:=btrim(substr(literal_prosa,2,length(literal_prosa)-2));
  end if;
  localizador:=regexp_match(literal_prosa,
    '^(?:carta en |pasaje en )?prosa entre (?:los )?vv?\.?[[:space:]]*([0-9]+)[[:space:]]*[-–—][[:space:]]*([0-9]+)$','i');
  if localizador is null then continue; end if;
  d:=public.desplazamiento_jornada_minima(p_desplazamientos,(prosa->>'jornada')::integer);
  if prosa->>'denominacion_literal' is distinct from c->>'literal'
    or prosa->>'v_ini' is not null or prosa->>'v_fin' is not null or prosa->>'n_versos_fuente' is not null
    or (c->>'v_ini')::integer::bigint+1<>(c->>'v_fin')::integer
    or (c->>'v_ini')::integer::numeric<>localizador[1]::numeric+d
    or (c->>'v_fin')::integer::numeric<>localizador[2]::numeric+d
    or (c->>'v_ini')::integer<inicio or (c->>'v_fin')::integer>fin
    or not exists(select 1 from jsonb_array_elements(rangos) x where
      (x->'jornada') is not distinct from (prosa->'jornada') and
      (x->>'ini')::integer<=(c->>'v_ini')::integer and (x->>'fin')::integer>=(c->>'v_fin')::integer) then
   raise exception using errcode='23514',message='Localizador de prosa distinto del impreso o fuera del pasaje';
  end if;
  n:=n+1;
 end loop;
 -- Pasajes cantados: la nota de la edición lo dice de esa fila y el rango es la fila en el segmento.
 for c in select value from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) where value->>'termino'='cantado' loop
  select t into r from jsonb_array_elements(p_original->'tramos') t where t->>'id'=c->>'tramo_ref';
  select x into v_nota from jsonb_array_elements(p_original->'notas') x where x->>'id'=c->>'nota_ref';
  if r is null or not (refs ? (c->>'tramo_ref')) or v_nota is null
    or not (v_nota->'tramos_ref' ? (c->>'tramo_ref'))
    or v_nota->>'texto_literal' is distinct from c->>'literal'
    or v_nota->>'texto_literal' !~* '(^|[^[:alpha:]])cantad[oa]s?([^[:alpha:]]|$)'
    or v_nota->>'texto_literal' ~* '(^|[^[:alpha:]])no[[:space:]]+cantad' then
   raise exception using errcode='23514',message='Pasaje cantado sin nota de la edición que lo declare';
  end if;
  d:=public.desplazamiento_jornada_minima(p_desplazamientos,(r->>'jornada')::integer);
  if (c->>'v_ini')::integer<>greatest(inicio,(r->>'v_ini')::integer+d)
    or (c->>'v_fin')::integer<>least(fin,(r->>'v_fin')::integer+d)
    or (c->>'v_fin')::integer<(c->>'v_ini')::integer then
   raise exception using errcode='23514',message='Pasaje cantado fuera de su fila';
  end if;
  m:=m+1;
 end loop;
 if jsonb_array_length(coalesce(p_fila->'caracterizaciones','[]'))<>n+m then
  raise exception using errcode='23514',message='Caracterización sin origen o fuera del pasaje';
 end if;
 for c in select value from jsonb_array_elements(p_fila#>'{origen,notas_ref}') loop
  if not exists(select 1 from jsonb_array_elements(p_original->'notas') nota
    where nota->>'id'=c#>>'{}' and exists(select 1 from jsonb_array_elements_text(refs) as z(ref)
      where nota->'tramos_ref' ? ref)) then
   raise exception using errcode='23514',message='Nota sin correspondencia con el tramo original';
  end if;
 end loop;
end;
$$;
revoke all on function public.comprobar_origen_minimo(jsonb,jsonb,jsonb) from public,anon,authenticated;

do $guarda$
declare
 original jsonb:='{"tramos":[
   {"id":"t1","jornada":1,"v_ini":1,"v_fin":10,"n_versos_fuente":11,"fuente_id":"foto","denominacion_literal":"romance"},
   {"id":"p1","jornada":1,"v_ini":null,"v_fin":null,"n_versos_fuente":null,
    "denominacion_literal":"[Carta en prosa entre los vv. 9-10]"}
 ],"notas":[]}';
 fila jsonb:='{"v_ini":1,"v_fin":11,
   "origen":{"tramo_ref":"t1","fuente_id":"foto","denominacion_literal":"romance","notas_ref":[],
    "correcciones":[{"tramo_ref":"t1","v_ini":1,"v_fin":11,"n_versos_fuente":11,"motivo":"Cotejo de la edición"}]},
   "caracterizaciones":[{"termino":"prosa","tramo_ref":"p1","literal":"[Carta en prosa entre los vv. 9-10]",
    "v_ini":9,"v_fin":10}]}';
 ficha_reiniciada jsonb;
 original_reiniciado jsonb;
begin
 if not extensions.jsonb_matches_schema(
    (public.esquema_documento_minimo()::jsonb #>
      '{properties,segmentos,items,properties,origen,properties,correcciones}')::json,
    fila#>'{origen,correcciones}') then
  raise exception 'El esquema no acepta correcciones de origen';
 end if;
 perform public.comprobar_origen_minimo(fila,original);
 original_reiniciado:=jsonb_set(original,'{tramos,1}',
   '{"id":"t2","jornada":2,"v_ini":1,"v_fin":3,"fuente_id":"foto","denominacion_literal":"romance"}');
 ficha_reiniciada:=jsonb_build_object('segmentos',jsonb_build_array(fila),
   'numeracion','{"tipo":"por_jornada","desplazamientos":[{"jornada":1,"desplazamiento":0},{"jornada":2,"desplazamiento":11}]}'::jsonb);
 perform public.comprobar_numeracion_minima(ficha_reiniciada,original_reiniciado);
 begin
  perform public.comprobar_numeracion_minima(
   jsonb_set(ficha_reiniciada,'{segmentos}',jsonb_build_array(fila,fila #- '{origen,correcciones}')),
   original_reiniciado);
  raise exception 'Una parte perdió la corrección compartida';
 exception when check_violation then null;
 end;
 begin
  perform public.comprobar_origen_minimo(fila #- '{origen,correcciones}',original);
  raise exception 'Se admitió un rango nuevo sin corrección';
 exception when check_violation then null;
 end;
 begin
  perform public.comprobar_origen_minimo(jsonb_set(fila,'{origen,correcciones,0,motivo}','" "'),original);
  raise exception 'Se admitió una corrección sin motivo';
 exception when check_violation then null;
 end;
 begin
  perform public.comprobar_origen_minimo(jsonb_set(fila,'{caracterizaciones,0,v_ini}','8'),original);
  raise exception 'Se admitió una localización de prosa distinta de la impresa';
 exception when check_violation then null;
 end;
end;
$guarda$;
