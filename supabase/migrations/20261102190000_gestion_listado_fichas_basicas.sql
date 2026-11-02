-- Listado compacto, fecha de modificación y borrado explícito admin/IP. No elimina datos.
begin;
create or replace function public.esquema_documento_minimo() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-ficha-minima/0.2"},"obra_ref":{"type":"string","minLength":1},"metadatos":{"type":"object","properties":{"titulo":{"type":"string","minLength":1},"autor_nombre":{"type":"string","minLength":1},"genero":{"type":"string","minLength":1},"edicion_base":{"type":"string","minLength":1},"fecha_inicio":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fecha_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"fuente_fecha":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fundamento_autoria":{"default":null,"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","minLength":1}}},"required":["titulo","autor_nombre","genero","edicion_base","fecha_inicio","fecha_fin","fuente_fecha","fundamento_autoria","observaciones"],"additionalProperties":false},"jornadas":{"minItems":1,"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"rotulo_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["numero","v_ini","v_fin","rotulo_literal"],"additionalProperties":false}},"segmentos":{"minItems":1,"type":"array","items":{"type":"object","properties":{"ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"segmentacion":{"type":"string","enum":["provisional","confirmada"]},"origen":{"type":"object","properties":{"tramo_ref":{"type":"string","minLength":1},"denominacion_literal":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"fuente_id":{"type":"string","minLength":1},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","minLength":1}}},"required":["tramo_ref","denominacion_literal","fuente_id","pagina","notas_ref"],"additionalProperties":false},"identificacion":{"anyOf":[{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false},{"type":"null"}]},"candidatas":{"type":"array","items":{"type":"object","properties":{"forma_slug":{"type":"string","minLength":1},"arquitectura_slug":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["forma_slug","arquitectura_slug"],"additionalProperties":false}},"regla_id":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]},"detalles_fuente":{"type":"array","items":{"anyOf":[{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"estructura"},"tipo_seccion":{"type":"string","const":"remate"},"nombre":{"type":"string","minLength":1},"n_versos":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"posicion":{"type":"string","const":"final"}},"required":["literal","dimension","tipo_seccion","nombre","n_versos","posicion"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"rasgo_slug":{"type":"string","minLength":1},"valor_slug":{"type":"string","minLength":1}},"required":["rasgo_slug","valor_slug"],"additionalProperties":false},{"type":"object","properties":{"literal":{"type":"string","minLength":1},"dimension":{"type":"string","const":"asonancia"}},"required":["literal"],"additionalProperties":false}]}},"desviaciones":{"type":"array","items":{"type":"object","properties":{"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"dimension":{"type":"string","enum":["metro","estructura"]},"relacion_norma":{"type":"string","enum":["menor_que_norma","mayor_que_norma","sobra","falta","otra"]},"metro_observado_slug":{"type":"string","minLength":1},"nota_ref":{"type":"string","minLength":1},"texto_fuente":{"type":"string","minLength":1},"nota":{"anyOf":[{"type":"string","minLength":1},{"type":"null"}]}},"required":["v_ini","v_fin","dimension","relacion_norma","nota_ref","texto_fuente","nota"],"additionalProperties":false}}},"required":["ref","v_ini","v_fin","segmentacion","origen","identificacion","candidatas","regla_id","nota","detalles_fuente","desviaciones"],"additionalProperties":false}},"comprobacion":{"type":"object","properties":{"avisos_longitud":{"type":"array","items":{"type":"object","properties":{"segmento_ref":{"type":"string","minLength":1},"v_ini":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"v_fin":{"type":"integer","exclusiveMinimum":0,"maximum":2147483647},"mensaje":{"type":"string","minLength":1}},"required":["segmento_ref","v_ini","v_fin","mensaje"],"additionalProperties":false}}},"required":["avisos_longitud"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"reglas_version":{"type":"string","minLength":1},"catalogo_revision":{"type":"integer","minimum":0,"maximum":9007199254740991},"extraccion_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},"entradas_sha256":{"type":"object","propertyNames":{"type":"string","minLength":1},"additionalProperties":{"type":"string","pattern":"^[a-f0-9]{64}$"}},"ejecucion":{"type":"object","properties":{"generador":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]}},"required":["generador","modelo","prompt_version"],"additionalProperties":false}},"required":["reglas_version","catalogo_revision","extraccion_sha256","entradas_sha256"],"additionalProperties":false}},"required":["esquema","obra_ref","metadatos","jornadas","segmentos","procedencia"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_documento_minimo() from public,anon,authenticated;

create or replace function public.esquema_extraccion_minima() returns json
language sql immutable set search_path = '' as $func$
  select $schema${"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","properties":{"esquema":{"type":"string","const":"versologia-extraccion/0.1"},"obra_ref":{"type":"string","pattern":"\\S"},"estado_revision":{"type":"string","const":"borrador_ia"},"revision_humana":{"type":"object","properties":{"responsable":{"type":"null"},"fecha":{"type":"null"},"resultado":{"type":"string","const":"pendiente"}},"required":["responsable","fecha","resultado"],"additionalProperties":false},"procedencia":{"type":"object","properties":{"fecha":{"anyOf":[{"type":"string","pattern":"^\\d{4}-\\d{2}-\\d{2}$"},{"type":"null"}]},"procedimiento":{"type":"string","enum":["lectura_visual_asistida","ejecucion_prompt"]},"generador":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"modelo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"modo":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"plan":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"parametros":{"anyOf":[{"type":"string","minLength":1,"maxLength":2000},{"type":"null"}]},"prompt_version":{"type":"string","pattern":"\\S"},"ensayo_controlado":{"type":"boolean"}},"required":["fecha","procedimiento","generador","modelo","prompt_version","ensayo_controlado"],"additionalProperties":false},"metadatos":{"anyOf":[{"type":"object","properties":{"titulo":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"genero_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fecha_inicio":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fecha_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_fecha":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"edicion_base":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"observaciones":{"type":"array","items":{"type":"string","pattern":"\\S"}},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"autoria_procedencia":{"type":"string","pattern":"\\S"},"bloque_docx_literal":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["titulo","autoria","genero_literal","fecha_inicio","fecha_fin","fuente_fecha","edicion_base","observaciones","fuente_id"],"additionalProperties":false},{"type":"null"}]},"jornadas":{"type":"array","items":{"type":"object","properties":{"numero":{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},"rotulo_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]}},"required":["numero","rotulo_literal"],"additionalProperties":false}},"tramos":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"jornada":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"notas_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["id","jornada","v_ini","v_fin","denominacion_literal","n_versos_fuente","fuente_id","pagina","notas_ref"],"additionalProperties":false}},"notas":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string","pattern":"\\S"},"marca":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"texto_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}},"v_ini":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"v_fin":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["id","marca","texto_literal","fuente_id","pagina","tramos_ref","v_ini","v_fin"],"additionalProperties":false}},"resumen_fuente":{"type":"array","items":{"type":"object","properties":{"denominacion_literal":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"n_versos_fuente":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]},"porcentaje_literal":{"anyOf":[{"type":"string","pattern":"^\\d+(,\\d+)?$"},{"type":"null"}]},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"pagina":{"anyOf":[{"type":"integer","exclusiveMinimum":0,"maximum":9007199254740991},{"type":"null"}]}},"required":["denominacion_literal","n_versos_fuente","porcentaje_literal","fuente_id","pagina"],"additionalProperties":false}},"incidencias":{"type":"array","items":{"type":"object","properties":{"tipo":{"type":"string","pattern":"\\S"},"descripcion":{"type":"string","pattern":"\\S"},"fuente_id":{"anyOf":[{"type":"string","pattern":"\\S"},{"type":"null"}]},"tramos_ref":{"type":"array","items":{"type":"string","pattern":"\\S"}}},"required":["tipo","descripcion","fuente_id","tramos_ref"],"additionalProperties":false}}},"required":["esquema","obra_ref","estado_revision","revision_humana","procedencia","metadatos","jornadas","tramos","notas","resumen_fuente","incidencias"],"additionalProperties":false}$schema$::json;
