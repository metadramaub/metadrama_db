begin;

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
	v_patron_rima_id uuid;
	v_raiz_id uuid;
begin
	select forma_id into v_forma_id
	from public.formas_metricas
	where slug = 'decima_aumentada';

	select configuracion_id into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'octosilabica_abbaaccddeed';

	select patron_rima_id into v_patron_rima_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id
		and esquema = 'abbaaccddeed';

	if num_nonnulls(v_forma_id, v_configuracion_id, v_patron_rima_id) <> 3 then
		raise exception 'No se encontró completa la formalización de la décima aumentada';
	end if;

	update public.formas_metricas
	set
		definicion = 'Estrofa de doce versos octosílabos con rima consonante abbaaccddeed y pausa característica tras el cuarto verso.',
		updated_at = now()
	where forma_id = v_forma_id;

	update public.configuraciones_forma
	set
		descripcion = 'Doce octosílabos consonantes con pausa tras el cuarto verso y estructura 4 + 8.',
		updated_at = now()
	where configuracion_id = v_configuracion_id;

	update public.patrones_rima
	set
		descripcion = 'Esquema documentado de doce versos con pausa tras el primer bloque abba.',
		updated_at = now()
	where patron_rima_id = v_patron_rima_id;

	update public.patron_rima_posiciones
	set
		bloque = case when bloque = 1 then 1 else 2 end,
		seccion = case
			when bloque = 1 then 'primer_bloque'
			else 'segundo_bloque'
		end,
		posicion = case
			when bloque = 1 then posicion
			when bloque = 2 then posicion
			else posicion + 2
		end
	where patron_rima_id = v_patron_rima_id;

	delete from public.estructuras_secciones
	where configuracion_id = v_configuracion_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		nota
	)
	values (
		v_configuracion_id,
		'decima_aumentada',
		'Décima aumentada',
		1,
		1,
		null,
		'Unidad repetible de doce versos.'
	)
	returning seccion_id into v_raiz_id;

	insert into public.estructuras_secciones (
		configuracion_id,
		seccion_padre_id,
		tipo_seccion,
		nombre,
		orden,
		repeticiones_min,
		repeticiones_max,
		versos_min,
		versos_max,
		nota
	)
	values
		(
			v_configuracion_id,
			v_raiz_id,
			'primer_bloque',
			'Primer bloque',
			1,
			1,
			1,
			4,
			4,
			'Arranque abba, seguido de la pausa característica.'
		),
		(
			v_configuracion_id,
			v_raiz_id,
			'segundo_bloque',
			'Segundo bloque',
			2,
			1,
			1,
			8,
			8,
			'Continuación accddeed; no se le atribuye una subdivisión interna no declarada.'
		);

	update public.forma_relaciones
	set
		nota = 'Amplía a doce versos el esquema de la espinela. La relación conserva la denominación y el vínculo estructural documentados sin imponer una subdivisión interna adicional.',
		updated_at = now()
	where forma_origen_id = v_forma_id
		and tipo_relacion = 'derivada_de'
		and forma_destino_id = (
			select forma_id
			from public.formas_metricas
			where slug = 'decima_espinela'
		);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 26,
	actualizado_en = now()
where id = true;

commit;
