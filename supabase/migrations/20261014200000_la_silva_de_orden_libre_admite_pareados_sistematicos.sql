-- La silva consonante de orden libre admite una serie enteramente pareada.
--
-- Decisión de David, 14 de octubre de 2026: combinar 7 y 11 sin orden fijo y rimar todos
-- los versos en pareados no equivale a repetir aA | bB | cC. «Predominantes» deja de ser
-- definitorio y se pregunta junto a «Regulares». La densidad total ya estaba admitida.
-- No se reescribe ninguna anotación: la nueva respuesta queda pendiente, incluido el
-- pasaje de Adonis y Venus, vv. 2021–2094. Las seis secuencias de prueba también quedan
-- pendientes; el IP las retirará y avisará al editor de la obra real.
--
-- La explicación de «Mayoritaria» es compartida por tres arquitecturas. El criterio
-- específico de Morley y Bruerton permanece en la nota de la silva endecasílaba, no
-- en ese valor general. Se revisaron además las ayudas de toda la familia: la de
-- pareados sistemáticos corresponde a la endecasílaba, y las dos de densidad eran nulas.

begin;

create temporary table silva_registro_previo on commit drop as
select am.anotacion_id, to_jsonb(am) as anotacion,
 coalesce((select jsonb_agg(to_jsonb(e) order by e.eleccion_id)
  from public.anotacion_elecciones e where e.anotacion_id = am.anotacion_id), '[]'::jsonb) as respuestas
from public.anotaciones_metricas am
join public.formas_metricas f using (forma_id)
where f.slug = 'silva';

do $catalogo$
declare
 v_forma uuid;
 v_arquitectura uuid;
 v_rasgo uuid;
 v_predominantes uuid;
 v_regulares uuid;
 v_actual text;
 v_n integer;
begin
 select forma_id into strict v_forma from public.formas_metricas where slug = 'silva' and activo;
 select arquitectura_id, descripcion into strict v_arquitectura, v_actual
 from public.arquitecturas_forma where forma_id = v_forma and slug = 'consonante_irregular' and activo;
 if v_actual not in (
  'Es la silva ordinaria y la más frecuente del corpus: la de las *Soledades*. Los pareados dominan sin llegar a formar pauta.',
  'Combina heptasílabos y endecasílabos sin orden fijo de medida. Los pareados pueden predominar o organizar toda la serie, y puede haber versos sueltos. Cuando toda la serie es pareada, la densidad de rima es total; lo que la distingue de la consonante regular es que no repite la alternancia 7–11.') then
  raise exception 'La descripción de la silva de orden libre no es la revisada: %', v_actual;
 end if;
 select rasgo_id into strict v_rasgo from public.rasgos_metricos where slug = 'organizacion_en_pareados';
 select valor_id into strict v_predominantes from public.rasgo_valores where rasgo_id = v_rasgo and slug = 'predominantes' and activo;
 select valor_id into strict v_regulares from public.rasgo_valores where rasgo_id = v_rasgo and slug = 'regulares' and activo;
 select modalidad into strict v_actual from public.arquitectura_rasgos
 where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo and valor_id = v_predominantes;
 if v_actual not in ('definitoria', 'habitual') then
  raise exception 'Los pareados predominantes de esta silva eran %, no la norma revisada.', v_actual;
 end if;
 if exists (select 1 from public.arquitectura_rasgos where arquitectura_id = v_arquitectura
  and rasgo_id = v_rasgo and (valor_id is null or valor_id not in (v_predominantes, v_regulares))) then
  raise exception 'Esta silva declara otros grados de pareados: no se modifica sin revisarlos.';
 end if;

 update public.arquitectura_rasgos set modalidad = 'habitual',
  nota = 'No exige una alternancia fija de heptasílabos y endecasílabos.'
 where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo and valor_id = v_predominantes;
 insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
 select v_arquitectura, v_rasgo, v_regulares, 'admitida',
  'La medida conserva su orden libre; toda la serie pareada exige densidad de rima total.'
 where not exists (select 1 from public.arquitectura_rasgos where arquitectura_id = v_arquitectura
  and rasgo_id = v_rasgo and valor_id = v_regulares);

 insert into public.grupos_eleccion_metrica (
  arquitectura_id, slug, dimension, alcance, rasgo_id, tipo_control,
  selecciones_min, selecciones_max, permite_aplicar_global, define_norma, activo, orden, ayuda_editor
 ) select v_arquitectura, 'organizacion_en_pareados', 'rasgo', 'secuencia', v_rasgo, 'opciones',
  1, 1, false, false, true, 91,
  'Elige «Predominantes» si los pareados dominan sin abarcar toda la serie, o «Regulares» si toda ella se organiza en pareados. En ambos casos las medidas pueden combinarse sin orden fijo; la alternancia constante 7–11 corresponde a la consonante regular. Con pareados regulares, la densidad de rima es total.'
 where not exists (select 1 from public.grupos_eleccion_metrica
  where arquitectura_id = v_arquitectura and slug = 'organizacion_en_pareados');

 update public.arquitecturas_forma set descripcion =
  'Combina heptasílabos y endecasílabos sin orden fijo de medida. Los pareados pueden predominar o organizar toda la serie, y puede haber versos sueltos. Cuando toda la serie es pareada, la densidad de rima es total; lo que la distingue de la consonante regular es que no repite la alternancia 7–11.'
 where arquitectura_id = v_arquitectura;
 update public.arquitecturas_forma set descripcion =
  'Alterna heptasílabo y endecasílabo en pareados que se suceden sin excepción, de modo que el pareado funciona aquí como unidad. A diferencia de la consonante de orden libre, repite el patrón métrico y de rima aA | bB | cC.'
 where forma_id = v_forma and slug = 'consonante_regular' and activo;

 select rv.descripcion into strict v_actual from public.rasgo_valores rv
 join public.rasgos_metricos r using (rasgo_id) where r.slug = 'densidad_de_rima' and rv.slug = 'mayoritaria';
 if v_actual not in (
  'Rima más de la mitad, pero no todos. Es el tramo del 50 al 98 % en que Morley y Bruerton sitúan la silva de endecasílabos.',
  'Rima más de la mitad de los versos de la serie, pero no todos; el dístico final, si lo hay, no cuenta.') then
  raise exception 'La descripción compartida de densidad mayoritaria no es la revisada: %', v_actual;
 end if;
 update public.rasgo_valores rv set descripcion =
  'Rima más de la mitad de los versos de la serie, pero no todos; el dístico final, si lo hay, no cuenta.'
 from public.rasgos_metricos r where rv.rasgo_id = r.rasgo_id
  and r.slug = 'densidad_de_rima' and rv.slug = 'mayoritaria';

 update public.grupos_eleccion_metrica g set ayuda_editor =
  'Cuenta los versos que riman en la serie, sin el dístico final. «Mayoritaria» indica que rima más de la mitad, pero no todos; «Total», que riman todos. La densidad no dice si esas rimas forman pareados.'
 from public.arquitecturas_forma a
 where g.arquitectura_id = a.arquitectura_id and a.forma_id = v_forma
  and a.slug in ('libre', 'consonante_irregular') and g.slug = 'densidad_de_rima';
 get diagnostics v_n = row_count;
 if v_n <> 2 then raise exception 'Se esperaban dos ayudas de densidad de la silva, se encontraron %.', v_n; end if;
 update public.grupos_eleccion_metrica g set ayuda_editor =
  'En una serie formada solo por endecasílabos, si los pareados organizan sistemáticamente toda la secuencia, se registra como tirada de pareados. Esta ayuda no se aplica a las silvas que mezclan siete y once.'
 from public.arquitecturas_forma a
 where g.arquitectura_id = a.arquitectura_id and a.forma_id = v_forma
  and a.slug = 'endecasilabica' and g.slug = 'organizacion_en_pareados';
 get diagnostics v_n = row_count;
 if v_n <> 1 then raise exception 'No se encontró la ayuda de pareados de la silva endecasílaba.'; end if;
