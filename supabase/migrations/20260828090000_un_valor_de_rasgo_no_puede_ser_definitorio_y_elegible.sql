-- Un valor de rasgo no puede ser definitorio y elegible a la vez
--
-- La norma del endecasílabo suelto decía «Densidad de rima: Ninguna; obligatorio» y la pregunta de
-- debajo ofrecía **Ninguna** y **Esporádica**: arriba obligatorio, abajo elegible.
--
-- **Lo que es obligatorio es el rasgo, no el valor.** Que la densidad de rima cuente es lo que define
-- al endecasílabo suelto —sin eso no sería la forma que es—, y eso se dice marcando el **rasgo**. Pero
-- «ninguna» no puede ser definitoria: un pasaje con rima esporádica **sigue siendo endecasílabo
-- suelto**, y Morley y Bruerton lo cuentan como tal por debajo de la mitad de los versos. Así que
-- «ninguna» es lo **habitual** y «esporádica» lo **admitido**, que es lo que ya estaba.
--
-- Y se amplía a los rasgos la garantía del 27 de agosto: **ninguna pregunta ofrece una definitoria
-- entre sus opciones**. Se dejaron fuera porque en `arquitectura_rasgos` la modalidad suele marcar *el
-- rasgo* —«este rasgo caracteriza la arquitectura»—, y entonces preguntar cuál de sus valores se lee
-- es justo lo que hay que hacer. Pero cuando la fila lleva `valor_id`, la modalidad marca **un valor**,
-- y ahí vale lo mismo que para una realización: la norma no es una alternativa entre las que elegir.
--
-- La distinción la hace el propio dato y no hace falta declararla: una fila **sin** `valor_id` no
-- casa con ninguna opción concreta, así que las definitorias de rasgo entero siguen pasando. Hoy hay
-- veintitantas y todas son correctas.

begin;

do $$
declare
	v_modalidad text;
	v_rasgo uuid;
	v_arquitectura uuid;
	v_valor uuid;
begin
	select ar.arquitectura_id, ar.rasgo_id, ar.valor_id, ar.modalidad
	into v_arquitectura, v_rasgo, v_valor, v_modalidad
	from public.arquitectura_rasgos ar
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Endecasílabo suelto'
		and r.slug = 'densidad_de_rima'
		and rv.nombre = 'Ninguna';

	if v_arquitectura is null then
		raise exception 'No está la densidad de rima «Ninguna» del endecasílabo suelto.';
	end if;

	if v_modalidad = 'habitual' then
		raise notice 'Ya era habitual.';
	elsif v_modalidad <> 'definitoria' then
		raise exception 'Era %, y no es lo que se acordó cambiar.', v_modalidad;
	else
		update public.arquitectura_rasgos
		set modalidad = 'habitual'
		where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo and valor_id = v_valor;
	end if;
end $$;

create or replace function public.preguntas_que_ofrecen_una_definitoria()
returns text
language plpgsql
stable
as $$
declare
	v_mal text;
	v_n integer;
begin
	-- La pregunta se hace sobre las opciones **derivadas**, que es lo que la aplicación lee: un
	-- esquema puede estar bien escrito y aun así acabar ofrecido por la función que las genera.
	select count(*), string_agg(distinct linea, '; ')
	into v_n, v_mal
	from (
		select f.nombre || ' · ' || a.nombre || ' · ' || g.slug as linea
		from public.grupos_eleccion_metrica g
		join public.opciones_eleccion_metrica o on o.grupo_eleccion_id = g.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		left join public.repeticiones_metricas rm on rm.repeticion_id = o.repeticion_id
		left join public.variedades_arquitectura va on va.variedad_id = o.variedad_id
		-- **Solo las filas con `valor_id`.** Sin él la modalidad habla del rasgo entero y no de
		-- ninguna opción, así que un rasgo definitorio con sus valores elegibles sigue siendo
		-- correcto: lo que caracteriza la arquitectura es que ese rasgo cuente, no cuál de sus
		-- valores se lea.
		left join public.arquitectura_rasgos ar
			on ar.arquitectura_id = g.arquitectura_id
			and ar.rasgo_id = g.rasgo_id
			and ar.valor_id = o.valor_rasgo_id
		where g.activo
			and 'definitoria' in (
				coalesce(er.modalidad, ''),
				coalesce(rm.modalidad, ''),
				coalesce(va.modalidad, ''),
				coalesce(ar.modalidad, '')
			)
	) malas;

	if v_n = 0 then
		return null;
	end if;
	return v_n || ' pregunta(s): ' || v_mal;
end;
$$;

do $$
begin
	execute format('drop trigger if exists %I on public.%I',
		'trg_definitoria_no_se_ofrece', 'arquitectura_rasgos');
	execute format(
		'create constraint trigger %I after insert or update or delete on public.%I '
		'deferrable initially deferred for each row '
		'execute function public.definitoria_no_se_ofrece()',
		'trg_definitoria_no_se_ofrece', 'arquitectura_rasgos');
end $$;

do $$
declare
	v_arquitectura uuid;
	v_rasgo uuid;
	v_valor uuid;
	v_error text;
	v_definitorias_de_rasgo integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **El catálogo entero pasa**, incluidos ya los rasgos.
	if public.preguntas_que_ofrecen_una_definitoria() is not null then
		raise exception 'Sigue habiendo incumplimientos: %',
			public.preguntas_que_ofrecen_una_definitoria();
	end if;

	-- **Y las definitorias de rasgo entero siguen pasando**, que es lo que la garantía no debe tocar.
	select count(*) into v_definitorias_de_rasgo
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.activo and a.activo and ar.modalidad = 'definitoria' and ar.valor_id is null;

	if v_definitorias_de_rasgo = 0 then
		raise exception 'No queda ninguna definitoria de rasgo entero: la comprobación no probaría nada.';
	end if;

	-- **Un disparador no está probado hasta que salta.** Se vuelve a poner la marca que se acaba de
	-- quitar y se comprueba que la base la rechaza; lo que entra se deshace.
	select ar.arquitectura_id, ar.rasgo_id, ar.valor_id
	into v_arquitectura, v_rasgo, v_valor
	from public.arquitectura_rasgos ar
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Endecasílabo suelto'
		and r.slug = 'densidad_de_rima'
		and rv.nombre = 'Ninguna';

	begin
		update public.arquitectura_rasgos
		set modalidad = 'definitoria'
		where arquitectura_id = v_arquitectura and rasgo_id = v_rasgo and valor_id = v_valor;
		set constraints all immediate;
		raise exception 'La base ha admitido un valor de rasgo definitorio ofrecido como opción.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%no es una alternativa que elegir%' then
			raise exception 'Ha fallado por otra razón: %', v_error;
		end if;
	end;

	set constraints all immediate;
end $$;

commit;
