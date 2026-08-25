-- La quintilla declara la regla de sus fuentes
--
-- Sus tres arquitecturas cambian **una restricción**: `min_alternancias = 2` pasa a
-- `max_consecutivos = 2` en el patrón `distribucion-variable`. No se toca ningún esquema, ni
-- `numero_clases`, ni `versos_sueltos`.
--
-- **Por qué.** La regla que enuncian las fuentes es «no más de dos versos seguidos con la misma
-- rima». `min_alternancias` era un sucedáneo, y la ficha lo llevaba anotado desde el 19 de agosto de
-- 2026 con su motivo: el tipo correcto existía en el `CHECK` y **el auditor no lo evaluaba**. El 25
-- de agosto se arregló eso, y con ello apareció el segundo motivo, que estaba tapado por el primero:
-- declarar la regla buena habría hecho que el auditor protestara por `abbba`, que rompe la regla con
-- sus tres `b` seguidas. Y `abbba` no es un defecto: está declarado **excepcional** porque ninguna
-- fuente lo numera —Morley y Bruerton lo atribuyen a errata o a adaptación expresiva—. D13 salta ya
-- los esquemas excepcionales, así que los dos motivos han desaparecido.
--
-- **Y el sucedáneo no filtraba nada.** Medidas las ocho disposiciones catalogadas, las ocho pasan
-- `min_alternancias = 2`, incluida `abbba` con sus dos alternancias. Era una restricción declarada
-- que no separaba ningún caso:
--
--   esquema  modalidad     alternancias  seguidos
--   ababa    habitual          4            1
--   aabba    admitida          2            2
--   abaab    admitida          3            2
--   abbab    admitida          3            2
--   aabab    excepcional       3            2
--   ababb    excepcional       3            2
--   abbaa    excepcional       2            2
--   abbba    excepcional       2            3   ← la única que la regla buena separa
--
-- **Lo que cambia de lo que la forma afirma**, y conviene decirlo: antes el criterio declarado
-- admitía las ocho disposiciones; ahora admite siete y **deja fuera `abbba`**, que sigue en el
-- catálogo como excepcional. Es lo correcto —una disposición excepcional está precisamente para
-- registrar lo que se aparta— pero es una afirmación distinta, y por eso la descripción del patrón
-- se reescribe: decía «admite además **tres** disposiciones que la descripción clásica no
-- contempla», y con la regla buena son dos, las que acaban en pareado y que Díaz Rengifo omite.
--
-- *Efecto colateral que no molesta:* al sustituirla, **ninguna arquitectura del catálogo declara ya
-- `min_alternancias`**. Era la única que lo usaba. El tipo sigue en el `CHECK` como vocabulario
-- disponible, que es otra cosa que estar declarado.

begin;

do $$
declare
	v_forma uuid;
	v_n integer;
	v_racha integer;
	v_esquema text;

	c_descripcion constant text :=
		'El criterio declarado —dos clases de rima, ningún verso suelto y no más de dos versos '
		|| 'seguidos con la misma rima— es la regla que enuncian las fuentes, y es más amplio que la '
		|| 'enumeración clásica: la recoge entera y admite además las disposiciones que acaban en '
		|| 'pareado, que Díaz Rengifo omite. Deja fuera `abbba`, que ninguna fuente numera y que el '
		|| 'catálogo registra como excepcional.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'quintilla' and activo;
	if v_forma is null then
		raise exception 'La quintilla no está activa.';
	end if;

	-- Las tres arquitecturas declaran hoy el sucedáneo, y solo ellas en todo el catálogo.
	select count(*) into v_n
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where r.tipo = 'min_alternancias' and a.forma_id = v_forma and r.valor_numero = 2;
	if v_n <> 3 then
		raise exception 'La quintilla declara % restricciones de min_alternancias, y se esperaban 3.', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_restricciones where tipo = 'min_alternancias';
	if v_n <> 3 then
		raise exception 'Hay % restricciones de min_alternancias en el catálogo; la quintilla no es la única.', v_n;
	end if;

	-- Y ninguna declara todavía la buena.
	select count(*) into v_n
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where r.tipo = 'max_consecutivos' and a.forma_id = v_forma;
	if v_n <> 0 then
		raise exception 'La quintilla ya declara max_consecutivos en % arquitecturas.', v_n;
	end if;

	-- ------------------------------------------------------------------ La sustitución
	update public.esquema_rima_restricciones r
	set tipo = 'max_consecutivos'
	from public.esquemas_rima er, public.arquitecturas_forma a
	where er.esquema_rima_id = r.esquema_rima_id
		and a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and r.tipo = 'min_alternancias';

	update public.esquemas_rima er
	set descripcion = c_descripcion
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = v_forma
		and er.tipo_secuencia = 'abierta';

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.esquema_rima_restricciones where tipo = 'min_alternancias';
	if v_n <> 0 then
		raise exception 'Quedan % restricciones de min_alternancias en el catálogo.', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where r.tipo = 'max_consecutivos' and r.valor_numero = 2 and a.forma_id = v_forma;
	if v_n <> 3 then
		raise exception 'Solo % de las tres quintillas declara la regla buena.', v_n;
	end if;

	-- **La regla se mide, no se supone.** Se calcula sobre las posiciones guardadas la racha más
	-- larga de versos seguidos con la misma rima en cada disposición catalogada, y se comprueba que
	-- solo la excepcional la rompe. Si alguien añadiera mañana un esquema no excepcional con tres
	-- seguidos, esta guarda lo diría antes que el auditor.
	for v_esquema, v_racha in
		-- **Por esquema, no por slug.** `aabba` existe en las tres medidas de la quintilla, y
		-- agrupar por el nombre mezclaba las posiciones de los tres: la primera versión de esta
		-- guarda dio tres seguidos donde hay dos, y por eso paró la migración. Bien hecha.
		with posiciones as (
			select er.esquema_rima_id, er.slug, er.modalidad, p.posicion,
				lower(p.clase_rima) as clase
			from public.esquemas_rima er
			join public.esquema_rima_posiciones p on p.esquema_rima_id = er.esquema_rima_id
			join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
			where a.forma_id = v_forma and er.tipo_secuencia <> 'abierta'
				and p.clase_rima is not null and not p.suelto
		), islas as (
			select esquema_rima_id, slug, modalidad, clase,
				posicion - row_number() over (
					partition by esquema_rima_id, clase order by posicion
				) as isla
			from posiciones
		), rachas as (
			select esquema_rima_id, slug, modalidad, count(*) as largo
			from islas group by esquema_rima_id, slug, modalidad, clase, isla
		)
		select slug, max(largo)::integer from rachas
		where modalidad <> 'excepcional'
		group by esquema_rima_id, slug
	loop
		if v_racha > 2 then
			raise exception 'La disposición «%» no es excepcional y tiene % versos seguidos con la misma rima.',
				v_esquema, v_racha;
		end if;
	end loop;

	-- Y la que sí la rompe sigue en el catálogo, declarada como lo que es.
	if not exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_forma and er.slug = 'abbba' and er.modalidad = 'excepcional'
	) then
		raise exception 'La disposición «abbba» ha dejado de estar declarada como excepcional.';
	end if;

	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma and er.tipo_secuencia <> 'abierta';
	if v_n <> 24 then
		raise exception 'La quintilla tiene % disposiciones catalogadas, y tenía 24 (ocho por medida).', v_n;
	end if;

	if public.get_forma_metrica_publica('quintilla') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la quintilla ha dejado de responder.';
	end if;
end $$;

commit;
