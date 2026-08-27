-- Una definitoria no puede ofrecerse como opción
--
-- `modalidad` es **una escala de frecuencia** y `definitoria` es su tope: «se da siempre; sin esto la
-- arquitectura no sería la que es». De ahí se sigue que **una definitoria no es una alternativa entre
-- las que elegir**, sino la norma que las alternativas cumplen. Si aparece en una pregunta, lo que se
-- le está pidiendo al editor es que escoja entre la norma y su negación.
--
-- Se comprobó el 10 de agosto de 2026 al arreglar la endecha real, y se volvió a comprobar el 27 al
-- arreglar la copla manriqueña —cuya pregunta ofrecía `abcabc|defdef` marcada definitoria, y era la
-- única del catálogo que lo hacía—. Las dos veces se comprobó **y se dejó sin sostener**: nada impedía
-- volver a romperlo. Esto lo sostiene.
--
-- **Es más estricta que la frase de agosto**, que decía «junto a otra modalidad». Se enunció así
-- porque el caso de la endecha ofrecía la definitoria entre hermanas, pero el de la manriqueña la
-- ofrecía **sola** y estaba igual de mal: una pregunta con una sola opción que la norma ya fija es una
-- pregunta que no debería existir. Lo que no puede es ofrecerse, acompañada o no.
--
-- **Alcanza a las tres tablas cuya `modalidad` describe una realización** —esquemas de rima,
-- repeticiones y variedades—. **Los rasgos quedan fuera a propósito:** en `arquitectura_rasgos`,
-- `definitoria` no dice que un valor sea la norma sino que **el rasgo caracteriza la arquitectura**, y
-- entonces preguntar cuál de sus valores se lee es justo lo que hay que hacer. Hoy hay un caso así, la
-- densidad de rima del endecasílabo suelto, y es correcto.
--
-- Los disparadores son **diferidos**: una migración puede dejar el catálogo incoherente a mitad de
-- camino mientras lo deje coherente al terminar.

begin;

-- La comprobación vive **fuera** del disparador, en una función normal: así puede ejecutarse a mano
-- —en la guarda de esta migración, o el día que se quiera auditar el catálogo— y no solo al escribir.
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
		where g.activo
			and 'definitoria' in (
				coalesce(er.modalidad, ''),
				coalesce(rm.modalidad, ''),
				coalesce(va.modalidad, '')
			)
	) malas;

	if v_n = 0 then
		return null;
	end if;
	return v_n || ' pregunta(s): ' || v_mal;
end;
$$;

create or replace function public.definitoria_no_se_ofrece()
returns trigger
language plpgsql
as $$
declare
	v_mal text;
begin
	v_mal := public.preguntas_que_ofrecen_una_definitoria();
	if v_mal is not null then
		raise exception 'Una definitoria no es una alternativa que elegir, y la ofrecen %.', v_mal;
	end if;
	return null;
end;
$$;

comment on function public.preguntas_que_ofrecen_una_definitoria() is
	'Sostiene que ninguna pregunta del catálogo ofrezca una realización definitoria entre sus opciones. Los rasgos quedan fuera: allí «definitoria» dice que el rasgo caracteriza la arquitectura, no que un valor sea la norma.';

do $$
declare
	v_tabla text;
begin
	foreach v_tabla in array array[
		'esquemas_rima',
		'repeticiones_metricas',
		'variedades_arquitectura',
		'grupos_eleccion_metrica'
	] loop
		execute format('drop trigger if exists %I on public.%I',
			'trg_definitoria_no_se_ofrece', v_tabla);
		execute format(
			'create constraint trigger %I after insert or update or delete on public.%I '
			'deferrable initially deferred for each row '
			'execute function public.definitoria_no_se_ofrece()',
			'trg_definitoria_no_se_ofrece', v_tabla);
	end loop;
end $$;

do $$
declare
	v_esquema uuid;
	v_error text;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Un disparador no está probado hasta que salta.** Se vuelve a poner la marca que se quitó esta
	-- misma tarde y se comprueba que la base lo rechaza; lo que entra se deshace.
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla manriqueña' and er.notacion = 'abcabc|defdef';

	if v_esquema is null then
		raise exception 'No está el esquema de la manriqueña con el que comprobarlo.';
	end if;

	begin
		update public.esquemas_rima set modalidad = 'definitoria' where esquema_rima_id = v_esquema;
		-- Diferido: sin esto la comprobación no ocurriría hasta el commit y la prueba no probaría nada.
		set constraints all immediate;
		raise exception 'La base ha admitido una definitoria ofrecida como opción.';
	exception when others then
		v_error := sqlerrm;
		if v_error not like '%no es una alternativa que elegir%' then
			raise exception 'Ha fallado por otra razón: %', v_error;
		end if;
	end;

	-- Y el catálogo tal como está pasa. Si no, esta migración no debería aplicarse.
	set constraints all immediate;
	if public.preguntas_que_ofrecen_una_definitoria() is not null then
		raise exception 'El catálogo ya incumple la garantía: %', public.preguntas_que_ofrecen_una_definitoria();
	end if;
end $$;

commit;
