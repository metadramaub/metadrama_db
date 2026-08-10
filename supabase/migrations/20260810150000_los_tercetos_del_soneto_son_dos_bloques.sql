-- Los tercetos del soneto son dos bloques de tres, y el esquema declara de qué sección es.
--
-- Los cuatro esquemas de tercetos tenían sus **seis posiciones en `bloque 1`, consecutivas** y
-- sin `seccion`: declaraban una tirada de seis versos. No lo es. Son dos tercetos que comparten
-- las clases de rima, y por eso el blanco que los separa saltaba como anomalía.
--
-- El modelo ya sabía decirlo y el soneto no lo decía. La redondilla `abbaacca` —dos redondillas
-- que enlazan su rima— reparte sus posiciones en `bloque 1` y `bloque 2` y las nombra con su
-- sección. Aquí se hace lo mismo: bloque 1 y bloque 2 de tres posiciones, ambos de la sección
-- `terceto`. Las clases C, D y E siguen siendo las mismas en los dos bloques, que es justo lo
-- que distingue al soneto de dos tercetos sueltos.
--
-- LA REGLA GENERAL QUE SALE DE AQUÍ, y que era la pregunta de fondo: para reutilizar una forma
-- con rima propia **no hace falta nada nuevo**. La sección sigue remitiendo a la forma y hereda
-- de ella lo que la hace esa forma —medida, extensión, identidad—; el esquema específico se
-- declara en la arquitectura contenedora y se reparte en bloques. Lo declarado gana sobre lo
-- heredado, y lo heredado es solo el valor por defecto.
--
-- Y SE SEPARAN DOS COSAS QUE IBAN JUNTAS. `grupos_eleccion_metrica.seccion_id` dice **dónde se
-- responde**: el editor plantea la pregunta en cada realización de esa sección. Eso no sirve para
-- los tercetos, porque la sección se realiza dos veces y la respuesta es una sola —de hecho, si
-- el grupo la declarase, el editor preguntaría dos veces—. De **qué trata** la respuesta lo dice
-- ahora el esquema, con `esquemas_rima.seccion_id`, y de ahí toma su sujeto el enunciado.
--
-- Con eso, el grupo de los tercetos deja por fin de llamarse «Esquema de rima» a secas: pasa a
-- «Tercetos · Esquema de rima» sin mentir sobre dónde se pregunta.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El esquema declara de qué sección es
-- ---------------------------------------------------------------------------

alter table public.esquemas_rima
	add column if not exists seccion_id uuid
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict;

comment on column public.esquemas_rima.seccion_id is
	'De qué sección habla este esquema, cuando no habla de la unidad entera. No dice dónde se pregunta —eso lo dice el grupo de elección—, sino de qué trata la respuesta: los cuatro esquemas de tercetos del soneto describen las dos realizaciones de su sección a la vez.';

-- Los que ya lo decían de otra manera: si una sola sección fija ese esquema, esa es la suya.
update public.esquemas_rima er
set seccion_id = (
		select s.seccion_id from public.estructuras_secciones s
		where s.esquema_rima_id = er.esquema_rima_id
	),
	updated_at = now()
where er.seccion_id is null
	and (
		select count(*) from public.estructuras_secciones s
		where s.esquema_rima_id = er.esquema_rima_id
	) = 1;

-- Y los del soneto, que no los fijaba ninguna sección.
update public.esquemas_rima er
set seccion_id = s.seccion_id, updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.estructuras_secciones s
	on s.arquitectura_id = a.arquitectura_id and s.tipo_seccion = 'terceto'
where er.arquitectura_id = a.arquitectura_id and f.slug = 'soneto' and er.seccion_id is null;

-- ---------------------------------------------------------------------------
-- 2 · Las seis posiciones pasan a ser dos bloques de tres
-- ---------------------------------------------------------------------------

-- Primero las tres últimas, que se van al bloque 2 y vuelven a numerarse desde 1. Se cambian
-- bloque y posición en la misma sentencia para no pasar por un estado que choque consigo mismo.
update public.esquema_rima_posiciones p
set bloque = 2, posicion = p.posicion - 3, seccion = 'terceto', updated_at = now()
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
where p.esquema_rima_id = er.esquema_rima_id and f.slug = 'soneto'
	and p.bloque = 1 and p.posicion > 3;

update public.esquema_rima_posiciones p
set seccion = 'terceto', updated_at = now()
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
where p.esquema_rima_id = er.esquema_rima_id and f.slug = 'soneto'
	and p.bloque = 1 and p.seccion is null;

-- ---------------------------------------------------------------------------
-- 3 · El enunciado toma el sujeto del esquema cuando el grupo no lo nombra
-- ---------------------------------------------------------------------------

drop view if exists public.propuesta_elecciones_secuencia;
drop view if exists public.grupos_eleccion_metrica_resueltos;

create view public.grupos_eleccion_metrica_resueltos with (security_invoker = on) as
select g.*,
	case
		when g.dimension = 'rasgo' then rm.pregunta
		when g.dimension = 'repeticion' then rep.nombre
		else concat_ws(' · ', coalesce(s.nombre, esq.nombre),
			case g.dimension
				when 'rima' then case
					when g.tipo_control = 'esquema_rima' then 'Esquema de rima observado'
					else 'Esquema de rima' end
				when 'metro' then case
					when m.quebrados then 'Medida de los quebrados'
					when m.posicional then 'Medida de cada verso'
					else 'Medida de los versos' end
				when 'combinacion' then 'Variedad'
			end)
	end as nombre
