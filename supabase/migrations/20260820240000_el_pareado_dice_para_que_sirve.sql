-- El pareado dice para qué sirve
--
-- Revisión de su prosa y de su régimen de rima.
--
-- 1. **Declaraba un régimen que no existe en ninguna otra parte del catálogo.** Su arquitectura
--    tenía `tipo_rima_id` apuntando a «Otras», de modo que la cabecera decía «rima Otras o
--    Asonante o Consonante» y la fila de la arquitectura, «Otras». Comprobado: de los cuatro
--    regímenes del vocabulario, **`otras` solo lo declaraba esta arquitectura**, y lo declaraba
--    teniendo debajo dos disposiciones que sí dicen el suyo. Es el mismo desajuste que la endecha
--    real tenía el día anterior, con un agravante: allí el régimen de arriba era verdad para tres
--    de cinco disposiciones; aquí no lo era para ninguna. Se retira, la fila pasa a «según la
--    disposición» y la cabecera queda en «Asonante o Consonante», que es lo que la forma admite.
--
--    *Los nombres de sus dos disposiciones —«Asonante» y «Consonante»— **no se tocan**. Se había
--    anotado como pendiente aplicarles la regla de la endecha real, pensando que eran un tercer
--    estilo; no lo son. La regla es que el nombre diga lo que distingue la fila de sus hermanas, y
--    aquí solo existe una disposición posible —dos versos que riman— de modo que lo único que las
--    distingue es el régimen. «Pareado asonante» habría añadido una palabra tautológica.*
--
-- 2. **La definición no decía por qué esta forma está en un catálogo de verso dramático**, que es
--    lo que sus seis fuentes destacan y en lo que coinciden: sirve suelta —estribillos, refranes,
--    máximas, motes y divisas, y en el teatro para intervenciones breves y tajantes— y sirve
--    además de base a formas mayores. El *Diccionario* lo dice del modo más rotundo: «es la forma
--    sobre la que se construyen otras: la silva de consonantes, el perqué, la aleluya, las
--    canciones de coro y los juegos dialogados».
--
-- 3. **La descripción de la arquitectura hablaba como la herramienta** —«la medida de cada uno y
--    el tipo de rima los declara el pasaje»—, y en su lugar dice qué medidas admite.
--
-- 4. **«Dístico» no llevaba su fuente**, aunque la afirmación de Caparrós 2014 la recoge. Se ha
--    comprobado en el texto —«El pareado, alguna vez también llamado dístico, es la combinación de
--    dos versos…»—, y de paso la afirmación recupera ese «alguna vez», que aplanaba.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de dos versos, de igual o diferente medida, unidos por rima consonante o asonante. '
		|| 'Es la más simple que puede formar estrofa por sí sola, y de ahí su doble vida: aparece '
		|| 'suelta —en estribillos, refranes, máximas, motes y divisas, y en el teatro para '
		|| 'intervenciones breves y tajantes— y sirve además de base a formas mayores, que se '
		|| 'construyen encadenándola: la silva de consonantes es una tirada de pareados de siete y '
		|| 'once.';

	c_descripcion constant text :=
		'Dos versos que riman entre sí, iguales o distintos en medida, desde el tetrasílabo hasta '
		|| 'el alejandrino.';

	c_dc14 constant text :=
		'Recoge «dístico» como otro nombre del pareado, que dice que se le da alguna vez, y lo nota '
		|| '`a a`, sin fijar medida ni régimen de rima.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';
	if v_forma is null then
		raise exception 'No existe el pareado.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'cualquier_medida' and activo;
	if v_arq is null then
		raise exception 'El pareado no tiene su arquitectura activa.';
	end if;

	-- ------------------------------------------------- 1. El régimen, en cada disposición
	update public.arquitecturas_forma set tipo_rima_id = null where arquitectura_id = v_arq;

	-- Solo se puede retirar de arriba si abajo lo declaran todas.
	if exists (
		select 1 from public.esquemas_rima where arquitectura_id = v_arq and tipo_rima_id is null
	) then
		raise exception 'Alguna disposición del pareado no declara su régimen de rima.';
	end if;
	select count(distinct tipo_rima_id) into v_n
	from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 2 then
		raise exception 'El pareado declara % regímenes en sus disposiciones, no dos.', v_n;
	end if;

	-- Y «otras» deja de usarse en el catálogo entero.
	if exists (
		select 1 from public.arquitecturas_forma a
		join public.vocabularios v on v.termino_id = a.tipo_rima_id
		where a.activo and v.termino = 'otras'
	) or exists (
		select 1 from public.esquemas_rima er
		join public.vocabularios v on v.termino_id = er.tipo_rima_id
		where v.termino = 'otras'
	) then
		raise exception 'Todavía hay algo que declara el régimen «otras».';
	end if;

	-- ------------------------------------------------------------------ 2 y 3. La prosa
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%rima consonante o asonante.' and v_actual is distinct from c_definicion
	then
		raise exception 'La definición del pareado no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual not like '%los declara el pasaje.' and v_actual is distinct from c_descripcion then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_descripcion where arquitectura_id = v_arq;

	-- ------------------------------------------------------------------- 4. «Dístico»
	update public.denominaciones_metricas set fuente_id = v_dc14
	where forma_id = v_forma and slug_normalizado = 'distico';

	if not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'distico' and fuente_id = v_dc14
	) then
		raise exception 'La denominación «Dístico» no ha quedado enlazada a su fuente.';
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = c_dc14
	where forma_id = v_forma and fuente_id = v_dc14;

	-- ------------------------------------------------------------------ Comprobaciones
	-- La cabecera pierde «Otras» y conserva los dos regímenes que la forma admite.
	select string_agg(x.termino, ' o ' order by x.termino) into v_actual
	from (
		select distinct v.termino
		from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.vocabularios v on v.termino_id = er.tipo_rima_id
		where a.forma_id = v_forma
	) x;
	if v_actual is distinct from 'asonante o consonante' then
		raise exception 'Los regímenes del pareado salen como «%».', v_actual;
	end if;

	if public.get_forma_metrica_publica('pareado') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del pareado ha dejado de responder.';
	end if;
end $$;

commit;
