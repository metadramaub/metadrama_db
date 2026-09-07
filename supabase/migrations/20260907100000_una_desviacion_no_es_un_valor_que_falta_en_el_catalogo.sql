-- Una desviación no es un valor que falte en el catálogo
--
-- El vocabulario de las desviaciones tenía seis relaciones con la norma, y tres combinaciones no
-- describían nada que pudiera pasar.
--
-- **`diferente` —«es otro valor»— se retira de todas las dimensiones.** Donde la respuesta se puede
-- escribir, «es otro valor» ya es una respuesta: las cincuenta y tres preguntas de rima del catálogo
-- son `opciones_y_esquema` o `esquema_rima`, todas, así que un esquema que el catálogo no tiene se
-- anota como respuesta y no como desviación. Y donde el repertorio es cerrado —rasgo, repetición—
-- encontrar un valor que no está **no es una desviación de la obra: es que al catálogo le falta ese
-- valor**, que es una cuestión para el IP y no algo que se anote en una secuencia.
--
-- **`menor_que_norma` y `mayor_que_norma` se retiran de `repeticion`.** Solo hay tres preguntas de
-- repetición en el catálogo —el estribillo del villancico, dos veces, y el del zéjel— y su
-- repertorio es «No, no vuelve a aparecer», «Se repite entero» y «Se repite solo en parte». Que el
-- estribillo vuelva con menos versos **es** «se repite solo en parte»: duplicaba una respuesta. Que
-- vuelva con más no lo documenta ninguna fuente ni ninguna opción.
--
-- `falta` se queda en repetición, y no por simetría: el zéjel no ofrece «no vuelve a aparecer»
-- entre sus respuestas, así que ahí un estribillo que no vuelve sí es una desviación.
--
-- Quedan cinco relaciones y ninguna se solapa con otra:
--
--     metro       mide menos · mide más · otra
--     rima        otra
--     estructura  falta · sobra · mide menos · mide más · otra
--     repetición  falta · sobra · otra
--     rasgo       falta · sobra · otra
--
-- *No hay nada que migrar.* `anotacion_desviaciones` está a cero filas: la tabla nunca se ha usado.

begin;

alter table public.anotacion_desviaciones
	drop constraint if exists anotacion_desviaciones_relacion_norma_check;

alter table public.anotacion_desviaciones
	add constraint anotacion_desviaciones_relacion_norma_check
	check (
		relacion_norma = any (
			array['falta'::text, 'sobra'::text, 'menor_que_norma'::text, 'mayor_que_norma'::text, 'otra'::text]
		)
	);

alter table public.anotacion_desviaciones
	drop constraint if exists anotacion_desviaciones_relacion_dimension_check;

alter table public.anotacion_desviaciones
	add constraint anotacion_desviaciones_relacion_dimension_check
	check (
		case dimension
			when 'metro' then relacion_norma = any (array['menor_que_norma'::text, 'mayor_que_norma'::text, 'otra'::text])
			when 'rima' then relacion_norma = 'otra'::text
			when 'estructura' then relacion_norma = any (array['falta'::text, 'sobra'::text, 'menor_que_norma'::text, 'mayor_que_norma'::text, 'otra'::text])
			when 'repeticion' then relacion_norma = any (array['falta'::text, 'sobra'::text, 'otra'::text])
			when 'rasgo' then relacion_norma = any (array['falta'::text, 'sobra'::text, 'otra'::text])
			else false
		end
	);

-- ------------------------------------------------------------------------ Comprobaciones
--
-- **Se intenta insertar cada combinación**, no se lee la definición de la restricción. Un `CHECK`
-- escrito con un `case` que no cubra una rama no falla al crearse: falla —o deja pasar— al
-- ejecutarse, y eso solo se sabe intentándolo. Las filas de prueba se borran aquí mismo, y si algo
-- sale mal la transacción entera se deshace.
do $comprobacion$
declare
	v_anot uuid;
	v_dim text;
	v_rel text;
	v_esperado boolean;
	v_entra boolean;
	v_permitidas jsonb := jsonb_build_object(
		'metro', jsonb_build_array('menor_que_norma', 'mayor_que_norma', 'otra'),
		'rima', jsonb_build_array('otra'),
		'estructura', jsonb_build_array('falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'otra'),
		'repeticion', jsonb_build_array('falta', 'sobra', 'otra'),
		'rasgo', jsonb_build_array('falta', 'sobra', 'otra')
	);
	v_probadas integer := 0;
	v_nueva uuid;
	-- Se guardan los identificadores de lo insertado y se borra por ellos. Borrar por coordenadas
	-- —«las de v_ini = 1»— se llevaría por delante una desviación real el día que las haya.
	v_puestas uuid[] := array[]::uuid[];
begin
	select anotacion_id into v_anot from public.anotaciones_metricas limit 1;

	if v_anot is null then
		-- En una base recién creada no hay de qué colgar la prueba. No se calla: se dice que la
		-- restricción queda sin ejercitar, para que nadie la dé por probada.
		raise warning 'Sin anotaciones en la base: la restricción de desviaciones queda sin ejercitar.';
	else
		foreach v_dim in array array['metro', 'rima', 'estructura', 'repeticion', 'rasgo'] loop
			foreach v_rel in array array['diferente', 'falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'otra'] loop
				v_esperado := v_permitidas -> v_dim @> to_jsonb(v_rel);
				begin
					insert into public.anotacion_desviaciones (anotacion_id, v_ini, v_fin, dimension, relacion_norma)
					values (v_anot, 1, 1, v_dim, v_rel)
					returning desviacion_id into v_nueva;
					v_puestas := v_puestas || v_nueva;
					v_entra := true;
				exception
					when check_violation then
						v_entra := false;
				end;

				if v_entra <> v_esperado then
					raise exception 'La combinación % · % %, y debería %.',
						v_dim, v_rel,
						case when v_entra then 'entra' else 'no entra' end,
						case when v_esperado then 'entrar' else 'no entrar' end;
				end if;
				v_probadas := v_probadas + 1;
			end loop;
		end loop;

		delete from public.anotacion_desviaciones where desviacion_id = any (v_puestas);

		if exists (select 1 from public.anotacion_desviaciones where desviacion_id = any (v_puestas)) then
			raise exception 'La prueba ha dejado desviaciones en la base.';
		end if;

		raise notice 'Probadas % combinaciones de dimensión y relación; la base acepta las 15 que valen.', v_probadas;
	end if;
end
$comprobacion$;

commit;
