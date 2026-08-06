-- La definición de la quintilla enunciaba una norma que el propio catálogo incumple.
--
-- Decía que vale «cualquiera que no ponga tres versos seguidos con la misma rima ni cierre la
-- estrofa en pareado». Las dos partes son falsas contra el propio catálogo:
--
--   · `abbba` tiene tres versos seguidos con la misma rima, y está admitida.
--   · `abbaa` y `ababb` cierran en pareado, y están admitidas.
--
-- Es la preceptiva de Quilis y de Rengifo, no la del catálogo. Repetirla en la definición
-- hacía que la ficha se contradijera a tres líneas de distancia, porque debajo se leen las
-- ocho disposiciones y tres de ellas la violan.
--
-- **La norma que sí se cumple es que no quede ningún verso suelto**: las dos clases de rima
-- aparecen cada una en dos versos por lo menos. Comprobado sobre las quince disposiciones
-- posibles de cinco versos con dos clases:
--
--   · Las ocho del catálogo la cumplen, sin excepción.
--   · La descarta `aabaa`, que era la pregunta 2 de `cuestiones-para-el-ip.md`: su segunda
--     clase aparece una sola vez, de modo que ese verso queda sin pareja. Igual que `aaaab`,
--     `aaaba`, `abaaa` y `abbbb`.
--
-- No es toda la frontera. Quedan fuera `aaabb` y `aabbb`, que cumplen la condición y el
-- catálogo no recoge; las dos tienen tres versos seguidos con la misma rima, igual que
-- `abbba`. De modo que la frontera real es: ningún verso suelto, y de las disposiciones con
-- tres rimas seguidas **solo se admite `abbba`**, que es justamente por lo que su nombre dice
-- «excepcional». La definición pasa a decir eso.
--
-- Se retira además «de tarde en tarde» de la descripción de `abbba`, que es coloquial de más
-- para una ficha.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'quintilla';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;

	if v_forma is null or v_arq is null then
		raise exception 'Falta la quintilla o su arquitectura';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de cinco versos octosílabos con rima consonante repartida en dos clases, cada una en dos versos por lo menos: ninguno queda suelto. La disposición no está fijada, y la tradición ha ido reconociendo las que evitan tres versos seguidos con una misma rima, con la excepción de abbba.'
	where forma_id = v_forma;

	update public.esquemas_rima
	set descripcion = 'Tres versos seguidos con la misma rima, lo que ninguna otra disposición admite. Es poco frecuente y no todas las fuentes la aceptan como quintilla regular.'
	where arquitectura_id = v_arq and notacion = 'abbba';

	-- La definición afirma que ninguna disposición del catálogo deja un verso suelto. Se
	-- comprueba, porque es lo único que la definición promete y conviene que no se rompa.
	if exists (
		select 1
		from public.esquemas_rima er
		cross join lateral (
			select
				length(er.notacion) - length(replace(er.notacion, 'a', '')) as aes,
				length(er.notacion) - length(replace(er.notacion, 'b', '')) as bes
		) c
		where er.arquitectura_id = v_arq and (c.aes < 2 or c.bes < 2)
	) then
		raise exception 'Alguna disposición de la quintilla deja un verso sin pareja de rima';
	end if;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
