-- Los nombres de los metros llevan su tilde.
--
-- Siete se escribieron sin ella en la importación del vocabulario legado —«Endecasilabo»,
-- «Octosilabo», «Hexasilabo», «Heptasilabo», «Tetrasilabo», «Pentasilabo», «Dodecasilabo»—,
-- mientras que los añadidos después durante la revisión sí la llevan: «Trisílabo»,
-- «Decasílabo», «Dodecasílabo compuesto 6 + 6». Todos son esdrújulos y todos la llevan.
--
-- Hasta ahora no se veía, porque las etiquetas de las preguntas dicen «11 sílabas» y no el
-- nombre del metro. En cuanto la etiqueta se derive del nombre —que es la regla a la que va
-- el catálogo—, saldría escrito así en el formulario del editor.
--
-- Es pequeño y conviene arreglarlo antes de derivar: un defecto de dato que hoy está tapado por
-- una etiqueta escrita a mano es justo lo que la derivación destapa.

begin;

update public.metros set nombre = 'Tetrasílabo', updated_at = now() where slug = 'tetrasilabo';
update public.metros set nombre = 'Pentasílabo', updated_at = now() where slug = 'pentasilabo';
update public.metros set nombre = 'Hexasílabo', updated_at = now() where slug = 'hexasilabo';
update public.metros set nombre = 'Heptasílabo', updated_at = now() where slug = 'heptasilabo';
update public.metros set nombre = 'Octosílabo', updated_at = now() where slug = 'octosilabo';
update public.metros set nombre = 'Endecasílabo', updated_at = now() where slug = 'endecasilabo';
update public.metros set nombre = 'Dodecasílabo', updated_at = now() where slug = 'dodecasilabo';

do $$
declare
	v_n integer;
	v_mal text;
begin
	select count(*), string_agg(nombre, ', ') into v_n, v_mal
	from public.metros
	where nombre ilike '%silabo%' and nombre not ilike '%sílabo%';
	if v_n <> 0 then
		raise exception 'Quedan % metros sin tilde: %', v_n, v_mal;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
