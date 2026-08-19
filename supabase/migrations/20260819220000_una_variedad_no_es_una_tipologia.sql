-- Una variedad no es una tipología
--
-- El grupo de elección que ofrece las siete variedades del sexteto-lira se llamaba `tipologia`,
-- y son cosas distintas: una **tipología** es una disposición de rima —las ocho de la quintilla,
-- las cuatro de los tercetos del soneto— y una **variedad** empareja una medida **con** una
-- rima. Es la confusión que la definición de la forma acaba de deshacer, y el slug la mantenía.
--
-- Nada del código lee ese slug —comprobado— y las anotaciones apuntan al dato elegido y no al
-- grupo, así que el renombrado no alcanza a ninguna elección guardada.

begin;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_variedades integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa sexteto_lira/heterometrica_consonante.';
	end if;

	select slug into v_actual
	from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and dimension = 'combinacion';

	if not found then
		raise exception 'El sexteto-lira no tiene grupo de dimensión «combinacion».';
	end if;

	if v_actual is distinct from 'tipologia' and v_actual is distinct from 'variedad' then
		raise exception 'El slug del grupo no es el esperado. Dice: %', v_actual;
	end if;

	update public.grupos_eleccion_metrica
	set slug = 'variedad'
	where arquitectura_id = v_arq and dimension = 'combinacion';

	-- Lo que ese grupo ofrece son variedades, y siguen siendo siete.
	select count(*) into v_variedades
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.arquitectura_id = v_arq and g.slug = 'variedad' and o.variedad_id is not null;

	if v_variedades <> 7 then
		raise exception 'El grupo «variedad» ofrece % opciones de variedad, no siete.', v_variedades;
	end if;

	-- Y no queda ningún grupo llamado «tipologia» en el catálogo.
	if exists (select 1 from public.grupos_eleccion_metrica where slug = 'tipologia') then
		raise exception 'Quedan grupos de elección llamados «tipologia».';
	end if;
end $$;

commit;
