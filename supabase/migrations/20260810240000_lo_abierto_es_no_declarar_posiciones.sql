-- Lo abierto es no declarar posiciones, y no dos cosas distintas.
--
-- Primer paso de la transversal de los esquemas abiertos. `tipo_secuencia` admitía `abierta` y
-- `restricciones` como si fueran dos formas de disposición, y no lo son: las dos dicen que **no
-- hay disposición declarada**. Lo que las distinguía en la cabeza de quien las escribió era si
-- además había restricciones, y eso ya se sabe mirando `esquema_rima_restricciones`.
--
-- Que la distinción no era aplicable lo demuestra la silva: **el mismo esquema,
-- `consonante-orden-libre`, estaba declarado `abierta` en la arquitectura «Libre» y
-- `restricciones` en «Consonante de orden libre»**, con una restricción idéntica en las dos. Es
-- el caso frontera —abierto *con* restricción— y no había manera de saber cuál poner.
--
-- LO ABIERTO PASA A SER UN HECHO COMPROBABLE. En 85 de los 86 esquemas, «abierto» equivale a «no
-- declara ni una posición»: los 11 `abierta` y los 4 `restricciones` no tienen ninguna, y los 61
-- `secuencia` las tienen todas. Así que el valor deja de ser una afirmación que alguien recuerda
-- poner y pasa a poder contrastarse contra las posiciones, que es lo que se ha hecho con las
-- repeticiones, los enlaces y las estructuras.
--
-- *Queda una excepción anotada y no se toca aquí: la `suelta` de la endecha real es un `ciclo`
-- con notación `[----]…` —cuatro versos sueltos— cuyas posiciones nunca se expandieron. No es un
-- esquema abierto mal marcado, es un esquema cerrado al que le faltan sus filas.*

begin;

alter table public.esquemas_rima drop constraint esquemas_rima_tipo_secuencia_check;

update public.esquemas_rima
set tipo_secuencia = 'abierta', updated_at = now()
where tipo_secuencia = 'restricciones';

alter table public.esquemas_rima add constraint esquemas_rima_tipo_secuencia_check
	check (tipo_secuencia = any (array['ciclo', 'secuencia', 'conjunto', 'abierta']));

comment on column public.esquemas_rima.tipo_secuencia is
	'Qué forma tiene la disposición: `secuencia` si se lee de una vez, `ciclo` si se repite, `conjunto` si sus posiciones no llevan orden, y `abierta` cuando la norma no fija ninguna. No dice cuántos versos abarca: eso lo dice la extensión de aquello a lo que pertenece. Un esquema abierto no es un esquema sin norma: declara su tipo de rima y sus restricciones, y lo que deja libre es la disposición.';

comment on column public.esquemas_rima.notacion is
	'La disposición escrita, cuando la hay. Nula exactamente en los esquemas abiertos, que son los que no declaran posiciones.';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Ningún esquema abierto puede declarar posiciones: sería decir a la vez que la disposición
	-- está fijada y que no lo está.
	select count(*), string_agg(er.slug, ', ') into v_n, v_mal
	from public.esquemas_rima er
	where er.tipo_secuencia = 'abierta'
		and exists (
			select 1 from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id
		);
	if v_n <> 0 then
		raise exception '% esquemas abiertos declaran posiciones: %', v_n, v_mal;
	end if;

	-- Ni notación, por lo mismo.
	select count(*), string_agg(er.slug, ', ') into v_n, v_mal
	from public.esquemas_rima er
	where er.tipo_secuencia = 'abierta' and er.notacion is not null;
	if v_n <> 0 then
		raise exception '% esquemas abiertos declaran notación: %', v_n, v_mal;
	end if;

	-- Los quince que había siguen siendo quince, ahora con un solo nombre.
	select count(*) into v_n from public.esquemas_rima where tipo_secuencia = 'abierta';
	if v_n <> 15 then
		raise exception 'Hay % esquemas abiertos en vez de 15', v_n;
	end if;

	-- Y la silva deja de decir dos cosas distintas de lo mismo.
	select count(distinct er.tipo_secuencia) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'silva' and er.slug = 'consonante-orden-libre';
	if v_n <> 1 then
		raise exception 'La silva sigue declarando `consonante-orden-libre` de % maneras', v_n;
	end if;

	-- Nada de esto puede haber movido lo que el editor ofrece: los abiertos nunca fueron opción.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then raise exception 'Las opciones dejaron de ser 405 y son %', v_n; end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
