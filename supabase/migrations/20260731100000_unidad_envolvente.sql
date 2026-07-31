begin;

-- La unidad envolvente: cierre del bloque C de la migración estructural.
--
-- El bloque C dejó que la unidad se declarara y retiró las nueve secciones que solo
-- servían para decir que se repite. Quedaron sin resolver dos formas de expresar lo mismo:
-- en unas arquitecturas la unidad era una sección raíz que contenía a las demás —«copla
-- real», «novena», «sextina», «canción»—, y en otras no era ninguna sección. Las que
-- tienen varias secciones raíz —soneto, villancico, zéjel, seguidilla compuesta— no podían
-- por eso registrar más de una unidad por secuencia: nada agrupaba sus raíces, y un pasaje
-- de tres sonetos seguidos no se podía delimitar.
--
-- Catorce secciones eran en realidad la unidad. Ninguna lleva esquema métrico, esquema de
-- rima ni arquitectura referenciada: solo una nota que explica de qué se compone la unidad,
-- que es justo lo que la extensión declarada y las partes ya dicen. Se disuelven, y sus
-- partes pasan a ser las partes de la unidad.
--
-- Queda una sola regla, sin excepciones: **la unidad es la realización que no cuelga de
-- ninguna otra, y toda sección se realiza dentro de una unidad.** Una realización sin
-- sección es la unidad; una realización con sección es una parte de su interior.

-- ---------------------------------------------------------------------------
-- 1 · Las secciones que eran la unidad se disuelven
-- ---------------------------------------------------------------------------

create temporary table secciones_que_eran_la_unidad on commit drop as
select seccion.seccion_id
from public.estructuras_secciones seccion
join public.arquitecturas_forma arquitectura
	on arquitectura.arquitectura_id = seccion.arquitectura_id
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where forma.nivel_estructural <> 'serie'
	and seccion.seccion_padre_id is null
	and 1 = (
		select count(*)
		from public.estructuras_secciones raiz
		where raiz.arquitectura_id = seccion.arquitectura_id
			and raiz.seccion_padre_id is null
	)
	and exists (
		select 1
		from public.estructuras_secciones hija
		where hija.seccion_padre_id = seccion.seccion_id
	);

do $$
declare
	v_total integer;
	v_con_contenido integer;
begin
	select count(*) into v_total from secciones_que_eran_la_unidad;
	if v_total <> 14 then
		raise exception 'Se esperaban 14 secciones que son la unidad y hay %', v_total;
	end if;

	-- Disolverlas solo es seguro si no aportan nada que no sea su propia existencia.
	select count(*) into v_con_contenido
	from public.estructuras_secciones seccion
	where seccion.seccion_id in (select seccion_id from secciones_que_eran_la_unidad)
		and (
			seccion.esquema_metrico_id is not null
			or seccion.esquema_rima_id is not null
			or seccion.arquitectura_referenciada_id is not null
		);
	if v_con_contenido > 0 then
		raise exception
			'% secciones de la unidad declaran esquemas o reutilizan otra arquitectura y no pueden disolverse',
			v_con_contenido;
	end if;
end;
$$;

-- Las preguntas ancladas en ellas se refieren a la unidad entera, no a una parte suya.
update public.grupos_eleccion_metrica
set seccion_id = null
where seccion_id in (select seccion_id from secciones_que_eran_la_unidad);

-- El orden de las partes promovidas es el que ya tenían; se aparta el contenedor para no
-- chocar con la unicidad de (arquitectura, sección superior, orden).
update public.estructuras_secciones
set orden = orden + 1000
where seccion_id in (select seccion_id from secciones_que_eran_la_unidad);

update public.estructuras_secciones
set seccion_padre_id = null
where seccion_padre_id in (select seccion_id from secciones_que_eran_la_unidad);

delete from public.estructuras_secciones
where seccion_id in (select seccion_id from secciones_que_eran_la_unidad);

-- ---------------------------------------------------------------------------
-- 2 · La unidad es la realización que no cuelga de ninguna otra
-- ---------------------------------------------------------------------------

alter table public.realizaciones_editor_metrico
	drop constraint realizaciones_editor_metrico_unidad_check;