from public.grupos_eleccion_metrica g
left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
left join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
left join lateral (
	select coalesce(bool_and(o.posicion_unidad is not null), false) as posicional,
		coalesce(bool_and(eo.rol = 'quebrado'), false) as quebrados
	from public.opciones_eleccion_metrica o
	left join public.esquemas_metricos em on em.arquitectura_id = g.arquitectura_id
	left join public.esquema_metrico_opciones eo
		on eo.esquema_metrico_id = em.esquema_metrico_id and eo.metro_id = o.metro_id
	where o.grupo_eleccion_id = g.grupo_eleccion_id
) m on g.dimension = 'metro'
left join lateral (
	select ms.nombre
	from public.repeticiones_metricas rp
	join public.estructuras_secciones ms on ms.seccion_id = rp.materializa_seccion_id
	where rp.arquitectura_id = g.arquitectura_id
	limit 1
) rep on g.dimension = 'repeticion'
left join lateral (
	-- Cuando el grupo no nombra sección, el sujeto lo ponen los esquemas que ofrece: los cuatro
	-- del soneto dicen que hablan de los tercetos aunque la pregunta se haga una sola vez.
	select ss.nombre
	from public.opciones_eleccion_metrica o
	join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
	join public.estructuras_secciones ss on ss.seccion_id = er.seccion_id
	where o.grupo_eleccion_id = g.grupo_eleccion_id
	group by ss.nombre
	limit 1
) esq on g.dimension = 'rima' and g.seccion_id is null;

comment on view public.grupos_eleccion_metrica_resueltos is
	'Las preguntas del editor con su enunciado calculado al leer. El enunciado es corto y sin artículo, con el nombre de la sección delante: la que el grupo declara si la declara, y si no la que declaran los esquemas que ofrece. El editor pliega en una sola las preguntas que comparten dimensión y enunciado, y así las dos mudanzas del villancico se siguen respondiendo juntas.';

grant select on public.grupos_eleccion_metrica_resueltos to authenticated;

create view public.propuesta_elecciones_secuencia as
with derivado as (
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null
	union all
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null
	union all
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null
	union all
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null
),
declarado as (
	select e.termino_id, e.grupo_eleccion_id, o.opcion_eleccion_id
	from public.equivalencias_respuestas_legadas e
	join public.opciones_eleccion_metrica o
		on o.grupo_eleccion_id = e.grupo_eleccion_id
		and o.metro_id is not distinct from e.metro_id
		and o.esquema_rima_id is not distinct from e.esquema_rima_id
		and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
		and o.variedad_id is not distinct from e.variedad_id
		and o.repeticion_id is not distinct from e.repeticion_id
		and o.posicion_unidad is not distinct from e.posicion_unidad
),
reclamado as (
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from derivado
	union
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from declarado
)
select p.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
	r.opcion_eleccion_id, o.nombre as respuesta, g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
join public.grupos_eleccion_metrica_resueltos g
	on g.grupo_eleccion_id = r.grupo_eleccion_id
	and g.arquitectura_id = p.arquitectura_propuesta_id
	and g.activo
join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
where g.alcance = 'secuencia'
	or g.alcance = 'unidad'
		and a.unidad_versos_min is not null
		and (p.v_fin - p.v_ini + 1) = a.unidad_versos_min;

comment on view public.propuesta_elecciones_secuencia is
	'Las respuestas que el término legado ya contenía, para cada secuencia. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Los cuatro esquemas del soneto son ya dos bloques de tres.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto'
		and (
			select count(distinct p.bloque) from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id
		) <> 2;
	if v_n <> 0 then
		raise exception '% esquemas del soneto no se reparten en dos bloques', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto' and (p.posicion not between 1 and 3 or p.seccion is distinct from 'terceto');
	if v_n <> 0 then
		raise exception '% posiciones del soneto quedan fuera de un terceto de tres', v_n;
	end if;

	-- Y las clases de rima no se han movido: siguen siendo las mismas seis, en el mismo orden.
	select string_agg(p.clase_rima, '' order by p.bloque, p.posicion) into v_mal
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	where er.slug = 'cdedce';
	if v_mal <> 'CDEDCE' then
		raise exception 'Las clases de «CDE DCE» quedaron como %', v_mal;
	end if;

	-- El grupo de los tercetos ya dice de qué habla, sin declarar dónde se responde.
	select nombre into v_mal from public.grupos_eleccion_metrica_resueltos where slug = 'esquema_tercetos';
	if v_mal <> 'Tercetos · Esquema de rima' then
		raise exception 'El grupo de los tercetos se llama «%»', v_mal;
	end if;

	select count(*) into v_n
	from public.grupos_eleccion_metrica_resueltos
	where activo and coalesce(btrim(nombre), '') = '';
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin enunciado', v_n;
	end if;

	-- Una pregunta que no nombra sección no puede ofrecer esquemas de dos secciones distintas:
	-- si eso pasara, su enunciado elegiría un sujeto al azar entre los dos.
	select count(*) into v_n from (
		select o.grupo_eleccion_id
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		where g.seccion_id is null and er.seccion_id is not null
		group by o.grupo_eleccion_id having count(distinct er.seccion_id) > 1
	) s;
	if v_n <> 0 then
		raise exception '% preguntas ofrecen esquemas de secciones distintas sin nombrar la suya', v_n;
	end if;

	-- El plegado del editor no se mueve, ni las respuestas ni lo que el término legado proponía.
	select count(*) into v_n from (
		select 1 from public.grupos_eleccion_metrica_resueltos
		where activo group by arquitectura_id, dimension, nombre having count(*) > 1
	) s;
	if v_n <> 3 then
		raise exception 'El editor plegaría % preguntas en vez de las 3 del villancico', v_n;
	end if;

	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then
		raise exception 'Las opciones derivadas dejaron de ser 405 y son %', v_n;
	end if;

	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'La propuesta de respuestas debe seguir dando 91 filas, y da %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
