begin;

-- Una respuesta puede activar una sección material que necesite localizarse.
-- Es distinto del valor normalizado de la respuesta: por ejemplo, la
-- repetición total apunta a un patrón de repetición y, además, materializa un
-- estribillo. Si su extensión se deriva de otra sección, también se declara.
alter table public.opciones_eleccion_metrica
	add column materializa_seccion_id uuid null
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict,
	add column extension_desde_seccion_id uuid null
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict;

comment on column public.opciones_eleccion_metrica.materializa_seccion_id is
	'Sección cuya realización y rango debe solicitar el editor al seleccionar esta opción.';

comment on column public.opciones_eleccion_metrica.extension_desde_seccion_id is
	'Sección realizada cuya longitud se reutiliza para la sección materializada.';

create or replace function public.validar_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_dimension text;
	v_alcance text;
	v_seccion_grupo uuid;
	v_configuracion_id uuid;
	v_objetivo_configuracion_id uuid;
	v_materializa_configuracion_id uuid;
	v_materializa_padre_id uuid;
	v_extension_configuracion_id uuid;
	v_rasgo_id uuid;
begin
	select dimension, alcance, seccion_id, configuracion_id
	into v_dimension, v_alcance, v_seccion_grupo, v_configuracion_id
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id;

	if v_dimension = 'metro' and num_nonnulls(new.metro_id, new.patron_metrico_id) <> 1 then
		raise exception 'Una opción de medida debe apuntar a un metro o patrón métrico';
	elsif v_dimension = 'rima' and new.patron_rima_id is null then
		raise exception 'Una opción de rima debe apuntar a un patrón de rima';
	elsif v_dimension = 'estructura' and new.seccion_id is null then
		raise exception 'Una opción estructural debe apuntar a una sección';
	elsif v_dimension = 'repeticion' and new.patron_repeticion_id is null then
		raise exception 'Una opción de repetición debe apuntar a un patrón de repetición';
	elsif v_dimension = 'rasgo' and num_nonnulls(new.rasgo_id, new.valor_rasgo_id) <> 1 then
		raise exception 'Una opción de rasgo debe apuntar a un rasgo booleano o a un valor controlado';
	end if;

	if new.patron_metrico_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_metricos where patron_metrico_id = new.patron_metrico_id;
	elsif new.patron_rima_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_rima where patron_rima_id = new.patron_rima_id;
	elsif new.seccion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.estructuras_secciones where seccion_id = new.seccion_id;
	elsif new.patron_repeticion_id is not null then
		select configuracion_id into v_objetivo_configuracion_id
		from public.patrones_repeticion where patron_repeticion_id = new.patron_repeticion_id;
	elsif new.valor_rasgo_id is not null then
		select rasgo_id into v_rasgo_id
		from public.rasgo_valores where valor_id = new.valor_rasgo_id;
	end if;

	if v_objetivo_configuracion_id is not null
		and v_objetivo_configuracion_id is distinct from v_configuracion_id
	then
		raise exception 'La opción no pertenece a la configuración del grupo';
	end if;

	if new.materializa_seccion_id is not null then
		select configuracion_id, seccion_padre_id
		into v_materializa_configuracion_id, v_materializa_padre_id
		from public.estructuras_secciones
		where seccion_id = new.materializa_seccion_id;

		if v_materializa_configuracion_id is distinct from v_configuracion_id then
			raise exception 'La sección materializada no pertenece a la configuración del grupo';
		end if;

		if v_alcance = 'unidad'
			and v_materializa_padre_id is distinct from v_seccion_grupo
		then
			raise exception 'La sección materializada debe depender de la unidad donde se responde';
		elsif v_alcance = 'secuencia' and v_materializa_padre_id is not null then
			raise exception 'Una elección de secuencia solo puede materializar una sección superior';
		end if;
	elsif new.extension_desde_seccion_id is not null then
		raise exception 'No se puede derivar una extensión sin materializar una sección';
	end if;

	if new.extension_desde_seccion_id is not null then
		select configuracion_id into v_extension_configuracion_id
		from public.estructuras_secciones
		where seccion_id = new.extension_desde_seccion_id;

		if v_extension_configuracion_id is distinct from v_configuracion_id then
			raise exception 'La sección de referencia no pertenece a la configuración del grupo';
		end if;
	end if;

	if v_dimension = 'rasgo' then
		v_rasgo_id := coalesce(new.rasgo_id, v_rasgo_id);
		if not exists (
			select 1
			from public.configuracion_rasgos
			where configuracion_id = v_configuracion_id
				and rasgo_id = v_rasgo_id
		) then
			raise exception 'El rasgo de la opción no está admitido por la configuración';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_unidad_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_id uuid;
	v_secuencia_ini integer;
	v_secuencia_fin integer;
	v_seccion_padre_esperada uuid;
	v_seccion_padre_real uuid;
	v_padre_ini integer;
	v_padre_fin integer;
