-- La novena-lira declara su rima abierta
--
-- Corrección de la migración anterior, detectada por `npm run audit:metrica`, que pasó de cero
-- defectos a uno: **D2b, «configuración sin ninguna declaración de rima ni de repetición»**.
--
-- Al crear la novena-lira decidí no darle ningún esquema de rima, porque no hay ninguna disposición
-- documentada que ofrecer y una pregunta activa sin opciones es a su vez un defecto. La conclusión
-- era falsa: **no hacía falta elegir entre las dos cosas**, porque el catálogo tiene desde hace
-- tiempo el mecanismo para este caso exacto, y el propio auditor lo enuncia al describir D2:
--
-- > «Se exceptúa el de tipo **abierta** con un tipo de rima declarado: afirma que la norma exige ese
-- > tipo y deja libre la disposición, como corresponde a una forma general.»
--
-- Es decir: un esquema **sin notación y sin posiciones**, que no dice cómo riman los versos pero sí
-- que riman, y en consonante. Lo usan ya la quintilla en sus tres arquitecturas, la silva libre y la
-- sextilla — que es, no por casualidad, el otro caso que **B1** tiene pendiente.
--
-- Con esto la novena-lira declara lo que de verdad se sabe de ella —nueve versos, siete y once,
-- consonante, disposición libre— y no finge un silencio que no era tal. Sigue sin pregunta de
-- disposición, y eso sigue siendo correcto: no hay opciones que ofrecer hasta que B1 permita
-- declarar un esquema que el catálogo no tenga.

begin;

do $$
declare
	v_arq uuid;
	v_consonante uuid;
	v_n integer;
begin
	select a.arquitectura_id, a.tipo_rima_id into v_arq, v_consonante
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'novena_lira' and a.slug = 'heterometrica_consonante' and a.activo;
	if v_arq is null or v_consonante is null then
		raise exception 'No existe la novena-lira o no declara régimen de rima.';
	end if;

	-- Entró sin ninguno: si ya tuviera esquema, esta corrección sobra.
	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n not in (0, 1) then
		raise exception 'La novena-lira tiene % esquemas de rima; se esperaba ninguno o el uno.', v_n;
	end if;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion
	)
	select v_arq, 'distribucion-variable', 'Distribución variable', null, v_consonante,
		'definitoria', 'abierta',
		'La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las '
		|| 'rimas. No es que el catálogo no lo sepa todavía: es que de esta forma no hay ninguna '
		|| 'disposición documentada, y declarar una sería inventarla.'
	where not exists (
		select 1 from public.esquemas_rima where arquitectura_id = v_arq
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 1 then
		raise exception 'La novena-lira tiene % esquemas de rima, no el uno.', v_n;
	end if;

	-- Abierto de verdad: sin notación y sin posiciones. Si trajera cualquiera de las dos, estaría
	-- afirmando una disposición que ninguna fuente sostiene.
	if exists (
		select 1 from public.esquemas_rima where arquitectura_id = v_arq
			and (notacion is not null or tipo_secuencia <> 'abierta')
	) then
		raise exception 'El esquema de la novena-lira afirma una disposición que no tiene.';
	end if;

	if exists (
		select 1 from public.esquema_rima_posiciones p
		join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
		where er.arquitectura_id = v_arq
	) then
		raise exception 'El esquema abierto de la novena-lira ha recibido posiciones.';
	end if;

	-- Y declara el régimen, que es lo único que la norma sí fija.
	if not exists (
		select 1 from public.esquemas_rima
		where arquitectura_id = v_arq and tipo_rima_id = v_consonante
	) then
		raise exception 'El esquema de la novena-lira no declara el régimen consonante.';
	end if;

	-- Sigue sin pregunta de disposición, que es correcto mientras no haya nada que ofrecer.
	select count(*) into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and activo;
	if v_n <> 0 then
		raise exception 'La novena-lira ha ganado % preguntas, y no debía traer ninguna.', v_n;
	end if;

	if public.get_forma_metrica_publica('novena_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la novena-lira ha dejado de responder.';
	end if;
end $$;

commit;
