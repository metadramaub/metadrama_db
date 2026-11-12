-- El esquema escrito de una sección se mide en su sección.
--
-- **El fallo.** En el soneto, los dos esquemas de rima —cuartetos y tercetos— no se guardan en cada
-- parte sino una vez en la unidad, con `seccion_tratada_id` diciendo de qué sección hablan: así los
-- dos tercetos pueden compartir rimas, como en `CDE ECD`. Elegido de la lista, el esquema se
-- guardaba. **Escrito a mano, no había manera**: este disparador medía la notación contra la
-- realización donde se guarda, que es el soneto entero, y exigía catorce posiciones; el formulario,
-- que sí lee `seccion_tratada_id`, exigía seis. Ninguna longitud pasaba las dos. Lo encontró una
-- editora en noviembre de 2026 con unos tercetos `CDEECD` que el repertorio no tiene.
--
-- **El arreglo.** Cuando la respuesta trata de una sección, la longitud que se exige es la suma de
-- las realizaciones de esa sección dentro de la realización que la guarda: seis en los tercetos,
-- ocho en los cuartetos. Es lo mismo que calcula el formulario (`versosDelEsquema`). Si la unidad
-- no tiene realizaciones de esa sección, se sigue midiendo la realización entera, como antes.
--
-- Nada más cambia: el resto de la función es el de `20260903100000`, copiado tal cual. No toca
-- datos; la guarda de abajo guarda un soneto de prueba y lo deshace.

begin;

create or replace function public.validar_anotacion_eleccion()
 returns trigger
 language plpgsql
 set search_path to 'public'
as $function$
declare
	v_arquitectura uuid;
	v_seccion_unidad uuid;
	v_padre uuid;
	v_longitud integer;
	v_entidades integer;
	v_escrito integer;
	v_admitida boolean;
	v_control text;
	v_medidas text[];
	v_desde integer;
	v_hasta integer;
	v_de_la_seccion integer;
begin
	select arquitectura_id, v_fin - v_ini + 1
	into v_arquitectura, v_longitud
	from public.anotaciones_metricas
	where anotacion_id = new.anotacion_id;

	v_entidades := num_nonnulls(
		new.metro_id, new.esquema_metrico_id, new.esquema_rima_id, new.seccion_id,
		new.repeticion_id, new.valor_rasgo_id, new.variedad_id
	);

	if v_entidades = 0 and new.valor_texto is null then
		raise exception 'Una respuesta sin dato no se guarda';
	end if;

	if new.realizacion_id is not null then
		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1, v_ini, v_fin
		into v_seccion_unidad, v_padre, v_longitud, v_desde, v_hasta
		from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_id and anotacion_id = new.anotacion_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
	end if;

	-- Un tramo sin forma no declara arquitectura: su respuesta se sostiene sola.
	if v_arquitectura is null then
		return new;
	end if;

	if v_entidades = 1 then
		-- ¿La ofrece el catálogo? Se busca entre las preguntas de la arquitectura, **heredadas
		-- incluidas**: ya no hace falta preguntar aparte por lo que la parte reutiliza.
		select exists (
			select 1
			from public.opciones_eleccion_metrica o
			join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
			where g.activo
				and g.arquitectura_id = v_arquitectura
				and g.dimension = new.dimension
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and g.seccion_id is not distinct from (
					case when v_padre is not null then v_seccion_unidad end
				)
				and o.metro_id is not distinct from new.metro_id
				and o.esquema_metrico_id is not distinct from new.esquema_metrico_id
				and o.esquema_rima_id is not distinct from new.esquema_rima_id
				and o.seccion_id is not distinct from new.seccion_id
				and o.repeticion_id is not distinct from new.repeticion_id
				and o.valor_rasgo_id is not distinct from new.valor_rasgo_id
				and o.variedad_id is not distinct from new.variedad_id
				and o.posicion_unidad is not distinct from new.posicion_unidad
		) into v_admitida;

		if not v_admitida then
			raise exception 'La respuesta no está admitida por la norma de esta arquitectura en la dimensión %', new.dimension;
		end if;
	else
		-- **Qué se ha escrito lo dice el control de la pregunta**, no la dimensión: una notación de
		-- rima se lee letra a letra y una serie de medidas, número a número.
		select g.tipo_control
		into v_control
		from public.preguntas_metricas g
		where g.activo
			and g.arquitectura_id = v_arquitectura
			and g.dimension = new.dimension
			and g.tipo_control in ('esquema_rima', 'opciones_y_esquema', 'serie_medidas')
			and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
			and g.seccion_id is not distinct from (
				case when v_padre is not null then v_seccion_unidad end
			)
		limit 1;

		if v_control is null then
			raise exception 'Esta arquitectura no admite escribir la respuesta en la dimensión %', new.dimension;
		end if;

		-- **Lo que habla de una sección se mide en esa sección.** Los tercetos del soneto se
		-- guardan en el soneto, pero lo escrito describe sus seis versos, no los catorce.
		if new.seccion_tratada_id is not null and new.realizacion_id is not null then
			select sum(r.v_fin - r.v_ini + 1)
			into v_de_la_seccion
			from public.anotacion_realizaciones r
			where r.anotacion_id = new.anotacion_id
				and r.seccion_id = new.seccion_tratada_id
				and r.v_ini >= v_desde
				and r.v_fin <= v_hasta;

			if v_de_la_seccion is not null and v_de_la_seccion > 0 then
				v_longitud := v_de_la_seccion;
			end if;
		end if;

		if v_control = 'serie_medidas' then
			-- Una medida por verso, separadas por espacios: `11 7 11 11 7`.
			v_medidas := regexp_split_to_array(btrim(new.valor_texto), '\s+');
			if exists (select 1 from unnest(v_medidas) medida where medida !~ '^[0-9]{1,2}$') then
				raise exception 'La serie de medidas solo admite números de una o dos cifras, y trae «%»', new.valor_texto;
			end if;
			v_escrito := coalesce(array_length(v_medidas, 1), 0);
			if v_longitud is not null and v_escrito <> v_longitud then
				raise exception 'La serie debe traer % medidas, una por verso, y trae %', v_longitud, v_escrito;
			end if;
		else
			-- Una notación se lee verso a verso. Se descuentan los separadores que la propia notación
			-- trae —`abcabc|defdef`, `abba:cdcd`— y los espacios.
			v_escrito := length(regexp_replace(new.valor_texto, '[:|[:space:]]', '', 'g'));
			if v_longitud is not null and v_escrito <> v_longitud then
				raise exception 'El esquema de rima debe tener % posiciones y tiene %', v_longitud, v_escrito;
			end if;
		end if;
	end if;

	return new;
