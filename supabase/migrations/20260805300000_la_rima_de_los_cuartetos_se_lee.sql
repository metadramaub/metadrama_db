-- Los cuartetos del soneto declaran sus dos disposiciones y ninguna llegaba al lector.
--
-- La ficha del soneto enseñaba, bajo «Rima», solo las cuatro disposiciones de los tercetos.
-- Las de los cuartetos —`ABBA` preferente y `ABAB` admitida— **están declaradas** desde la
-- migración `20260801150000`, pero no salían por ninguna parte.
--
-- La causa no era un filtro sino el modelo, y el modelo tiene razón: los dos esquemas de los
-- cuartetos pertenecen a la arquitectura del **cuarteto endecasílabo**, no a la del soneto.
-- Es lo coherente con reutilizar en vez de duplicar. Pero la ficha agrupa los esquemas por
-- `arquitectura_id`, así que en el soneto no aparecían, y la sección que sí los referencia
-- solo guardaba el nombre de la arquitectura reutilizada. De ahí salía «Reutiliza el
-- repertorio de "Endecasilábica"»: una arquitectura suelta, sin decir de qué forma es ni qué
-- rima trae.
--
-- Se arregla en la carga —la sección trae ahora los esquemas de la arquitectura que
-- referencia— y en la ficha, que en vez de aquella frase imprime la rima: «ABBA (abrazada) ·
-- ABAB (cruzada)». Aquí solo queda la prosa que sobra o que falta.
--
-- 1 · **Se retira la nota de los tercetos.** «El esquema de rima no se declara en la sección
--     porque entrelaza los dos tercetos…» explica una decisión de modelado a un lector que no
--     la necesita, y además se deduce sola al ver que las cuatro disposiciones cuelgan de la
--     unidad y no de la sección.
--
-- 2 · **Las descripciones de los dos esquemas del cuarteto** empezaban a leerse ahora en la
--     ficha del soneto, y estaban vacías. Dicen ya qué distingue a cada disposición, sin
--     repetir la notación que va al lado.
--
-- 3 · **La nota de la sección de cuartetos** se queda con lo que aporta —que los dos cuartetos
--     comparten sus dos clases de rima— y suelta lo que ahora se ve solo.

begin;

do $$
declare
	v_soneto uuid;
	v_cuarteto uuid;
	v_abba uuid;
	v_abab uuid;
begin
	select arquitectura_id into v_soneto from public.arquitecturas_forma
	where forma_id = (select forma_id from public.formas_metricas where slug = 'soneto');

	select a.arquitectura_id into v_cuarteto
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'cuarteto' and a.slug = 'endecasilabica';

	if v_soneto is null or v_cuarteto is null then
		raise exception 'Falta la arquitectura del soneto o la del cuarteto endecasílabo';
	end if;

	select esquema_rima_id into v_abba from public.esquemas_rima
	where arquitectura_id = v_cuarteto and notacion = 'ABBA';
	select esquema_rima_id into v_abab from public.esquemas_rima
	where arquitectura_id = v_cuarteto and notacion = 'ABAB';

	if v_abba is null or v_abab is null then
		raise exception 'El cuarteto endecasílabo no declara ABBA y ABAB';
	end if;

	-- 1 · La nota técnica sobra.
	update public.estructuras_secciones
	set nota = null
	where arquitectura_id = v_soneto and slug = 'terceto';

	-- 2 · Los dos esquemas del cuarteto, que ahora se leen también desde el soneto.
	update public.esquemas_rima
	set descripcion = 'Las dos clases de rima se abrazan: la primera envuelve a la segunda. Es la disposición regular del cuarteto endecasílabo y la del soneto.'
	where esquema_rima_id = v_abba;

	update public.esquemas_rima
	set descripcion = 'Las dos clases de rima alternan verso a verso. Es la disposición del serventesio, y en el soneto una realización documentada aunque menos frecuente.'
	where esquema_rima_id = v_abab;

	-- 3 · La nota de la sección dice lo que no se ve.
	update public.estructuras_secciones
	set nota = 'Los dos cuartetos comparten sus dos clases de rima: no estrenan rima el segundo.'
	where arquitectura_id = v_soneto and slug = 'cuarteto';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
