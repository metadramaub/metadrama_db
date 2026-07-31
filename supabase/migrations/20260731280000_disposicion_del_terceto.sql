begin;

-- El terceto elige su disposición.
--
-- Al disolverse `tercetos_sin_encadenar`, sus dos disposiciones pasaron al terceto, pero
-- se quedaron sin la pregunta que las distingue: la arquitectura ofrecía dos esquemas y
-- ninguna manera de decir cuál se observa. Y sus notaciones seguían escritas como serie
-- —`A-A | B-B | C-C | …`— cuando el esquema describe ya una sola estrofa: cuántos tercetos
-- contiene el pasaje lo dice el rango.

update public.esquemas_rima
set notacion = case slug when 'verso-central-suelto' then 'A-A' else '-AA' end
where slug in ('verso-central-suelto', 'primer-verso-suelto')
	and arquitectura_id = (
		select arquitectura.arquitectura_id
		from public.arquitecturas_forma arquitectura
		join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
		where forma.slug = 'terceto' and arquitectura.slug = 'endecasilabico_consonante'
	);

do $$
declare
	v_terceto uuid;
	v_grupo uuid;
begin
	select arquitectura.arquitectura_id into v_terceto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto' and arquitectura.slug = 'endecasilabico_consonante';

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_terceto, 'disposicion_rima', '¿Qué verso queda suelto?',
		'En el terceto suelto riman dos de los tres versos. Señala cuál queda sin pareja.',
		'rima', 'unidad', 'opciones', 1, 1, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id, slug, nombre, descripcion, esquema_rima_id, orden
	)
	select
		v_grupo,
		case esquema.slug when 'verso-central-suelto' then 'central' else 'primero' end,
		esquema.nombre,
		case esquema.slug
			when 'verso-central-suelto' then 'Riman el primero y el tercero: A-A.'
			else 'Riman el segundo y el tercero: -AA.'
		end,
		esquema.esquema_rima_id,
		case esquema.slug when 'verso-central-suelto' then 1 else 2 end
	from public.esquemas_rima esquema
	where esquema.arquitectura_id = v_terceto
		and esquema.slug in ('verso-central-suelto', 'primer-verso-suelto');
end;
$$;

do $$
declare
	v_opciones integer;
begin
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto' and grupo.slug = 'disposicion_rima';
	if v_opciones <> 2 then
		raise exception 'El terceto debe ofrecer dos disposiciones y ofrece %', v_opciones;
	end if;
end;
$$;

commit;
