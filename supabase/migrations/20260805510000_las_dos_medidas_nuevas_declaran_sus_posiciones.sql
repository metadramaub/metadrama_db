-- Las dos medidas nuevas de la endecha real declaran sus posiciones.
--
-- Los esquemas `7-7-7-7-11` y `6-6-6-11` se crearon con nombre, descripción y `tipo_secuencia
-- = 'ciclo'`, pero sin posiciones: el nombre decía la medida y el dato no la decía. La
-- auditoría lo señaló como **D3 · patrón métrico sin posiciones ni opciones**, y tiene razón —
-- un ciclo sin posiciones no es computable, y el demarcador no podría comprobar ninguna de las
-- dos arquitecturas.
--
-- Es el mismo contenido que ya tenía `7-7-7-11`, que sí las declaraba: un metro por posición.

begin;

do $$
declare
	v_forma uuid;
	v_hepta uuid;
	v_hexa uuid;
	v_endeca uuid;
	v_cinco uuid;
	v_seis uuid;
	v_mal integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecha_real';

	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_hexa from public.metros where slug = 'hexasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';

	if v_hepta is null or v_hexa is null or v_endeca is null then
		raise exception 'Falta alguno de los tres metros: heptasílabo, hexasílabo o endecasílabo';
	end if;

	select em.esquema_metrico_id into v_cinco
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	where a.forma_id = v_forma and em.nombre = '7-7-7-7-11';

	select em.esquema_metrico_id into v_seis
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	where a.forma_id = v_forma and em.nombre = '6-6-6-11';

	if v_cinco is null or v_seis is null then
		raise exception 'No están los esquemas 7-7-7-7-11 y 6-6-6-11';
	end if;

	delete from public.esquema_metrico_posiciones where esquema_metrico_id in (v_cinco, v_seis);

	-- La redondilla heptasílaba y su endecasílabo.
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, alternativa, metro_id, opcional)
	values
		(v_cinco, 1, 1, v_hepta, false),
		(v_cinco, 2, 1, v_hepta, false),
		(v_cinco, 3, 1, v_hepta, false),
		(v_cinco, 4, 1, v_hepta, false),
		(v_cinco, 5, 1, v_endeca, false);

	-- Los tres hexasílabos y su endecasílabo.
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, alternativa, metro_id, opcional)
	values
		(v_seis, 1, 1, v_hexa, false),
		(v_seis, 2, 1, v_hexa, false),
		(v_seis, 3, 1, v_hexa, false),
		(v_seis, 4, 1, v_endeca, false);

	-- Comprobación: los tres esquemas de la forma declaran tantas posiciones como dice su
	-- nombre, y la última es siempre el endecasílabo que da nombre a la forma.
	select count(*) into v_mal
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	where a.forma_id = v_forma
		and (select count(*) from public.esquema_metrico_posiciones p
		     where p.esquema_metrico_id = em.esquema_metrico_id)
		    <> array_length(string_to_array(em.nombre, '-'), 1);
	if v_mal > 0 then
		raise exception '% esquemas métricos no declaran tantas posiciones como dice su nombre', v_mal;
	end if;

	select count(*) into v_mal
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	where a.forma_id = v_forma
		and not exists (
			select 1 from public.esquema_metrico_posiciones p
			where p.esquema_metrico_id = em.esquema_metrico_id
				and p.metro_id = v_endeca
				and p.posicion = (select max(q.posicion) from public.esquema_metrico_posiciones q
				                  where q.esquema_metrico_id = em.esquema_metrico_id)
		);
	if v_mal > 0 then
		raise exception '% esquemas de la endecha real no cierran en endecasílabo', v_mal;
	end if;

	raise notice 'Endecha real · posiciones métricas de 7-7-7-7-11 y 6-6-6-11 declaradas';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