end;
$function$;

-- La guarda **ejecuta** lo que toca: guarda un soneto de prueba con los tercetos escritos y los
-- cuartetos elegidos, comprueba que una notación de cinco letras sigue fallando, y lo deshace todo.
do $guarda$
declare
 v_admin uuid;
 v_escenario uuid;
 v_anotacion uuid;
 v_unidad uuid := gen_random_uuid();
 v_forma uuid;
 v_arquitectura uuid;
 v_cuarteto uuid;
 v_terceto uuid;
 v_opcion_cuartetos uuid;
 v_unidades jsonb;
 v_sub text := current_setting('request.jwt.claim.sub', true);
 v_claims text := current_setting('request.jwt.claims', true);
 v_fallo text;
begin
 select e.user_id into v_admin from public.editores e join public.vocabularios v on v.termino_id = e.role
 where coalesce(e.activo, true) and lower(v.termino) in ('admin', 'ip') order by e.created_at limit 1;

 select a.forma_id, a.arquitectura_id into v_forma, v_arquitectura
 from public.formas_metricas f join public.arquitecturas_forma a using (forma_id)
 where f.slug = 'soneto' and a.slug = 'endecasilabica_consonante' and a.activo;

 select seccion_id into v_cuarteto from public.estructuras_secciones
 where arquitectura_id = v_arquitectura and slug = 'cuarteto';
 select seccion_id into v_terceto from public.estructuras_secciones
 where arquitectura_id = v_arquitectura and slug = 'terceto';

 select o.opcion_eleccion_id into v_opcion_cuartetos
 from public.preguntas_metricas g join public.opciones_eleccion_metrica o using (grupo_eleccion_id)
 join public.esquemas_rima r using (esquema_rima_id)
 where g.arquitectura_id = v_arquitectura and g.seccion_tratada_id = v_cuarteto
  and r.notacion = 'ABBA ABBA' limit 1;

 if v_admin is null or v_arquitectura is null or v_cuarteto is null or v_terceto is null
  or v_opcion_cuartetos is null then
  raise exception 'Faltan identidad o catálogo para ejecutar la guarda';
 end if;

 -- El soneto como lo guarda el editor: la unidad y, colgando de ella, dos cuartetos y dos tercetos.
 v_unidades := jsonb_build_array(
  jsonb_build_object('realizacion_id', v_unidad, 'orden', 1, 'v_ini', 1, 'v_fin', 14),
  jsonb_build_object('realizacion_id', gen_random_uuid(), 'realizacion_padre_id', v_unidad,
   'seccion_id', v_cuarteto, 'orden', 2, 'v_ini', 1, 'v_fin', 4),
  jsonb_build_object('realizacion_id', gen_random_uuid(), 'realizacion_padre_id', v_unidad,
   'seccion_id', v_cuarteto, 'orden', 3, 'v_ini', 5, 'v_fin', 8),
  jsonb_build_object('realizacion_id', gen_random_uuid(), 'realizacion_padre_id', v_unidad,
   'seccion_id', v_terceto, 'orden', 4, 'v_ini', 9, 'v_fin', 11),
  jsonb_build_object('realizacion_id', gen_random_uuid(), 'realizacion_padre_id', v_unidad,
   'seccion_id', v_terceto, 'orden', 5, 'v_ini', 12, 'v_fin', 14)
 );

 perform set_config('request.jwt.claim.sub', v_admin::text, true);
 perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

 -- 1. Tercetos escritos con sus seis letras: se guardan.
 begin
  insert into public.anotacion_escenarios_prueba (nombre, created_by, updated_by)
  values ('Guarda transitoria del soneto escrito', v_admin, v_admin) returning escenario_id into v_escenario;
  v_anotacion := public.guardar_anotacion_metrica(jsonb_build_object(
   'escenario_id', v_escenario, 'forma_id', v_forma, 'arquitectura_id', v_arquitectura,
   'orden', 1, 'v_ini', 1, 'v_fin', 14, 'unidades', v_unidades,
   'elecciones', jsonb_build_array(
    jsonb_build_object('realizacion_id', v_unidad, 'dimension', 'rima',
     'seccion_tratada_id', v_cuarteto, 'opcion_eleccion_id', v_opcion_cuartetos),
    jsonb_build_object('realizacion_id', v_unidad, 'dimension', 'rima',
     'seccion_tratada_id', v_terceto, 'valor_texto', 'CDEECD'))));
  set constraints all immediate;
  if not exists (
   select 1 from public.anotacion_elecciones
   where anotacion_id = v_anotacion and seccion_tratada_id = v_terceto and valor_texto = 'CDEECD'
  ) then
   raise exception 'La guarda no ha conservado los tercetos escritos';
  end if;
  if not exists (
   select 1 from public.anotacion_elecciones
   where anotacion_id = v_anotacion and seccion_tratada_id = v_cuarteto and esquema_rima_id is not null
  ) then
   raise exception 'La guarda no ha conservado los cuartetos elegidos';
  end if;
  raise exception using errcode = 'ZX001', message = 'Deshacer solamente los datos de la guarda';
 exception when sqlstate 'ZX001' then null;
 end;

 -- 2. Cinco letras para seis versos: sigue fallando, y dice seis.
 v_fallo := null;
 begin
  insert into public.anotacion_escenarios_prueba (nombre, created_by, updated_by)
  values ('Guarda transitoria del soneto mal escrito', v_admin, v_admin) returning escenario_id into v_escenario;
  perform public.guardar_anotacion_metrica(jsonb_build_object(
   'escenario_id', v_escenario, 'forma_id', v_forma, 'arquitectura_id', v_arquitectura,
   'orden', 1, 'v_ini', 1, 'v_fin', 14, 'unidades', v_unidades,
   'elecciones', jsonb_build_array(
    jsonb_build_object('realizacion_id', v_unidad, 'dimension', 'rima',
     'seccion_tratada_id', v_cuarteto, 'opcion_eleccion_id', v_opcion_cuartetos),
    jsonb_build_object('realizacion_id', v_unidad, 'dimension', 'rima',
     'seccion_tratada_id', v_terceto, 'valor_texto', 'CDEEC'))));
  raise exception using errcode = 'ZX001', message = 'Deshacer solamente los datos de la guarda';
 exception
  when sqlstate 'ZX001' then v_fallo := 'se guardó';
  when others then v_fallo := sqlerrm;
 end;
 if v_fallo is distinct from 'El esquema de rima debe tener 6 posiciones y tiene 5' then
  raise exception 'Los tercetos mal escritos deberían fallar pidiendo seis posiciones, y: %', v_fallo;
 end if;

 perform set_config('request.jwt.claim.sub', coalesce(v_sub, ''), true);
 perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);
end $guarda$;

commit;
