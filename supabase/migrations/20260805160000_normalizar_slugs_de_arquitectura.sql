-- Los slugs de arquitectura concuerdan también en femenino, y una mayúscula que se perdió.
--
-- Al llevar los nombres al femenino quedó a la vista que los slugs arrastraban la misma
-- discrepancia: el soneto y los tercetos declaran `endecasilabico_consonante` y la octava
-- real `endecasilabica_consonante`, para lo mismo. El romance, igual: `octosilabico` frente
-- al `octosilabica` de la redondilla y la sextilla.
--
-- Nada del código busca arquitecturas por slug —solo un ejemplo de la guía y un metro en un
-- test—, así que se pueden igualar de una vez, que es como la revisión de nomenclatura dice
-- que deben cambiar.
--
-- Y el nombre del terceto encadenado octosilábico quedó con minúscula inicial: al quitarle
-- el nombre de su forma, lo que seguía era ya minúscula.

begin;

do $$
declare
	v_slugs integer;
	v_mayuscula integer;
	v_restantes integer;
begin
	update public.arquitecturas_forma
	set slug = replace(slug, 'silabico', 'silabica')
	where slug like '%silabico%';
	get diagnostics v_slugs = row_count;

	-- Una inicial en minúscula solo puede venir de haber recortado el nombre de la forma.
	update public.arquitecturas_forma
	set nombre = upper(left(nombre, 1)) || substring(nombre from 2)
	where nombre <> '' and left(nombre, 1) = lower(left(nombre, 1))
		and left(nombre, 1) ~ '[a-záéíóúñ]';
	get diagnostics v_mayuscula = row_count;

	raise notice 'Slugs llevados a femenino: %', v_slugs;
	raise notice 'Nombres recapitalizados: %', v_mayuscula;

	select count(*) into v_restantes
	from public.arquitecturas_forma where slug like '%silabico%';
	if v_restantes > 0 then
		raise exception 'Quedan % slugs con el adjetivo en masculino', v_restantes;
	end if;

	select count(*) into v_restantes
	from public.arquitecturas_forma
	where nombre <> '' and left(nombre, 1) = lower(left(nombre, 1)) and left(nombre, 1) ~ '[a-záéíóúñ]';
	if v_restantes > 0 then
		raise exception 'Quedan % nombres que empiezan en minúscula', v_restantes;
	end if;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
