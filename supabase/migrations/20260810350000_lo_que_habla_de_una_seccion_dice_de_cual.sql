-- Lo que habla de una sección dice de cuál.
--
-- `ambito` nació el 28 de julio con cinco valores —`unidad · estrofa · serie · seccion ·
-- composicion`—, una escala de niveles estructurales. Se estrechó después a dos y dejó de ser una
-- escala para volverse un sí/no: «esto habla de la unidad» o «esto habla de una sección». Pero no
-- de cuál.
--
-- `seccion_id` llegó el 10 de agosto con los tercetos del soneto, y dice exactamente eso. Donde
-- conviven, **se contradicen**: seis esquemas del villancico declaran ámbito de sección sin
-- apuntar a ninguna, y el `pareados-regulares` de la silva apunta a la sección `pareado` mientras
-- declara ámbito de unidad.
--
-- Y la ficha pública ha tenido que **adivinar** para poder pintarlos: asigna la única sección que
-- aún no tiene rima y, si hay más de una candidata, se rinde y los deja sin parte. Eso no es una
-- columna que funcione; es una heurística tapando un dato que falta.
--
-- Esta migración llena el hueco. La siguiente deriva `ambito` y lo retira.
--
-- LOS SEIS DEL VILLANCICO SON DE LA MUDANZA, no del estribillo. Se preguntó al IP si eran de la
-- `cabeza` o del `estribillo` —las dos arquitecturas nombran distinto la misma sección, según el
-- estribillo aparezca antes o después de la primera copla— y la pregunta estaba mal hecha: el
-- propio dato lo dice sin ambigüedad. Se llaman «Mudanza en redondilla», «Mudanza en redondilla
-- cruzada» y «Mudanza asonantada», y las seis descripciones rezan «alternativa habitual para la
-- mudanza de cuatro versos».
--
-- LOS CUATRO ESQUEMAS MÉTRICOS también se nombran solos: el `5-7-5` de la seguidilla compuesta es
-- el de su estribillo, y el endecasílabo repetido de las tres sextinas es el de su remate —el
-- terceto final, en la de Montemayor—. `esquemas_metricos` no tenía dónde decirlo, así que se le
-- añade la columna que ya tienen los esquemas de rima.

begin;

-- 1 · Los esquemas métricos también pueden hablar de una parte.

alter table public.esquemas_metricos
	add column if not exists seccion_id uuid
		references public.estructuras_secciones (seccion_id) on update cascade on delete set null;

comment on column public.esquemas_metricos.seccion_id is
	'La parte de la que habla el esquema. Nulo cuando habla de la unidad entera.';

update public.esquemas_metricos e
set seccion_id = s.seccion_id,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f, public.estructuras_secciones s
where a.arquitectura_id = e.arquitectura_id
	and f.forma_id = a.forma_id
	and s.arquitectura_id = e.arquitectura_id
	and e.ambito = 'seccion'
	and e.seccion_id is null
	and (
		(f.slug = 'seguidilla' and s.slug = 'estribillo')
		or (f.slug = 'sextina' and s.slug in ('remate', 'terceto_final'))
	);

-- 2 · Los seis del villancico son de la mudanza.

update public.esquemas_rima e
set seccion_id = s.seccion_id,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f, public.estructuras_secciones s
where a.arquitectura_id = e.arquitectura_id
	and f.forma_id = a.forma_id
	and s.arquitectura_id = e.arquitectura_id
	and f.slug = 'villancico'
	and s.slug = 'mudanza'
	and e.ambito = 'seccion'
	and e.seccion_id is null;

-- 3 · Y el de la silva ya apuntaba a su sección; lo que decía mal era el ámbito.

update public.esquemas_rima
set ambito = 'seccion',
	updated_at = now()
where seccion_id is not null and ambito <> 'seccion';

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
	v_slug text;
begin
	-- El invariante que hace derivable el ámbito: decir «sección» y apuntar a una sección son ya
	-- lo mismo, en las dos tablas de esquemas.
	select count(*), string_agg(t || ' · ' || slug, ', ' order by t, slug) into v_n, v_mal
	from (
		select 'rima' t, e.slug, e.ambito, e.seccion_id from public.esquemas_rima e
		union all
		select 'metrico', e.slug, e.ambito, e.seccion_id from public.esquemas_metricos e
	) x
	where (ambito = 'seccion') <> (seccion_id is not null);
	if v_n <> 0 then
		raise exception '% esquemas discrepan entre ámbito y sección: %', v_n, v_mal;
	end if;

	-- Y ninguna sección señalada es de otra arquitectura.
	select count(*) into v_n
	from (
		select e.arquitectura_id, e.seccion_id from public.esquemas_rima e where e.seccion_id is not null
		union all
		select e.arquitectura_id, e.seccion_id from public.esquemas_metricos e where e.seccion_id is not null
	) x
	join public.estructuras_secciones s on s.seccion_id = x.seccion_id
	where s.arquitectura_id <> x.arquitectura_id;
	if v_n <> 0 then
		raise exception '% esquemas señalan una sección de otra arquitectura', v_n;
	end if;

	-- Los seis del villancico quedaron en la mudanza, y ninguno en la cabeza ni en el estribillo.
	select count(*) into v_n
	from public.esquemas_rima e
	join public.estructuras_secciones s on s.seccion_id = e.seccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = e.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and s.slug = 'mudanza';
	if v_n <> 6 then
		raise exception '% esquemas del villancico en la mudanza en vez de 6', v_n;
	end if;

	-- Y los cuatro métricos, en su parte.
	select count(*) into v_n from public.esquemas_metricos where seccion_id is not null;
	if v_n <> 4 then
		raise exception '% esquemas métricos con sección en vez de 4', v_n;
	end if;

	-- Se ejecuta lo que proyecta esquemas: un cuerpo entrecomillado no se revalida solo, y aquí
	-- se ha añadido una columna a una tabla que varias funciones leen con `select` explícito.
	for v_slug in select slug from public.formas_metricas loop
		select public.get_forma_metrica_publica_jerarquica(v_slug) into v_json;
		if v_json is null then
			raise exception 'La ficha jerárquica salió vacía para %', v_slug;
		end if;
	end loop;

	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ?& array['metricPatterns', 'rhymePatterns']) then
		raise exception 'El catálogo del demarcador salió sin sus claves';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