alter table public.realizaciones_editor_metrico
	add constraint realizaciones_editor_metrico_unidad_check check (
		(seccion_id is null) = (realizacion_padre_id is null)
	);

comment on column public.realizaciones_editor_metrico.seccion_id is
	'Sección realizada. Nula exactamente cuando la realización es la de la unidad que define la forma, que no es parte de nada y no cuelga de ninguna otra.';

create or replace function public.validar_unidad_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
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
	select arquitectura_id, v_ini, v_fin
	into v_configuracion_id, v_secuencia_ini, v_secuencia_fin
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La unidad debe quedar dentro del rango de la secuencia';
	end if;

	-- Una realización sin sección es la realización de la unidad que define la forma.
	if new.seccion_id is null then
		if new.realizacion_padre_id is not null then
			raise exception 'La realización de la unidad no cuelga de ninguna otra';
		end if;
		return new;
	end if;

	select seccion_padre_id
	into v_seccion_padre_esperada
	from public.estructuras_secciones
	where seccion_id = new.seccion_id
		and arquitectura_id = v_configuracion_id;

	if not found then
		raise exception 'La sección de la unidad no pertenece a la arquitectura seleccionada';
	end if;

	if new.realizacion_padre_id is null then
		raise exception 'Una sección se realiza siempre dentro de una unidad';
	end if;

	select seccion_id, v_ini, v_fin
	into v_seccion_padre_real, v_padre_ini, v_padre_fin
	from public.realizaciones_editor_metrico
	where realizacion_prueba_id = new.realizacion_padre_id
		and secuencia_prueba_id = new.secuencia_prueba_id;

	if not found then
		raise exception 'La unidad superior debe pertenecer a la misma secuencia';
	end if;
	-- Una sección raíz cuelga de la unidad, cuya realización no tiene sección; una sección
	-- interna cuelga de la realización de su sección superior.
	if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
		raise exception 'La unidad superior no corresponde a la jerarquía de la sección';
	end if;
	if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
		raise exception 'La sección interna debe quedar dentro del rango de su unidad superior';
	end if;

	return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Las secciones se cuentan dentro de la unidad, no dentro de la secuencia
--
-- Cuántas unidades contiene el pasaje lo gobierna el rango. Lo que la repetición de una
-- sección declara es cuántas veces aparece dentro de cada unidad.
-- ---------------------------------------------------------------------------

create or replace function public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid)
returns void
language plpgsql
set search_path to 'public'
as $$
declare
	v_configuracion_id uuid;
	v_seccion record;
	v_padre record;
	v_total integer;
begin
	select arquitectura_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = p_secuencia_id;

	if v_configuracion_id is null then
		return;
	end if;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where arquitectura_id = v_configuracion_id
			and seccion_padre_id is null
	loop
		for v_padre in
			select realizacion_prueba_id
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and realizacion_padre_id is null
				and seccion_id is null
		loop
			select count(*) into v_total
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and realizacion_padre_id = v_padre.realizacion_prueba_id
				and seccion_id = v_seccion.seccion_id;

			if v_total < coalesce(v_seccion.repeticiones_min, 0) then
				raise exception 'Cada unidad necesita al menos % realizaciones de «%»',
					v_seccion.repeticiones_min,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
			if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
				raise exception 'Cada unidad admite como máximo % realizaciones de «%»',
					v_seccion.repeticiones_max,
					coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
			end if;
		end loop;
	end loop;

	for v_seccion in
		select *
		from public.estructuras_secciones
		where arquitectura_id = v_configuracion_id
			and seccion_padre_id is not null
	loop
		for v_padre in
			select realizacion_prueba_id
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and seccion_id = v_seccion.seccion_padre_id
		loop
			select count(*) into v_total
			from public.realizaciones_editor_metrico
			where secuencia_prueba_id = p_secuencia_id
				and realizacion_padre_id = v_padre.realizacion_prueba_id
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

comment on function public.validar_estructura_secuencia_editor_metrico(uuid) is
	'Comprueba la repetición declarada de cada sección dentro de la unidad que la contiene. Cuántas unidades contiene la secuencia no se comprueba aquí: se deriva del rango.';

update public.catalogo_metrico_estado
set modelo_version = 46,
	actualizado_en = now()
where id = true;

commit;