end;
$catalogo$;

-- La garantía se difiere porque guardar_anotacion_metrica reemplaza todas las respuestas.
-- Se comprueba el estado final, independientemente del orden en que lleguen los dos rasgos.
create or replace function public.validar_densidad_de_pareados_regulares()
returns trigger language plpgsql set search_path = public as $coherencia$
declare
 v_anotacion uuid;
begin
 v_anotacion := case when tg_op = 'DELETE' then old.anotacion_id else new.anotacion_id end;
 if exists (
  select 1 from public.anotacion_elecciones p
  join public.rasgo_valores pv on pv.valor_id = p.valor_rasgo_id
  join public.rasgos_metricos pr on pr.rasgo_id = pv.rasgo_id
  join public.anotacion_elecciones d on d.anotacion_id = p.anotacion_id
   and d.realizacion_id is null and d.seccion_tratada_id is null
  join public.rasgo_valores dv on dv.valor_id = d.valor_rasgo_id
  join public.rasgos_metricos dr on dr.rasgo_id = dv.rasgo_id
  where p.anotacion_id = v_anotacion and p.realizacion_id is null and p.seccion_tratada_id is null
   and pr.slug = 'organizacion_en_pareados' and pv.slug = 'regulares'
   and dr.slug = 'densidad_de_rima' and dv.slug <> 'total'
 ) then
  raise exception 'Si los pareados organizan toda la serie, la densidad de rima debe ser «Total»: todos sus versos riman.'
   using errcode = '22023';
 end if;
 return null;
end;
$coherencia$;

drop trigger if exists comprobar_densidad_de_pareados_regulares on public.anotacion_elecciones;
create constraint trigger comprobar_densidad_de_pareados_regulares
after insert or update or delete on public.anotacion_elecciones
deferrable initially deferred for each row
execute function public.validar_densidad_de_pareados_regulares();

do $guardas$
declare
 v_arq uuid;
 v_forma uuid;
 v_admin uuid;
 v_escenario uuid;
 v_payload jsonb;
 v_opciones jsonb;
 v_caso record;
 v_n integer;
