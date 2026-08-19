-- El cuarteto dice de dónde le vienen sus nombres
--
-- Es la forma más escueta del catálogo: **dos textos de prosa y ninguno que sobre**. La revisión
-- no retira nada; lo que hace es alargar la definición y escribir la descripción de arquitectura,
-- que estaba vacía siendo la única.
--
-- La definición se queda entera y añade lo que un lector necesita para no bajar a la figura: las
-- notaciones, el corte por arte del verso tal como lo formula Domínguez Caparrós —«si los versos
-- son de arte mayor, se llama cuarteto»—, **la asimetría de los nombres** —la cruzada tiene tres
-- denominaciones y la abrazada ninguna, y eso hoy se ve sin que nada lo explique— y el vínculo
-- con el soneto, que es donde el cuarteto se encuentra la mayor parte de las veces.
--
-- La descripción de la arquitectura explica por qué el catálogo marca `abba` como habitual y
-- `abab` como admitida, que hoy también se ve sin razón aparente: lo dice Navarro Tomás § 463,
-- ya registrado, y la relación se invierte fuera del corpus áureo.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de cuatro versos de arte mayor con rima consonante repartida en dos clases, abrazada o cruzada. Es la misma estrofa que la redondilla, de la que solo la separa el arte del verso.';
	v_nuevo constant text :=
		'Estrofa de cuatro versos de arte mayor con rima consonante repartida en dos clases, abrazada (ABBA) o cruzada (ABAB). Es la misma estrofa que la redondilla, de la que solo la separa el arte del verso: si los versos son de arte mayor se llama cuarteto, y si son de arte menor, redondilla. La disposición cruzada tiene además nombre propio, serventesio, que la abrazada no tiene. El endecasílabo es su realización habitual, y el cuarteto abrazado es el de los ocho primeros versos del soneto.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'cuarteto' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «cuarteto».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición del cuarteto no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;

	-- La definición afirma que la cruzada tiene nombre propio y la abrazada no: se comprueba
	-- contra el dato antes de dejarlo escrito.
	if (
		select count(*) from public.denominaciones_metricas d
		join public.esquemas_rima er on er.esquema_rima_id = d.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_forma and er.slug = 'abba'
	) <> 0 then
		raise exception 'La disposición abrazada del cuarteto tiene denominaciones y la definición dice que no.';
	end if;

	if (
		select count(*) from public.denominaciones_metricas d
		join public.esquemas_rima er on er.esquema_rima_id = d.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		where a.forma_id = v_forma and er.slug = 'abab' and d.nombre = 'Serventesio'
	) <> 1 then
		raise exception 'La disposición cruzada del cuarteto no declara «Serventesio».';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · La arquitectura, que estaba sin describir
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_actual text;
	v_nuevo constant text :=
		'Realización habitual del cuarteto, y la única que el corpus áureo documenta. La abrazada es aquí la corriente, porque es la de los cuartetos del soneto; en la poesía posterior la relación se invierte y pasa a predominar la cruzada.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'cuarteto' and a.slug = 'endecasilabica' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa cuarteto/endecasilabica.';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;

	if v_actual is not null and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no estaba vacía. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;

	-- La descripción explica la modalidad de las dos disposiciones: se comprueba que es la que
	-- el catálogo declara, porque si se invirtieran la frase quedaría al revés.
	if (
		select er.modalidad from public.esquemas_rima er
		where er.arquitectura_id = v_arq and er.slug = 'abba'
	) <> 'habitual' then
		raise exception 'La disposición abrazada del cuarteto ya no es la habitual.';
	end if;
end $$;

commit;