begin
	select configuracion_id, v_ini, v_fin
	into v_configuracion_id, v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select seccion_padre_id
	into v_seccion_padre_esperada
	from public.estructuras_secciones
	where seccion_id = new.seccion_id
		and configuracion_id = v_configuracion_id;

	if not found then
		raise exception 'La sección de la unidad no pertenece a la configuración seleccionada';
	end if;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La unidad debe quedar dentro del rango de la secuencia';
	end if;

	if new.unidad_padre_id is null then
		if v_seccion_padre_esperada is not null then
			raise exception 'La sección interna necesita su unidad superior';
		end if;
	else
		select seccion_id, v_ini, v_fin
		into v_seccion_padre_real, v_padre_ini, v_padre_fin
		from public.unidades_editor_metrico
		where unidad_prueba_id = new.unidad_padre_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if v_seccion_padre_real is null then
			raise exception 'La unidad superior debe pertenecer a la misma secuencia';
		end if;
		if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
			raise exception 'La unidad superior no corresponde a la jerarquía de la sección';
		end if;
		if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
			raise exception 'La sección interna debe quedar dentro del rango de su unidad superior';
		end if;
	end if;

	return new;
end;
$$;

create or replace function public.validar_estructura_secuencia_editor_metrico(
	p_secuencia_id uuid
)
returns void
language plpgsql
set search_path = public
as $$
declare
	v_configuracion_id uuid;
	v_seccion record;
	v_padre record;
	v_total integer;
begin
	select configuracion_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = p_secuencia_id;

	if v_configuracion_id is null or not exists (
		select 1
		from public.estructuras_secciones
		where configuracion_id = v_configuracion_id
			and seccion_padre_id is not null
	) then
		return;
	end if;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where configuracion_id = v_configuracion_id
			and seccion_padre_id is null
	loop
		select count(*) into v_total
		from public.unidades_editor_metrico
		where secuencia_prueba_id = p_secuencia_id
			and unidad_padre_id is null
			and seccion_id = v_seccion.seccion_id;

		if v_total < coalesce(v_seccion.repeticiones_min, 0) then
			raise exception 'La sección «%» necesita al menos % realizaciones',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_min;
		end if;
		if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
			raise exception 'La sección «%» admite como máximo % realizaciones',
				coalesce(v_seccion.nombre, v_seccion.tipo_seccion),
				v_seccion.repeticiones_max;
		end if;
	end loop;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where configuracion_id = v_configuracion_id
			and seccion_padre_id is not null
	loop
		for v_padre in
			select unidad_prueba_id
			from public.unidades_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and seccion_id = v_seccion.seccion_padre_id
		loop
			select count(*) into v_total
			from public.unidades_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and unidad_padre_id = v_padre.unidad_prueba_id
				and seccion_id = v_seccion.seccion_id;

			if v_total < coalesce(v_seccion.repeticiones_min, 0) then
				raise exception 'Cada unidad superior necesita al menos % realizaciones de «%»',
					v_seccion.repeticiones_min,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
			if v_seccion.repeticiones_max is not null
				and v_total > v_seccion.repeticiones_max
			then
				raise exception 'Cada unidad superior admite como máximo % realizaciones de «%»',
					v_seccion.repeticiones_max,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
		end loop;
	end loop;
