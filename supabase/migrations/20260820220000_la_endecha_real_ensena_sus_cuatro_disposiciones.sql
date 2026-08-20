-- La endecha real enseña sus cuatro disposiciones
--
-- Revisión de su prosa y de su rima. Su sección de cuestiones ya cubría lo filológico —lo
-- definitorio es el metro y no la asonancia, decidido el 10 de agosto—, y lo que quedaba eran dos
-- defectos que solo se ven en esta ficha y una definición que no se enteró de aquella decisión.
--
-- 1. **Una disposición declarada que no se veía.** El catálogo declara cinco en la arquitectura
--    principal y la ficha dibujaba cuatro, seguidas de un «La disposición no está fijada» que
--    parecía sobrar. La causa: el esquema `suelta`, de notación `[----]…`, **no tenía ni una
--    posición**. El disparador solo reparte notaciones de letras y guiones —los corchetes lo
--    detienen—, y a la `asonantada`, con la misma forma de notación, se las pusieron a mano en su
--    día. Y como el servidor deriva «abierto» de no tener posiciones, un esquema sin ellas se
--    presenta como si no fijara nada. **Es el único caso del catálogo**: comprobado, no hay otro
--    esquema no abierto sin posiciones. Se le escriben sus cuatro versos sueltos.
--
-- 2. **El régimen de la arquitectura decía «Asonante» y dos de sus disposiciones no lo son.** Sus
--    cinco esquemas reparten **tres regímenes**: asonante la asonantada, la abrazada y la cruzada;
--    consonante la cruzada consonante; y sin rima la suelta. La cabecera de la forma sí lo dice;
--    era la fila de la arquitectura la que lo aplanaba, y contradecía el criterio fijado el 12 de
--    agosto y escrito en el propio componente: **arriba si el régimen es uno, y en cada
--    disposición si dentro de la arquitectura varía**. Las otras tres arquitecturas del catálogo
--    con varios regímenes —la canción y las dos del villancico— ya lo dejan sin declarar arriba.
--    Se retira, y de paso se resuelve solo otro problema: «Cruzada asonante» y «Cruzada
--    consonante» dibujaban exactamente lo mismo, `a b a B`, sin que nada dijera en qué difieren.
--
--    *El pareado tiene el mismo desajuste y no se toca aquí: le toca en su revisión.*
--
-- 3. **La definición presentaba como norma una disposición entre cinco.** Decía «con una sola
--    asonancia sostenida en los versos cuartos», cuando la propia revisión del 10 de agosto dejó
--    decidido que **lo definitorio es el metro** y por eso la asonantada es `habitual` y no
--    `definitoria`. La definición no se había enterado.
--
-- Acompaña a esta migración un arreglo de la rejilla y de su componente: el pie —«se repite hasta
-- el final de la serie», «el verso 4 conserva su rima»— describe el esqueleto, que sale de **una**
-- disposición, y quedaba debajo de las cuatro como si valiera para todas.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_suelta uuid;
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Serie de cuartetos formados por tres heptasílabos y un endecasílabo final. Lo que la '
		|| 'define es esa medida, no su rima: nació en verso suelto, y hacia mediados del siglo '
		|| 'XVII se generalizó la forma asonantada, con una sola asonancia sostenida en los versos '
		|| 'cuartos de toda la composición, que es hoy la disposición corriente; también se '
		|| 'documenta abrazada, cruzada y sin rima alguna. El endecasílabo que cierra cada cuarteto '
		|| 'es lo que la separa de la endecha, que es el romance heptasílabo.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecha_real';
	if v_forma is null then
		raise exception 'No existe la endecha real.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heptasilabica_con_endecasilabo' and activo;
	if v_arq is null then
		raise exception 'La endecha real no tiene su arquitectura principal activa.';
	end if;

	-- ------------------------------------------- 1. La disposición suelta se dibuja
	select esquema_rima_id into v_suelta from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'suelta';

	if v_suelta is null then
		raise exception 'No existe la disposición suelta de la endecha real.';
	end if;

	insert into public.esquema_rima_posiciones
		(esquema_rima_id, bloque, posicion, ubicacion, clase_rima, suelto, opcional)
	select v_suelta, 1, n, 'final', null, true, false
	from generate_series(1, 4) as n
	on conflict (esquema_rima_id, bloque, posicion, ubicacion) do update
		set clase_rima = null, suelto = true;

	select count(*) into v_n
	from public.esquema_rima_posiciones where esquema_rima_id = v_suelta;
	if v_n <> 4 then
		raise exception 'La disposición suelta tiene % posiciones, no los cuatro versos.', v_n;
	end if;
	if exists (
		select 1 from public.esquema_rima_posiciones
		where esquema_rima_id = v_suelta and (not suelto or clase_rima is not null)
	) then
		raise exception 'Algún verso de la disposición suelta ha quedado rimando.';
	end if;

	-- Y no queda en el catálogo ningún otro esquema cerrado sin posiciones.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.activo
		and er.tipo_secuencia <> 'abierta'
		and not exists (
			select 1 from public.esquema_rima_posiciones p where p.esquema_rima_id = er.esquema_rima_id
		);
	if v_n <> 0 then
		raise exception 'Quedan % esquemas cerrados sin posiciones.', v_n;
	end if;

	-- --------------------------------- 2. El régimen se declara en cada disposición
	update public.arquitecturas_forma set tipo_rima_id = null where arquitectura_id = v_arq;

	-- Solo se puede retirar de arriba si abajo lo declaran **todas**: si no, la ficha diría que
	-- el catálogo no declara el régimen, que es un aviso en rojo y con razón.
	if exists (
		select 1 from public.esquemas_rima where arquitectura_id = v_arq and tipo_rima_id is null
	) then
		raise exception 'Alguna disposición de la endecha real no declara su régimen de rima.';
	end if;
	select count(distinct tipo_rima_id) into v_n
	from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n < 2 then
		raise exception 'La arquitectura tiene un solo régimen: debería declararlo arriba.';
	end if;

	-- ------------------------------------------------------------ 3. La definición
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%el romance heptasílabo.' and v_actual is distinct from c_definicion then
		raise exception 'La definición no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	-- ------------------------------------------------------------- Comprobaciones
	-- La ficha trae ya las cinco disposiciones, y ninguna sin dibujo.
	select count(*) into v_n
	from jsonb_array_elements(public.get_forma_metrica_publica('endecha_real') -> 'esquemasRima') e
	where e ->> 'arquitectura_id' = v_arq::text;
	if v_n <> 5 then
		raise exception 'La arquitectura principal trae % disposiciones, no las cinco.', v_n;
	end if;

	-- Y la forma conserva sus tres regímenes en la cabecera, que salen de las disposiciones.
	select count(distinct er.tipo_rima_id) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'La endecha real declara % regímenes de rima, no los tres.', v_n;
	end if;
end $$;

commit;
