-- La endecasílaba del terceto dice lo suyo
--
-- Repaso de la ficha después de bajar el terceto al arte menor. Con tres arquitecturas donde antes
-- había una, la endecasilábica quedó **como la única muda** —sin descripción, entre dos que sí
-- dicen qué son— y con un nombre que arrastra un régimen que ya no declara: se llamaba
-- «Endecasilábica consonante» cuando el régimen vivía arriba, y desde ayer lo declaran sus
-- disposiciones, como en las otras dos.
--
-- Se le pone la descripción que le faltaba y el nombre se alinea con sus hermanas. **El slug no se
-- toca**: lo referencian las secciones del soneto y del septeto.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_n integer;

	c_descripcion constant text :=
		'El terceto de arte mayor, y el que entra en la composición de otras formas: los dos del '
		|| 'soneto y el que cierra el septeto compuesto. Dos de sus versos riman en consonante y el '
		|| 'tercero queda suelto, de modo que aislado no se sostiene: lo normal es que se suceda en '
		|| 'serie o que otra forma lo recoja.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'terceto';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica_consonante';
	if v_arq is null then
		raise exception 'No aparece la arquitectura endecasilábica del terceto.';
	end if;

	update public.arquitecturas_forma set
		nombre = 'Endecasilábica',
		descripcion = c_descripcion
	where arquitectura_id = v_arq;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Las tres dicen qué son, y ninguna repite el régimen en el nombre teniéndolo abajo.
	select count(*) into v_n
	from public.arquitecturas_forma
	where forma_id = v_forma and activo and descripcion is not null;
	if v_n <> 3 then
		raise exception 'Solo % de las tres arquitecturas del terceto se describe.', v_n;
	end if;
	if exists (
		select 1 from public.arquitecturas_forma
		where forma_id = v_forma and activo
			and (nombre ilike '%consonante%' or nombre ilike '%asonante%')
	) then
		raise exception 'Alguna arquitectura del terceto sigue nombrando su régimen.';
	end if;

	-- Y el slug sigue donde las otras formas lo buscan.
	select count(*) into v_n
	from public.estructuras_secciones where arquitectura_referenciada_id = v_arq;
	if v_n <> 2 then
		raise exception 'La endecasilábica la referencian % secciones, no las dos.', v_n;
	end if;

	if public.get_forma_metrica_publica('terceto') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del terceto ha dejado de responder.';
	end if;
end $$;

commit;