$func$;
revoke all on function public.esquema_extraccion_minima() from public,anon,authenticated;

-- Gestión editorial de básicas. No abre escritura directa sobre las copias confirmadas.

-- Los registros anteriores no se fechan retroactivamente. Las nuevas copias nacen
-- con ambas fechas; hoy son inmutables y aún no existe edición/reimportación general.
alter table public.importaciones_metricas add column if not exists modificado_en timestamptz;
alter table public.importaciones_metricas alter column modificado_en set default now();

create or replace function public.listar_fichas_basicas(p_desde integer default 0)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='La sesión no puede consultar fichas básicas';
 end if;
 if p_desde is null or p_desde<0 then raise exception using errcode='22023',message='Página inválida'; end if;
 return (
  with pagina as materialized (
   select i.* ,e.nombre_completo::text as importado_por_nombre
   from public.importaciones_metricas i join public.obras o using(obra_id)
   join public.editores e on e.user_id=i.importado_por
   where o.tipo_ficha='minima' and i.usada_en_corpus
   order by i.importado_en desc,i.importacion_id limit 51 offset p_desde
  )
  select coalesce(jsonb_agg(jsonb_build_object(
   'importacion_id',i.importacion_id,'obra_id',i.obra_id,
   'titulo',i.datos_confirmados#>>'{metadatos,titulo}',
   'autor_nombre',i.datos_confirmados#>>'{metadatos,autor_nombre}',
   'importado_por',i.importado_por_nombre,'importado_en',i.importado_en,
   'modificado_en',i.modificado_en,
   'formas_pendientes',coalesce((select jsonb_agg(jsonb_build_object(
     'denominacion',coalesce(s#>>'{origen,denominacion_literal}','Forma sin resolver'),
     'v_ini',(s->>'v_ini')::integer,'v_fin',(s->>'v_fin')::integer
    ) order by (s->>'v_ini')::integer)
    from jsonb_array_elements(i.datos_confirmados->'segmentos') s
    where s->'identificacion'='null'::jsonb),'[]'::jsonb),
   'comprobacion_registrada',i.datos_confirmados ? 'comprobacion',
   'avisos_longitud',coalesce(i.datos_confirmados#>'{comprobacion,avisos_longitud}','[]'::jsonb),
   'incidencias_fuente',coalesce((select jsonb_agg(jsonb_build_object('descripcion',c->>'descripcion'))
      from jsonb_array_elements(i.entrada_original->'incidencias') c),'[]'::jsonb)
  ) order by i.importado_en desc,i.importacion_id),'[]'::jsonb) from pagina i
 );
end;
$$;
revoke all on function public.listar_fichas_basicas(integer) from public,anon;
grant execute on function public.listar_fichas_basicas(integer) to authenticated;

create or replace function public.eliminar_ficha_basica(p_importacion uuid,p_confirmacion text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_obra uuid; v_tipo text; v_editor uuid; v_titulo text; v_vigente boolean;
begin
 if not public.auth_is_admin_or_ip() or not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='Solo admin o IP pueden eliminar fichas básicas';
 end if;
 -- Bloqueo compartido con las operaciones que modifiquen el tipo o asignación de la obra.
 select o.obra_id,o.tipo_ficha,o.editor_asignado,i.datos_confirmados#>>'{metadatos,titulo}',i.usada_en_corpus
 into v_obra,v_tipo,v_editor,v_titulo,v_vigente
 from public.importaciones_metricas i join public.obras o using(obra_id)
 where i.importacion_id=p_importacion for update of o,i;
 if not found then raise exception using errcode='P0002',message='La ficha ya no está disponible'; end if;
 if v_tipo<>'minima' or not v_vigente or v_editor is not null then
  raise exception using errcode='23514',message='La obra ya no es una ficha básica disponible para eliminar';
 end if;
 if p_confirmacion is null or btrim(p_confirmacion)<>btrim(v_titulo) then
  raise exception using errcode='22023',message='Escribe el título de la obra para confirmar';
 end if;
 if exists(select 1 from public.secuencias_metricas s join public.anotaciones_metricas a using(secuencia_id) where s.obra_id=v_obra) then
  raise exception using errcode='23514',message='La obra contiene anotaciones detalladas y no puede eliminarse desde el importador';
 end if;
 -- Los FK eliminan en la misma transacción jornadas, secuencias e importaciones de esa obra.
 delete from public.obras where obra_id=v_obra;
 return jsonb_build_object('eliminada',true,'obra_id',v_obra);
end;
$$;
revoke all on function public.eliminar_ficha_basica(uuid,text) from public,anon;
grant execute on function public.eliminar_ficha_basica(uuid,text) to authenticated;

commit;
