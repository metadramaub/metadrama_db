-- Respuestas que un término legado implica y que `origen_termino_id` no puede expresar.
--
-- El caso que lo hizo necesario: los cuatro términos específicos de soneto empiezan todos
-- por `ABBAABBA`, así que todos implican cuartetos abrazados. Pero el esquema «Abrazada»
-- solo puede declarar **un** `origen_termino_id` —la columna es única— y esos términos ya
-- están reclamados por sus esquemas de tercetos. Tres términos, un destino: no cabe.
--
-- Es el mismo límite que aparece en el endecasílabo suelto, en el pareado y en los
-- esdrújulos. `origen_termino_id` sirve para el uno a uno; esta tabla, para lo demás.
--
-- No sustituye a `origen_termino_id`: lo completa. La vista une las dos fuentes.

begin;

create table if not exists public.equivalencias_respuestas_legadas (
	termino_id uuid not null references public.vocabularios (termino_id)
		on update cascade on delete cascade,
	grupo_eleccion_id uuid not null references public.grupos_eleccion_metrica (grupo_eleccion_id)
		on update cascade on delete cascade,
	opcion_eleccion_id uuid not null references public.opciones_eleccion_metrica (opcion_eleccion_id)
		on update cascade on delete cascade,
	nota text,
	created_at timestamptz not null default now(),
	primary key (termino_id, grupo_eleccion_id, opcion_eleccion_id)
);

comment on table public.equivalencias_respuestas_legadas is
	'Respuestas del formulario que un término del vocabulario legado implica, cuando no se pueden deducir siguiendo `origen_termino_id` porque varios términos apuntan al mismo destino. Se rellena editorialmente y solo con lo que el término dice sin lugar a duda.';

comment on column public.equivalencias_respuestas_legadas.nota is
	'Por qué ese término implica esa respuesta. Es la justificación filológica, no un comentario.';

alter table public.equivalencias_respuestas_legadas enable row level security;

drop policy if exists equivalencias_respuestas_lectura on public.equivalencias_respuestas_legadas;
create policy equivalencias_respuestas_lectura
	on public.equivalencias_respuestas_legadas
	for select to authenticated using (true);

drop policy if exists equivalencias_respuestas_escritura on public.equivalencias_respuestas_legadas;
create policy equivalencias_respuestas_escritura
	on public.equivalencias_respuestas_legadas
	for all to authenticated
	using (public.auth_is_admin_or_ip())
	with check (public.auth_is_admin_or_ip());

-- ---------------------------------------------------------------------------
-- Los cuartetos del soneto
--
-- Los cuatro términos específicos declaran el esquema completo en su propio nombre y los
-- cuatro empiezan por ABBAABBA. El vocabulario viejo no contempló el soneto de cuartetos
-- cruzados; el catálogo sí lo admite, y por eso la pregunta existe y hay que contestarla.
-- ---------------------------------------------------------------------------

insert into public.equivalencias_respuestas_legadas (termino_id, grupo_eleccion_id, opcion_eleccion_id, nota)
select
	v.termino_id,
	g.grupo_eleccion_id,
	o.opcion_eleccion_id,
	'El término declara el esquema completo en su nombre y empieza por ABBAABBA.'
from public.vocabularios v
cross join lateral (
	select g.grupo_eleccion_id
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto' and g.nombre ilike '%cuartetos%' and g.activo
	limit 1
) g
join public.opciones_eleccion_metrica o
	on o.grupo_eleccion_id = g.grupo_eleccion_id and o.nombre = 'ABBA ABBA'
where v.categoria = 'estrofa_tipo'
	and v.termino like 'soneto%ABBAABBA%'
on conflict do nothing;

do $$
declare
	v_total integer;
begin
	select count(*) into v_total from public.equivalencias_respuestas_legadas;
	if v_total = 0 then
		raise exception 'No se declaró ninguna respuesta: revisa los nombres de la pregunta y de la opción';
	end if;
	raise notice 'Respuestas legadas declaradas: %', v_total;
end $$;

-- ---------------------------------------------------------------------------
-- La propuesta une ahora las dos fuentes
-- ---------------------------------------------------------------------------

create or replace view public.propuesta_elecciones_secuencia as
with derivado as (
	-- Deducidas siguiendo `origen_termino_id` hasta la opción que selecciona esa entidad.
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null and o.activo

	union all
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null and o.activo

	union all
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null and o.activo

	union all
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null and o.activo
),
reclamado as (
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from derivado
	union
	-- Declaradas a mano, para lo que el uno a uno no alcanza.
	select termino_id, grupo_eleccion_id, opcion_eleccion_id
	from public.equivalencias_respuestas_legadas
)
select
	p.secuencia_id,
	g.grupo_eleccion_id,
	g.nombre as pregunta,
	r.opcion_eleccion_id,
	o.nombre as respuesta,
	g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
-- La pregunta tiene que ser de la arquitectura que se propone: el mismo valor de asonancia
-- lo ofrecen las cuatro arquitecturas del romance, y solo vale la de esta secuencia.
join public.grupos_eleccion_metrica g
	on g.grupo_eleccion_id = r.grupo_eleccion_id
	and g.arquitectura_id = p.arquitectura_propuesta_id
	and g.activo
join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
where
	g.alcance = 'secuencia'
	-- Una respuesta por unidad solo se propone cuando la secuencia es exactamente una unidad:
	-- si contiene varias, el término legado decía una sola cosa de todas ellas y darla por
	-- buena afirmaría que son idénticas. En Dido y Eneas sabemos que no lo son.
	or (
		g.alcance = 'unidad'
		and a.unidad_versos_min is not null
		and p.v_fin - p.v_ini + 1 = a.unidad_versos_min
	);

comment on view public.propuesta_elecciones_secuencia is
	'Respuestas del formulario que se deducen del término legado de cada secuencia, sumando lo que se sigue de `origen_termino_id` y lo declarado en `equivalencias_respuestas_legadas`. Las de ámbito unidad solo aparecen cuando la secuencia es una sola unidad. Es una propuesta para revisar, no una asignación.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

commit;
