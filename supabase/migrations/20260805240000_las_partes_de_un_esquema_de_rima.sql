-- Las partes de un esquema de rima se declaran, no se dejan en la puntuación.
--
-- Al revisar la redondilla apareció que la frontera entre sus dos redondillas vivía solo en
-- los dos puntos de `abba:acca`, con `esquema_rima_posiciones.seccion` a null en las ocho.
-- Auditar el resto del catálogo destapó algo peor que una columna vacía: **una incoherencia
-- entre las posiciones y los enlaces de ese mismo esquema**.
--
-- Los dos enlaces de la doble enlazada dicen `bloque_origen = 1, desplazamiento_bloque = 1`:
-- hablan de dos bloques de cuatro versos, y afirman que el verso 1 del primero rima con el 4
-- del segundo y el 4 del primero con el 1 del segundo. Pero las posiciones estaban las ocho
-- en el bloque 1, numeradas de 1 a 8. Leído sobre ese dato, el enlace decía que el verso 1
-- rima con el verso 4 de una repetición siguiente que no existe, porque el esquema no cicla.
-- Los enlaces tenían razón y las posiciones no.
--
-- **Bloque y sección no son lo mismo**, y el catálogo ya lo demostraba: en el zéjel el bloque
-- 2 contiene dos secciones, mudanza y vuelta. Y la silva declara sección —«pareado»— con un
-- solo bloque. De modo que:
--
--   · `bloque`  · unidad de repetición y de enlace. Es lo que cuenta `desplazamiento_bloque`.
--   · `seccion` · la parte con nombre a la que pertenece el verso. Puede ser más fina que el
--                 bloque, y existe aunque el bloque sea uno solo.
--
-- Y en la notación, en consecuencia:
--
--   · `|` separa bloques. Sus segmentos tienen que ser tantos como bloques declarados.
--   · `:` marca una pausa **dentro** de un bloque, que no lo parte.
--
-- Tres arreglos:
--
-- 1 · **Redondilla doble enlazada.** Las posiciones 5-8 pasan a ser el bloque 2, posiciones
--     1-4, que es lo que sus enlaces llevaban afirmando. Secciones: primera y segunda
--     redondilla, con el mismo criterio que la sextilla de doble pie quebrado. Y `abba|acca`,
--     porque son dos bloques y no una pausa.
--
-- 2 · **Sextilla de doble pie quebrado.** Declaraba ya dos bloques y sus doce secciones —era
--     la única forma del catálogo que lo hacía— pero escribía `abcabc:defdef`. Pasa a `|`.
--
-- 3 · **Canción petrarquista regular.** Sigue siendo un bloque con una pausa, así que conserva
--     los dos puntos; lo que le faltaba eran las secciones. La entrada «estancia» del
--     Diccionario las nombra, y el dato las confirma verso a verso: una *fronte* de dos pies
--     de tres versos (1-6), un *eslabón* que es «generalmente un heptasílabo que rima con el
--     último verso de la fronte, pero que pertenece sintácticamente a la sirima» —la posición
--     7 es heptasílaba y repite la clase de rima de la 6, que es endecasílaba— y una *sirima*
--     con rimas independientes (8-13).
--
-- No se tocan los quince esquemas sin notación ni posiciones: se llaman «Distribución
-- variable», «de orden libre» o «Predominio de…», y ahí el vacío es el dato. La forma declara
-- que la rima es consonante y que su orden no está fijado; inventarle posiciones sería
-- afirmar lo que la forma niega.

begin;

do $$
declare
	v_redondilla uuid;
	v_cancion uuid;
	v_movidas integer;
	v_mal integer;
	v_detalle text;
begin
	select er.esquema_rima_id into v_redondilla
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'redondilla' and a.slug = 'doble_enlazada';

	select er.esquema_rima_id into v_cancion
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'cancion_petrarquista' and er.notacion = 'abCabC:cdeeDfF';

	if v_redondilla is null or v_cancion is null then
		raise exception 'Falta la redondilla doble enlazada o la canción petrarquista regular';
	end if;

	-- 1 · La doble enlazada, tal como sus enlaces la describen desde el principio.
	update public.esquema_rima_posiciones
	set bloque = 2, posicion = posicion - 4
	where esquema_rima_id = v_redondilla and bloque = 1 and posicion > 4;
	get diagnostics v_movidas = row_count;

	if v_movidas <> 4 then
		raise exception 'Se esperaban 4 posiciones en la segunda redondilla y se movieron %', v_movidas;
	end if;

	update public.esquema_rima_posiciones
	set seccion = case bloque when 1 then 'primera_redondilla' else 'segunda_redondilla' end
	where esquema_rima_id = v_redondilla;

	update public.esquemas_rima set notacion = 'abba|acca' where esquema_rima_id = v_redondilla;

	-- 2 · La sextilla ya tenía los bloques; le faltaba escribirlos.
	update public.esquemas_rima set notacion = 'abcabc|defdef' where notacion = 'abcabc:defdef';

	-- 3 · Las partes de la estancia, que el Diccionario nombra y la medida confirma.
	update public.esquema_rima_posiciones
	set seccion = case
		when posicion <= 6 then 'fronte'
		when posicion = 7 then 'eslabon'
		else 'sirima'
	end
	where esquema_rima_id = v_cancion;

	update public.esquema_rima_posiciones
	set nota = 'Rima con el último verso de la fronte, pero pertenece sintácticamente a la sirima.'
	where esquema_rima_id = v_cancion and posicion = 7;

	-- Comprobación: los segmentos que separa `|` son tantos como bloques declarados.
	select count(*), string_agg(x.notacion, ' · ')
	into v_mal, v_detalle
	from (
		select er.notacion, count(distinct p.bloque) as bloques
		from public.esquemas_rima er
		join public.esquema_rima_posiciones p on p.esquema_rima_id = er.esquema_rima_id
		where er.notacion is not null
		group by er.esquema_rima_id, er.notacion
		having count(distinct p.bloque) <> array_length(string_to_array(er.notacion, '|'), 1)
	) x;

	if v_mal > 0 then
		raise exception 'Quedan % esquemas cuyos bloques no cuadran con su notación: %', v_mal, v_detalle;
	end if;

	raise notice 'Partes declaradas · redondilla doble enlazada en dos bloques, sextilla con «|», canción con fronte, eslabón y sirima';
end $$;

comment on column public.esquema_rima_posiciones.bloque is
	'Unidad de repetición y de enlace: es lo que cuenta `desplazamiento_bloque` en `esquema_rima_enlaces`, y lo que separa `|` en la notación. Los segmentos de la notación tienen que ser tantos como bloques distintos declaren las posiciones.';

comment on column public.esquema_rima_posiciones.seccion is
	'La parte con nombre a la que pertenece el verso: fronte, sirima, mudanza, vuelta, primera redondilla… No es el bloque y puede ser más fina que él —en el zéjel, el bloque 2 contiene mudanza y vuelta— ni depende de él: la silva declara «pareado» con un solo bloque. Se rellena siempre que la forma tenga partes con nombre; el vacío solo es legítimo cuando no las tiene.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
