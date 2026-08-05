-- Normalizar los nombres y los slugs del catálogo según la convención ya fijada.
--
-- La convención está en docs/dominio-metrico/historico/revision-nomenclatura.md: slug en
-- minúsculas sin tildes, y el nombre de una arquitectura no repite el de su forma. Auditadas
-- las 110 entidades con nombre y slug —arquitecturas, esquemas métricos y variedades— salen
-- cuatro cosas, todas pequeñas.
--
-- 1 · Siete variedades del sexteto-lira llevan mayúsculas en el slug. La notación con su caja
--     original —`aBaBcC`, donde la mayúscula marca arte mayor— vive en el nombre, que es
--     donde se lee; el slug es un identificador y va en minúsculas como todos.
--
-- 2 · Cuatro arquitecturas usan el adjetivo en masculino y dieciocho en femenino. El
--     femenino concuerda con «arquitectura», que es lo que el nombre califica. No concuerda
--     con la forma: el cuarteto y el sexteto son masculinos y ya se nombran «Endecasilábica».
--
-- 3 · Una arquitectura repite el nombre de su forma —«Terceto encadenado octosilábico
--     consonante»—, que es justo lo que la convención prohíbe. Su hermana endecasilábica ya
--     lo hacía bien.
--
-- 4 · Las cuatro arquitecturas del romance nombran en sustantivo —«Octosílabo»— mientras su
--     slug ya usa el adjetivo y las otras cuarenta y cinco también. Se normalizan por
--     coherencia. **Es la única de las cuatro que admite discusión**: «romance octosílabo» es
--     como lo dice la tradición, y si se prefiere conservarlo, revertir estas cuatro filas no
--     afecta a nada más.

begin;

do $$
declare
	v_variedades integer;
	v_genero integer;
	v_repetido integer;
	v_romance integer;
	v_restantes integer;
begin
	-- 1 · Slugs de variedad en minúsculas
	update public.variedades_arquitectura
	set slug = lower(slug)
	where slug <> lower(slug);
	get diagnostics v_variedades = row_count;

	-- 2 · El adjetivo concuerda con «arquitectura», en femenino
	update public.arquitecturas_forma
	set nombre = replace(nombre, 'silábico', 'silábica')
	where nombre like '%silábico%';
	get diagnostics v_genero = row_count;

	-- 3 · El nombre no repite el de su forma
	update public.arquitecturas_forma a
	set nombre = btrim(
		regexp_replace(a.nombre, '^' || f.nombre || '\s+', '', 'i')
	)
	from public.formas_metricas f
	where f.forma_id = a.forma_id
		and a.nombre <> f.nombre
		and lower(a.nombre) like lower(f.nombre) || ' %';
	get diagnostics v_repetido = row_count;

	-- 4 · El romance nombra en adjetivo, como el resto
	update public.arquitecturas_forma a
	set nombre = case a.slug
		when 'octosilabico' then 'Octosilábica'
		when 'hexasilabico' then 'Hexasilábica'
		when 'heptasilabico' then 'Heptasilábica'
		when 'endecasilabico' then 'Endecasilábica'
		else a.nombre
	end
	from public.formas_metricas f
	where f.forma_id = a.forma_id
		and f.slug = 'romance'
		and a.slug in ('octosilabico', 'hexasilabico', 'heptasilabico', 'endecasilabico');
	get diagnostics v_romance = row_count;

	raise notice 'Slugs de variedad en minúsculas: %', v_variedades;
	raise notice 'Adjetivos llevados a femenino: %', v_genero;
	raise notice 'Nombres que repetían su forma: %', v_repetido;
	raise notice 'Arquitecturas del romance en adjetivo: %', v_romance;

	-- Nada debe quedar fuera de la convención.
	select count(*) into v_restantes
	from public.variedades_arquitectura where slug <> lower(slug);
	if v_restantes > 0 then
		raise exception 'Quedan % slugs de variedad con mayúsculas', v_restantes;
	end if;

	select count(*) into v_restantes
	from public.arquitecturas_forma where nombre like '%silábico%';
	if v_restantes > 0 then
		raise exception 'Quedan % arquitecturas con el adjetivo en masculino', v_restantes;
	end if;

	select count(*) into v_restantes
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where lower(a.nombre) like lower(f.nombre) || ' %';
	if v_restantes > 0 then
		raise exception 'Quedan % nombres que repiten el de su forma', v_restantes;
	end if;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
