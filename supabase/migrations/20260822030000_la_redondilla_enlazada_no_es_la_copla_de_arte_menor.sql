-- La redondilla enlazada no es la copla de arte menor
--
-- Las dos salieron el mismo día y las dos hablan de redondillas que enlazan, así que la confusión
-- es la primera que alguien se va a hacer al leerlas — se la hizo el IP en cuanto vio la lista. El
-- catálogo tiene un sitio para responderla, que es el vínculo entre las dos, y hasta ahora no lo
-- tenían: la redondilla enlazada se relacionaba con la redondilla y con el terceto encadenado, y la
-- copla de arte menor con la redondilla y con la copla castellana, pero entre sí no decían nada.
--
-- **La prueba que las separa es contar dos vueltas.** Dos de la enlazada dan `abbc-cdde`: ocho
-- versos con cinco clases, y la última abierta. Una copla de arte menor tiene ocho versos con dos o
-- tres clases y no deja ninguna abierta. Nunca coinciden.
--
-- Y de fondo: la copla de arte menor es **una estrofa que se cose por dentro** —una rima vuelve de
-- la primera semiestrofa a la segunda y ahí se cierra—, mientras que la redondilla enlazada es
-- **una serie que se cose por fuera**, y lo que la cose es un verso quebrado que la copla no tiene.

begin;

do $$
declare
	v_copla uuid;
	v_enlazada uuid;
	v_n integer;

	c_nota constant text :=
		'Las dos enlazan redondillas por la rima, y se separan por dónde: la copla de arte menor es '
		|| 'una estrofa de ocho versos que se cose por dentro —una rima vuelve de la primera '
		|| 'semiestrofa a la segunda y ahí se cierra, sin pasar de tres clases—, y la redondilla '
		|| 'enlazada es una serie abierta que se cose por fuera, con un verso quebrado que estrena '
		|| 'la clase con que abre la estrofa siguiente. Dos vueltas de la enlazada dan ocho versos '
		|| 'con cinco clases y una abierta; la copla de arte menor nunca llega ahí.';
begin
	select forma_id into v_copla from public.formas_metricas where slug = 'copla_de_arte_menor';
	select forma_id into v_enlazada from public.formas_metricas where slug = 'redondilla_enlazada';
	if v_copla is null or v_enlazada is null then
		raise exception 'Falta la copla de arte menor o la redondilla enlazada.';
	end if;

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_enlazada, v_copla, 'contrasta_con', c_nota
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_enlazada and forma_destino_id = v_copla)
			or (forma_origen_id = v_copla and forma_destino_id = v_enlazada)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	-- Lo que la nota afirma, comprobado contra el dato y no contra el recuerdo.
	if not exists (
		select 1 from public.formas_metricas
		where forma_id = v_enlazada and nivel_estructural = 'serie'
	) or not exists (
		select 1 from public.formas_metricas
		where forma_id = v_copla and nivel_estructural = 'estrofa'
	) then
		raise exception 'Una de las dos ha cambiado de nivel y la nota deja de ser cierta.';
	end if;

	-- La enlazada cicla y la copla no.
	if exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_enlazada and er.tipo_secuencia <> 'ciclo'
	) or exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_copla and er.tipo_secuencia = 'ciclo'
	) then
		raise exception 'El reparto entre ciclo y secuencia ya no separa a las dos formas.';
	end if;

	-- Ninguna disposición de la copla pasa de tres clases, que es el otro extremo de la nota.
	if exists (
		select 1 from public.esquemas_rima er
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_copla
			and (select count(distinct p.clase_rima) from public.esquema_rima_posiciones p
				where p.esquema_rima_id = er.esquema_rima_id) > 3
	) then
		raise exception 'Alguna disposición de la copla de arte menor pasa de tres clases.';
	end if;

	-- Y el quebrado, que es lo que de verdad las distingue a simple vista.
	if not exists (
		select 1 from public.esquema_metrico_posiciones p
		join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id
		join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
		join public.metros m on m.metro_id = p.metro_id
		where a.forma_id = v_enlazada and m.silabas = 4
	) then
		raise exception 'La redondilla enlazada ha dejado de llevar su quebrado.';
	end if;

	select count(*) into v_n
	from jsonb_array_elements(
		public.get_forma_metrica_publica('redondilla_enlazada') -> 'relaciones'
	);
	if v_n < 3 then
		raise exception 'La redondilla enlazada trae % vínculos, y debería traer al menos tres.', v_n;
	end if;
end $$;

commit;