begin
 select a.arquitectura_id, a.forma_id into strict v_arq, v_forma
 from public.arquitecturas_forma a join public.formas_metricas f using (forma_id)
 where f.slug = 'silva' and a.slug = 'consonante_irregular';
 select count(*) into v_n from public.grupos_eleccion_metrica g
 join public.opciones_eleccion_metrica o using (grupo_eleccion_id)
 join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
 where g.arquitectura_id = v_arq and g.slug = 'organizacion_en_pareados' and g.activo
  and g.selecciones_min = 1 and g.selecciones_max = 1 and g.alcance = 'secuencia'
  and rv.slug in ('predominantes', 'regulares');
 if v_n <> 2 then raise exception 'La silva no ofrece exactamente sus dos grados de pareados.'; end if;
 if public.preguntas_que_ofrecen_una_definitoria() is not null then
  raise exception 'Una norma definitoria se ofrece como opción: %', public.preguntas_que_ofrecen_una_definitoria();
 end if;
 perform public.get_forma_metrica_publica_jerarquica('silva');

 -- Se ejecuta la RPC real en un escenario temporal. Todo este bloque se deshace,
 -- incluidas las inserciones que pasan: no se presta ninguna obra anotada a la prueba.
 select e.user_id into v_admin from public.editores e
 join public.vocabularios r on r.termino_id = e.role
 where lower(r.termino) in ('admin', 'ip') and e.activo order by e.created_at limit 1;
 if v_admin is null then raise exception 'No hay una identidad admin/IP para ensayar el guardado.'; end if;
 perform set_config('request.jwt.claim.sub', v_admin::text, true);
 begin
  insert into public.anotacion_escenarios_prueba (nombre, created_by, updated_by)
  values ('Guarda transitoria: silva de orden libre', v_admin, v_admin) returning escenario_id into v_escenario;
  v_n := 0;
  for v_caso in select * from (values
   ('total', 'regulares', true), ('total', 'predominantes', true),
   ('mayoritaria', 'predominantes', true), ('mayoritaria', 'regulares', false)
  ) casos(densidad, pareados, admitida) loop
   v_n := v_n + 1;
   select jsonb_agg(jsonb_build_object('opcion_eleccion_id', o.opcion_eleccion_id,
    'realizacion_id', null, 'dimension', 'rasgo')) into v_opciones
   from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
   join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
   where g.arquitectura_id = v_arq and (
    (g.slug = 'densidad_de_rima' and rv.slug = v_caso.densidad)
    or (g.slug = 'organizacion_en_pareados' and rv.slug = v_caso.pareados));
   v_payload := jsonb_build_object('escenario_id', v_escenario, 'forma_id', v_forma,
    'arquitectura_id', v_arq, 'orden', v_n, 'v_ini', 1, 'v_fin', 4,
    'unidades', '[]'::jsonb, 'elecciones', v_opciones, 'desviaciones', '[]'::jsonb);
   begin
    perform public.guardar_anotacion_metrica(v_payload);
    set constraints all immediate;
    if not v_caso.admitida then raise exception 'La base ha admitido pareados regulares sin densidad total.'; end if;
   exception when sqlstate '22023' then
    if v_caso.admitida or sqlerrm not like 'Si los pareados organizan toda la serie%' then raise; end if;
   end;
   set constraints all deferred;
  end loop;

  -- Una anotación anterior conserva su dato, pero un guardado nuevo necesita confirmar
  -- la organización en pareados: la densidad total sola no contesta esa pregunta.
  v_payload := jsonb_set(v_payload, '{orden}', '5'::jsonb);
  v_payload := jsonb_set(v_payload, '{elecciones}', (
   select jsonb_agg(jsonb_build_object('opcion_eleccion_id', o.opcion_eleccion_id,
    'realizacion_id', null, 'dimension', 'rasgo'))
   from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
   join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
   where g.arquitectura_id = v_arq and g.slug = 'densidad_de_rima' and rv.slug = 'total'
  ));
  begin
   perform public.guardar_anotacion_metrica(v_payload);
   raise exception 'La base ha guardado la silva sin contestar su organización en pareados.';
  exception when raise_exception then
   if sqlerrm not like 'La pregunta «%» necesita entre % respuestas' then raise; end if;
  end;
  raise exception using errcode = 'ZX001', message = 'Deshacer los escenarios de las guardas';
 exception when sqlstate 'ZX001' then null;
 end;

 if exists (select 1 from silva_registro_previo antes
  left join public.anotaciones_metricas am using (anotacion_id)
  where to_jsonb(am) is distinct from antes.anotacion or antes.respuestas is distinct from
   coalesce((select jsonb_agg(to_jsonb(e) order by e.eleccion_id)
    from public.anotacion_elecciones e where e.anotacion_id = am.anotacion_id), '[]'::jsonb)) then
  raise exception 'Ha cambiado una anotación de silva: la migración no debe reescribir lo observado.';
 end if;
end;
$guardas$;

update public.catalogo_metrico_estado set revision = revision + 1, actualizado_en = now() where id;
set constraints all immediate;
commit;
