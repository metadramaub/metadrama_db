-- Las preguntas nuevas apuntan a su rasgo
--
-- Corrección de las dos migraciones anteriores, detectada por `npm run audit:editor`, que pasó de
-- cero defectos a tres: **«pregunta activa que no ofrece nada»** en el romance pentasilábico, el
-- tetrasilábico y la silva arromanzada.
--
-- Las tres copian del romance octosilábico la pregunta por las vocales de la asonancia, y la copia
-- se hizo columna a columna sin incluir `rasgo_id`. Ese campo no es decorativo: la vista
-- `opciones_eleccion_derivadas()` exige `g.rasgo_id is not null` para derivar las opciones de una
-- pregunta de dimensión `rasgo`, de modo que las tres se guardaron **activas, obligatorias y
-- vacías** — el editor las habría mostrado sin nada que elegir y sin poder guardar.
--
-- *La comprobación de aquellas migraciones no lo vio porque contaba las preguntas, no sus opciones.
-- Aquí se comprueba lo que importa: que las seis medidas del romance y la silva arromanzada
-- ofrezcan las diecinueve vocales.*

begin;

do $$
declare
	v_rasgo uuid;
	v_n integer;
	v_esperadas integer;
begin
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'vocales_asonancia';
	if v_rasgo is null then
		raise exception 'No existe el rasgo de las vocales de la asonancia.';
	end if;

	-- Toda pregunta de dimensión `rasgo` sobre una arquitectura que declara este rasgo debe
	-- apuntarlo. Se arregla en general, no solo en las tres: si mañana se copia otra, cae aquí.
	update public.grupos_eleccion_metrica g set rasgo_id = v_rasgo
	where g.dimension = 'rasgo' and g.rasgo_id is null and g.slug = 'vocales_asonancia'
		and exists (
			select 1 from public.arquitectura_rasgos ar
			where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = v_rasgo
		);

	-- ------------------------------------------------------------------ Comprobaciones
	-- Ninguna pregunta de rasgo se queda sin apuntar al suyo.
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where dimension = 'rasgo' and activo and rasgo_id is null;
	if v_n <> 0 then
		raise exception 'Quedan % preguntas de rasgo sin apuntar a ningún rasgo.', v_n;
	end if;

	-- Y ninguna pregunta activa del catálogo se queda sin opciones que ofrecer.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.activo and a.activo and f.activo and g.tipo_control = 'opciones'
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		);
	if v_n <> 0 then
		raise exception 'Hay % preguntas activas sin ninguna opción.', v_n;
	end if;

	-- Todas las que preguntan las vocales ofrecen las mismas: el romance en sus seis medidas, la
	-- endecha real en sus tres y la silva arromanzada.
	select count(*) into v_esperadas from public.rasgo_valores
	where rasgo_id = v_rasgo and activo;

	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	where g.rasgo_id = v_rasgo and g.activo
		and (select count(*) from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id) <> v_esperadas;
	if v_n <> 0 then
		raise exception '% preguntas de vocales no ofrecen las % que hay.', v_n, v_esperadas;
	end if;
end $$;

commit;
