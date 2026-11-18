-- Valida las posiciones de la notación y conserva el régimen escrito en el mismo valor.
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
	v_notacion text;
	v_regimen text;
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
			v_notacion := new.valor_texto;
			if new.dimension = 'rima' then
				-- El régimen se guarda con lo escrito, pero no ocupa posiciones de verso.
				if strpos(v_notacion, '·') > 0 then
					v_regimen := btrim(substr(v_notacion, strpos(v_notacion, '·') + 1));
					if v_regimen !~ '^[a-z][a-z0-9_-]*$' then
						raise exception 'El régimen de rima escrito no es válido';
					end if;
					v_notacion := split_part(v_notacion, '·', 1);
				end if;
				if v_notacion ~ '[^A-Za-z:|[:space:]-]' then
					raise exception 'El esquema de rima solo admite letras y guiones como posiciones';
				end if;
			end if;
			v_escrito := length(regexp_replace(v_notacion, '[:|[:space:]]', '', 'g'));
			if v_longitud is not null and v_escrito <> v_longitud then
				raise exception 'El esquema de rima debe tener % posiciones y tiene %', v_longitud, v_escrito;
			end if;
		end if;
	end if;

	return new;
end;
$function$;

-- La guarda pasa por el RPC y verifica el valor persistido, dentro de una subtransacción.
do $guarda$
declare
 v_admin uuid;
 v_escenario uuid;
 v_anotacion uuid;
 v_unidad uuid := gen_random_uuid();
 v_forma uuid;
 v_arquitectura uuid;
 v_vocal_a uuid;
 v_datos jsonb;
 v_sub text := current_setting('request.jwt.claim.sub', true);
 v_claims text := current_setting('request.jwt.claims', true);
 v_fallo text;
 v_texto text := '-a-a---a · asonante';
begin
 select e.user_id into v_admin from public.editores e join public.vocabularios v on v.termino_id = e.role
 where coalesce(e.activo, true) and lower(v.termino) in ('admin', 'ip') order by e.created_at limit 1;

 select a.forma_id, a.arquitectura_id into v_forma, v_arquitectura
 from public.formas_metricas f join public.arquitecturas_forma a using (forma_id)
 where f.slug = 'octava_aguda' and a.slug = 'octosilabica' and a.activo;

 select o.opcion_eleccion_id into v_vocal_a
 from public.grupos_eleccion_metrica_resueltos g
 join public.opciones_eleccion_metrica o using (grupo_eleccion_id)
 where g.arquitectura_id = v_arquitectura and g.activo
   and g.slug = 'vocales_asonancia' and o.slug = 'a';

 if v_admin is null or v_arquitectura is null or v_vocal_a is null then
  raise exception 'Faltan identidad o catálogo para ejecutar la guarda de la octava';
 end if;
 perform set_config('request.jwt.claim.sub', v_admin::text, true);
 perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

 begin
  insert into public.anotacion_escenarios_prueba (nombre, created_by, updated_by)
  values ('Guarda transitoria de la octava con régimen escrito', v_admin, v_admin) returning escenario_id into v_escenario;
  v_datos := jsonb_build_object(
   'escenario_id', v_escenario, 'forma_id', v_forma, 'arquitectura_id', v_arquitectura,
   'orden', 1, 'v_ini', 1, 'v_fin', 8,
   'unidades', jsonb_build_array(jsonb_build_object('realizacion_id', v_unidad, 'orden', 1, 'v_ini', 1, 'v_fin', 8)),
   'elecciones', jsonb_build_array(
    jsonb_build_object('realizacion_id', v_unidad, 'dimension', 'rima', 'valor_texto', v_texto),
    jsonb_build_object('dimension', 'rasgo', 'opcion_eleccion_id', v_vocal_a)));
  v_anotacion := public.guardar_anotacion_metrica(v_datos);
  set constraints all immediate;
  if not exists (
   select 1 from public.anotacion_elecciones
   where anotacion_id = v_anotacion and dimension = 'rima' and valor_texto = v_texto
  ) then
   raise exception 'La guarda no ha conservado el esquema y su régimen';
  end if;
  if not exists (
   select 1 from public.anotacion_elecciones
   where anotacion_id = v_anotacion and dimension = 'rasgo' and valor_rasgo_id is not null
  ) then
   raise exception 'La guarda no ha conservado la vocal de la asonancia';
  end if;

  begin
   perform public.guardar_anotacion_metrica(jsonb_set(v_datos || jsonb_build_object('anotacion_id', v_anotacion),
    '{elecciones,0,valor_texto}', to_jsonb('-a-a--a · asonante'::text)));
   raise exception using errcode = 'ZX002', message = 'Se guardó un esquema incompleto';
  exception
   when sqlstate 'ZX002' then raise;
   when others then v_fallo := sqlerrm;
  end;
  if v_fallo is distinct from 'El esquema de rima debe tener 8 posiciones y tiene 7' then
   raise exception 'La octava mal escrita debería fallar pidiendo ocho posiciones, y: %', v_fallo;
  end if;

  raise exception using errcode = 'ZX001', message = 'Deshacer solamente los datos de la guarda';
 exception when sqlstate 'ZX001' then null;
 end;
 perform set_config('request.jwt.claim.sub', coalesce(v_sub, ''), true);
 perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);
end $guarda$;

commit;
