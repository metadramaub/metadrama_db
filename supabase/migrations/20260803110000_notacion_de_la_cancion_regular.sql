-- La notación de la canción regular recupera su articulación.
--
-- El punto 7 de `20260803100000_vocabulario_de_las_desviaciones.sql` no llegó a aplicarse:
-- buscaba la arquitectura por el slug `regular_13_abCabC_cdeeDfF`, que era el original de
-- la formalización y que `20260731200000_nomenclatura_catalogo.sql` ya había cambiado por
-- `regular_13_versos`. La migración anterior está aplicada y no se toca.
--
-- El esquema se identifica aquí por su propia notación, que es única y no depende de cómo
-- se llame la arquitectura que lo declara.

update public.esquemas_rima
set notacion = 'ABCABC:CDEEDFF',
	updated_at = now()
where notacion = 'ABCABCCDEEDFF';

-- El slug no lleva los dos puntos: es un identificador normalizado, no la notación.

-- Comprobación: si la fila no existiera, la migración quedaría en silencio y el problema
-- volvería más adelante disfrazado de dato que nadie escribió.
do $$
declare
	v_total integer;
begin
	select count(*) into v_total
	from public.esquemas_rima
	where notacion = 'ABCABC:CDEEDFF';

	if v_total = 0 then
		raise exception
			'No se encontró el esquema de la canción regular: revisa su notación antes de dar por buena esta migración';
	end if;
end;
$$;
