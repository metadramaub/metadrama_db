-- La definición de la sextilla nombraba una disposición que el catálogo llama de otro modo.
--
-- Decía «alterna, correlativa, paralela», pero el esquema quedó registrado como «Simétrica»,
-- que es como lo escribe Navarro Tomás; «paralela» es el nombre del Diccionario para la misma
-- disposición, y consta como denominación de ese esquema. Quien lea la ficha ve la lista de la
-- definición y debajo los esquemas: los dos nombres tienen que coincidir.

begin;

do $$
declare
	v_forma uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'sextilla';
	if v_forma is null then
		raise exception 'Falta la sextilla vigente';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de seis versos de arte menor con rima consonante cuya disposición no está fijada. La tradición ha nombrado algunas de sus disposiciones —alterna, correlativa, simétrica— y admite que uno o más versos se quiebren en otros más breves, que es la variedad de la que procede la copla manriqueña.',
		updated_at = now()
	where forma_id = v_forma;

	select count(*) into v_n from public.esquemas_rima e
	join public.arquitecturas_forma a on a.arquitectura_id = e.arquitectura_id
	where a.forma_id = v_forma
		and a.slug = 'octosilabica'
		and e.nombre in ('Alterna', 'Correlativa', 'Simétrica');
	if v_n <> 3 then
		raise exception 'La definición nombra tres disposiciones que deben existir como esquema, y hay %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