end;
$$;

create or replace function public.validar_estructura_editor_metrico_diferida()
returns trigger
language plpgsql
set search_path = public
as $$
begin
	perform public.validar_estructura_secuencia_editor_metrico(
		case when tg_op = 'DELETE' then old.secuencia_prueba_id else new.secuencia_prueba_id end
	);
	return null;
end;
$$;

drop trigger if exists trigger_validar_estructura_secuencia_diferida
	on public.secuencias_editor_metrico;
create constraint trigger trigger_validar_estructura_secuencia_diferida
after insert or update on public.secuencias_editor_metrico
deferrable initially deferred
for each row execute function public.validar_estructura_editor_metrico_diferida();

drop trigger if exists trigger_validar_estructura_unidad_diferida
	on public.unidades_editor_metrico;
create constraint trigger trigger_validar_estructura_unidad_diferida
after insert or update or delete on public.unidades_editor_metrico
deferrable initially deferred
for each row execute function public.validar_estructura_editor_metrico_diferida();

do $$
declare
	v_configuracion_id uuid;
	v_seccion_cabeza_id uuid;
	v_seccion_copla_id uuid;
	v_seccion_mudanza_id uuid;
	v_seccion_estribillo_id uuid;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'villancico'
		and configuracion.slug = 'estructura_habitual';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración habitual del villancico';
	end if;

	select seccion_id into v_seccion_cabeza_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and tipo_seccion = 'cabeza'
		and seccion_padre_id is null;

	select seccion_id into v_seccion_copla_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and tipo_seccion = 'copla'
		and seccion_padre_id is null;

	select seccion_id into v_seccion_mudanza_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and tipo_seccion = 'mudanza'
		and seccion_padre_id = v_seccion_copla_id;

	select seccion_id into v_seccion_estribillo_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and tipo_seccion = 'estribillo'
		and seccion_padre_id = v_seccion_copla_id;

	-- Las pruebas existentes pueden conservar la copla, pero deben volver a
	-- declarar el patrón en la mudanza, que es su verdadero alcance.
	delete from public.elecciones_editor_metrico eleccion
	using public.grupos_eleccion_metrica grupo
	where eleccion.grupo_eleccion_id = grupo.grupo_eleccion_id
		and grupo.configuracion_id = v_configuracion_id
		and grupo.slug in ('rima_mudanza', 'presencia_enlace', 'presencia_vuelta');

	delete from public.grupos_eleccion_metrica
	where configuracion_id = v_configuracion_id
		and slug in ('presencia_enlace', 'presencia_vuelta');

	update public.grupos_eleccion_metrica
	set
		seccion_id = v_seccion_mudanza_id,
		ayuda_editor = 'Se registra en cada mudanza. Puede aplicarse la misma respuesta a todas y corregir solo las excepciones.'
	where configuracion_id = v_configuracion_id
		and slug = 'rima_mudanza';

	update public.opciones_eleccion_metrica opcion
	set
		materializa_seccion_id = case
			when opcion.slug in ('total', 'parcial') then v_seccion_estribillo_id
			else null
		end,
		extension_desde_seccion_id = case
			when opcion.slug = 'total' then v_seccion_cabeza_id
			else null
		end
	from public.grupos_eleccion_metrica grupo
	where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
		and grupo.configuracion_id = v_configuracion_id
		and grupo.slug = 'repeticion_estribillo';
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 16,
	actualizado_en = now()
where id = true;

commit;
