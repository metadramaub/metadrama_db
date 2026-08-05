-- Una sola convención para la notación de los esquemas de rima, y comprobada por la base.
--
-- La barra vertical hacía dos trabajos: en el zéjel separaba bloques —cabeza y copla— y en
-- la silva y el terceto encadenado solo ilustraba que el ciclo se repite, escribiéndolo
-- varias veces con letras que avanzaban. Y los puntos suspensivos aparecían unas veces tras
-- un ciclo escrito una vez y otras tras varios.
--
-- La norma queda así:
--
--   a, b, …     clase de rima de arte menor
--   A, B, …     clase de rima de arte mayor
--   -           verso suelto
--   ( )         posición opcional
--   :           pausa estructural dentro de un bloque
--   |           frontera de bloque, y solo eso
--   [ ]…        el bloque se repite indefinidamente
--
-- Regla que lo gobierna todo: **cada posición aparece una sola vez**. La repetición se
-- marca, no se escribe. Un romance es `[-a]…`, no `-a-a-a…`.
--
-- Lo que la notación no lleva vive donde le toca: el enlace de rima entre bloques está en
-- `esquema_rima_enlaces`, y el cierre de una serie —el serventesio final del terceto
-- encadenado— es una sección de `estructuras_secciones`.

begin;

update public.esquemas_rima set notacion = '[-a]…'
where notacion = '-a-a-a…';

update public.esquemas_rima set notacion = '[aA]…'
where notacion = 'aA | bB | cC | …';

update public.esquemas_rima set notacion = '[aba]…'
where notacion = 'aba | bcb | cdc | … | yzyz';

update public.esquemas_rima set notacion = '[ABA]…'
where notacion = 'ABA | BCB | CDC | … | YZYZ';

-- En el zéjel la barra sí separa bloques: la cabeza de la copla. Lo que faltaba era decir
-- que la copla se repite.
update public.esquemas_rima set notacion = 'A(A) | [BBBA]…'
where notacion = 'A(A) | BBBA';

do $$
declare
	v_malas integer;
begin
	select count(*) into v_malas
	from public.esquemas_rima
	where notacion is not null and notacion !~ '^[A-Za-z:|()\[\]… -]+$';

	if v_malas > 0 then
		raise exception 'Quedan % notaciones con símbolos fuera de la convención', v_malas;
	end if;

	-- Ningún ciclo puede quedar escrito más de una vez: si hay «…» sin corchetes, o letras
	-- repitiendo el mismo patrón, es que se escribió en vez de marcarse.
	select count(*) into v_malas
	from public.esquemas_rima
	where notacion like '%…%' and notacion not like '%]…%';

	if v_malas > 0 then
		raise exception 'Quedan % notaciones con «…» que no cierran un ciclo entre corchetes', v_malas;
	end if;
end $$;

alter table public.esquemas_rima
	drop constraint if exists esquemas_rima_notacion_check;

alter table public.esquemas_rima
	add constraint esquemas_rima_notacion_check
	check (
		notacion is null
		-- Solo el alfabeto de la convención.
		or (
			notacion ~ '^[A-Za-z:|()\[\]… -]+$'
			-- Los puntos suspensivos cierran siempre un ciclo entre corchetes.
			and (notacion not like '%…%' or notacion like '%]…%')
			-- Y no hay corchete de apertura sin su cierre.
			and (notacion like '%[%') = (notacion like '%]%')
		)
	);

comment on column public.esquemas_rima.notacion is
	'Notación normalizada: minúscula arte menor, mayúscula arte mayor, «-» verso suelto, «( )» opcional, «:» pausa dentro de un bloque, «|» frontera de bloque, «[ ]…» bloque que se repite. Cada posición aparece una sola vez: la repetición se marca, no se escribe.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
