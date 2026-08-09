-- El nombre de la repetición de la sextina, escrito y no fabricado.
--
-- Al dar nombre a las repeticiones, las que ninguna pregunta ofrece lo recibieron de su slug,
-- convertido mecánicamente. A las tres de la sextina les salió «Palabra Final», con una
-- mayúscula que el castellano no lleva y que además no dice lo que la repetición hace.
--
-- La sextina no repite «una palabra final»: repite **las seis palabras finales** de la primera
-- estrofa, en un orden distinto en cada una. Se les da el nombre que les corresponde.
--
-- Ninguna pregunta las ofrece, así que el nombre solo se lee en la ficha; pero un nombre
-- fabricado por un `replace` es exactamente lo que este catálogo no quiere tener.

begin;

update public.repeticiones_metricas
set nombre = 'Palabras finales repetidas', updated_at = now()
where nombre = 'Palabra Final';

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.repeticiones_metricas
	where nombre ~ '[a-záéíóúñ] [A-ZÁÉÍÓÚÑ]';
	if v_n <> 0 then
		raise exception 'Quedan % nombres de repetición con mayúscula intermedia', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
