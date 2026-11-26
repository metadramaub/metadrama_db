-- En la glosa de El caballero de Olmedo, vv. 1113–1162, cada copla toma como
-- décimo verso un hexasílabo de la cabeza (vv. 1104–1108). Véase la edición de
-- Francisco Rico, jornada II, y Fernández Guillermo, El arte de la versificación
-- en el teatro de Lope de Vega, pp. 272–273.
begin;

do $copla_real$
declare
  v_arquitectura uuid;
  v_esquema uuid;
  v_grupo uuid;
  v_hexasilabo uuid;
  v_descripcion text := 'Diez versos de base octosilábica. Puede haber uno o varios quebrados, sobre todo en la segunda quintilla, en posición interior o final. El quebrado suele ser tetrasílabo; si tiene cinco sílabas, se interpreta mediante sinafía o compensación con el octosílabo anterior.';
  v_adicion text := ' También se documenta el hexasílabo como quebrado final.';
  v_anteriores uuid[];
  v_ficha jsonb;
begin
  select a.arquitectura_id into strict v_arquitectura
  from public.arquitecturas_forma a
  join public.formas_metricas f using (forma_id)
  where f.slug = 'copla_real' and f.activo and a.activo
    and a.slug = 'octosilabica_consonante'
    and a.unidad_versos_min = 10 and a.unidad_versos_max = 10
    and a.descripcion in (v_descripcion, v_descripcion || v_adicion);

  select esquema_metrico_id into strict v_esquema
  from public.esquemas_metricos
  where arquitectura_id = v_arquitectura and slug = '8-repetido'
    and ((tipo_secuencia = 'ciclo' and medida_uniforme is false)
      or (tipo_secuencia = 'secuencia' and medida_uniforme is null));

  select grupo_eleccion_id into strict v_grupo
  from public.grupos_eleccion_metrica
  where arquitectura_id = v_arquitectura and slug = 'posiciones_pie_quebrado'
    and activo and dimension = 'metro' and alcance = 'unidad'
    and selecciones_min = 0 and selecciones_max = 9;

  select metro_id into strict v_hexasilabo
  from public.metros where slug = 'hexasilabo' and silabas = 6 and activo;

  if (select array_agg(m.silabas order by o.orden)
      from public.esquema_metrico_opciones o join public.metros m using (metro_id)
      where o.esquema_metrico_id = v_esquema and o.rol = 'quebrado' and m.silabas <> 6)
    is distinct from array[4, 5] then
    raise exception 'Han cambiado los quebrados de la copla real';
  end if;

  select array_agg(o.opcion_eleccion_id order by o.opcion_eleccion_id) into v_anteriores
  from public.opciones_eleccion_metrica o join public.metros m using (metro_id)
  where o.grupo_eleccion_id = v_grupo and o.activo and m.silabas in (4, 5);
  if cardinality(v_anteriores) is distinct from 20 then
    raise exception 'Se esperaban opciones de cuatro y cinco sílabas en los diez versos';
  end if;

  insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, rol, orden)
  values (v_esquema, v_hexasilabo, 'quebrado', 4)
  on conflict (esquema_metrico_id, metro_id) do nothing;

  -- El ciclo desplegaba las mismas medidas en todos los versos. Declaramos las
  -- diez posiciones para ofrecer el hexasílabo solo en el lugar documentado.
  insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
  select v_esquema, n.posicion, o.metro_id, o.orden
  from public.esquema_metrico_opciones o
  cross join generate_series(1, 10) n(posicion)
  where o.esquema_metrico_id = v_esquema
    and (o.metro_id <> v_hexasilabo or n.posicion = 10)
  on conflict (esquema_metrico_id, posicion, alternativa) do nothing;

  update public.esquemas_metricos
  set tipo_secuencia = 'secuencia', medida_uniforme = null
  where esquema_metrico_id = v_esquema and tipo_secuencia = 'ciclo';

  update public.arquitecturas_forma
  set descripcion = v_descripcion || v_adicion
  where arquitectura_id = v_arquitectura and descripcion = v_descripcion;

  if (select array_agg(o.opcion_eleccion_id order by o.opcion_eleccion_id)
      from public.opciones_eleccion_metrica o join public.metros m using (metro_id)
      where o.grupo_eleccion_id = v_grupo and o.activo and m.silabas in (4, 5))
    is distinct from v_anteriores then
    raise exception 'Han cambiado las opciones existentes de la copla real';
  end if;

  if (select array_agg(o.posicion_unidad order by o.posicion_unidad)
      from public.opciones_eleccion_metrica o
      where o.grupo_eleccion_id = v_grupo and o.activo and o.metro_id = v_hexasilabo)
    is distinct from array[10] then
    raise exception 'El hexasílabo debe ofrecerse solo en el décimo verso';
  end if;

  v_ficha := public.get_forma_metrica_publica_jerarquica('copla_real');
  if not exists (
    select 1 from jsonb_array_elements(v_ficha->'opcionesEleccion') o
    where (o->>'grupo_eleccion_id')::uuid = v_grupo and (o->>'metro_id')::uuid = v_hexasilabo
  ) then
    raise exception 'La ficha pública de copla real no recoge el quebrado hexasílabo';
  end if;
end;
$copla_real$;

commit;
