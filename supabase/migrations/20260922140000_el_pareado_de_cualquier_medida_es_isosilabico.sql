-- El pareado de cualquier medida es isosilábico, no mixto
--
-- `esquemas_metricos` distingue desde siempre dos cosas con dos campos: `tipo_secuencia = 'conjunto'`
-- enumera el repertorio de medidas admitidas, y `medida_uniforme` dice si dentro de la unidad todos
-- los versos comparten una de ellas o si se combinan.
--
-- El pareado «de cualquier medida» tenía `medida_uniforme = false`, y eso dice que **mezcla** sus
-- ocho medidas —de tetrasílabo a alejandrino— dentro de una unidad de dos versos. No es lo que es:
-- un pareado de cualquier medida es **isosilábico de medida libre**, sus dos versos miden igual y
-- lo que no se sabe es cuál. Con el campo en falso, el demarcador resumía su repertorio en «mixto»
-- y **responder «arte mayor» lo contradecía**: una sucesión de pareados endecasílabos quedaba
-- descartada en la primera pregunta y no volvía a aparecer ni entre las ocho primeras candidatas.
--
-- No se tocan los conjuntos que sí combinan, que son mayoría y están bien: la silva alterna siete y
-- once, el pareado alirado combina siete y once, y las liras, la sáfica, la endecha y la seguidilla
-- declaran sus medidas por posiciones.

begin;

update public.esquemas_metricos em
set medida_uniforme = true,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id
	and f.slug = 'pareado'
	and a.slug = 'cualquier_medida'
	and em.tipo_secuencia = 'conjunto'
	and em.medida_uniforme is distinct from true;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

do $guarda$
declare
	v_uniforme boolean;
	v_silva int;
	v_alirado boolean;
begin
	-- 1. El pareado de cualquier medida quedó uniforme.
	select em.medida_uniforme into v_uniforme
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'cualquier_medida' and em.tipo_secuencia = 'conjunto';

	if v_uniforme is not true then
		raise exception 'El pareado de cualquier medida sigue sin declararse isosilábico.';
	end if;

	-- 2. Y los que sí combinan no se han movido: la silva alterna de verdad.
	select count(*) into v_silva
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'silva' and em.tipo_secuencia = 'conjunto' and em.medida_uniforme is not false;

	if v_silva > 0 then
		raise exception 'Algún conjunto de la silva ha quedado declarado uniforme, y la silva combina.';
	end if;

	select em.medida_uniforme into v_alirado
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'alirado' and em.tipo_secuencia = 'conjunto';

	if v_alirado is not false then
		raise exception 'El pareado alirado combina siete y once: no puede quedar uniforme.';
	end if;

	-- 3. La regla que queda vigilada: un conjunto uniforme no puede declarar más medidas que
	--    versos tiene su unidad, porque entonces no serían alternativas sino una combinación.
	if exists (
		select 1
		from public.esquemas_metricos em
		join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
		where em.tipo_secuencia = 'conjunto'
			and em.medida_uniforme = true
			and a.unidad_versos_max is not null
			and (
				select count(distinct m.silabas)
				from public.esquema_metrico_opciones o
				join public.metros m on m.metro_id = o.metro_id
				where o.esquema_metrico_id = em.esquema_metrico_id
			) < 1
	) then
		raise exception 'Hay un conjunto uniforme sin ninguna medida declarada.';
	end if;
end
$guarda$;

commit;
