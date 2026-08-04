-- La propuesta métrica resuelve por las tres vías, no solo por la directa.
--
-- La vista anterior solo miraba si algo del catálogo reclamaba el término exacto. Eso deja
-- fuera dos casos que juntos son más de un tercio del corpus:
--
--   · **rasgo** — el término de un romance no lo reclama ninguna forma sino un valor de
--     rasgo, las vocales de la asonancia. La forma hay que buscarla en el padre y el rasgo
--     se conserva aparte. Son 71 de las 216 secuencias.
--   · **ascendencia** — `endecasilabo_suelto_puro` no lo reclama nadie, pero su raíz sí.
--     Da forma y arquitectura, **no las respuestas**: si hay pareados o dístico final lo
--     sigue contestando el editor.
--
-- La vía se declara en la vista y no se esconde: una propuesta por ascendencia es menos
-- precisa que una directa, y el recuento de la fase 0 tiene que poder distinguirlas.
--
-- Es el mismo sistema de equivalencias que aplica `npm run migracion:informe`. Los dos
-- deben decir lo mismo; si se cambia uno, se cambia el otro.

begin;

drop view if exists public.propuesta_metrica_secuencia;

create view public.propuesta_metrica_secuencia as
with recursive
-- Quién reclama cada término legado y qué aporta. Una entidad que no lleva forma —un valor
-- de rasgo, un metro— aporta solo el detalle, y la forma se busca más arriba.
reclamaciones as (
	select f.origen_termino_id as termino_id, f.forma_id, null::uuid as arquitectura_id,
		null::text as detalle, 1 as prioridad
	from public.formas_metricas f
	where f.origen_termino_id is not null

	union all
	-- Una forma que reutiliza el UUID de su término legado también lo reclama.
	select f.forma_id, f.forma_id, null::uuid, null::text, 2
	from public.formas_metricas f
	join public.vocabularios v on v.termino_id = f.forma_id

	union all
	select a.origen_termino_id, a.forma_id, a.arquitectura_id, null::text, 1
	from public.arquitecturas_forma a
	where a.origen_termino_id is not null

	union all
	select e.origen_termino_id, arq.forma_id, e.arquitectura_id,
		'esquema de rima «' || e.nombre || '»', 1
	from public.esquemas_rima e
	join public.arquitecturas_forma arq on arq.arquitectura_id = e.arquitectura_id
	where e.origen_termino_id is not null

	union all
	select va.origen_termino_id, arq.forma_id, va.arquitectura_id,
		'variedad «' || va.nombre || '»', 1
	from public.variedades_arquitectura va
	join public.arquitecturas_forma arq on arq.arquitectura_id = va.arquitectura_id
	where va.origen_termino_id is not null

	union all
	select d.origen_termino_id, coalesce(d.forma_id, arq.forma_id), d.arquitectura_id,
		null::text, 3
	from public.denominaciones_metricas d
	left join public.arquitecturas_forma arq on arq.arquitectura_id = d.arquitectura_id
	where d.origen_termino_id is not null

	union all
	-- Un valor de rasgo no dice forma: solo precisa. Es el caso de los romances.
	select rv.origen_termino_id, null::uuid, null::uuid,
		r.nombre || ' = ' || rv.nombre, 4
	from public.rasgo_valores rv
	join public.rasgos_metricos r on r.rasgo_id = rv.rasgo_id
	where rv.origen_termino_id is not null

	union all
	select m.origen_termino_id, null::uuid, null::uuid, 'metro «' || m.nombre || '»', 4
	from public.metros m
	where m.origen_termino_id is not null
),
-- Una sola reclamación por término: manda la que aporte forma.
reclamacion as (
	select distinct on (termino_id)
		termino_id, forma_id, arquitectura_id, detalle
	from reclamaciones
	order by termino_id, (forma_id is null), prioridad
),
-- Cada término y toda su línea de ascendientes, con la distancia.
ascendencia as (
	select v.termino_id as origen, v.termino_id as actual, 0 as salto
	from public.vocabularios v
	where v.categoria = 'estrofa_tipo'

	union all
	select a.origen, padre.termino_id, a.salto + 1
	from ascendencia a
	join public.vocabularios hijo on hijo.termino_id = a.actual
	join public.vocabularios padre on padre.termino_id = hijo.termino_padre_id
	where a.salto < 8
),
-- La forma más cercana hacia arriba, sin contar el propio término.
heredada as (
	select distinct on (a.origen)
		a.origen as termino_id, r.forma_id, r.arquitectura_id, v.termino as desde
	from ascendencia a
	join reclamacion r on r.termino_id = a.actual
	join public.vocabularios v on v.termino_id = a.actual
	where a.salto > 0 and r.forma_id is not null
	order by a.origen, a.salto
),
resolucion as (
	select
		v.termino_id,
		case
			when d.forma_id is not null then 'directa'
			when d.termino_id is not null and h.forma_id is not null then 'rasgo'
			when d.termino_id is not null then 'rasgo'
			when h.forma_id is not null then 'ascendencia'
			else 'sin_destino'
		end as via,
		coalesce(d.forma_id, h.forma_id) as forma_id,
		case
			when d.forma_id is not null then d.arquitectura_id
			else h.arquitectura_id
		end as arquitectura_id,
		d.detalle,
		case when d.forma_id is null then h.desde end as heredado_de
	from public.vocabularios v
	left join reclamacion d on d.termino_id = v.termino_id
	left join heredada h on h.termino_id = v.termino_id
	where v.categoria = 'estrofa_tipo'
)
select
	s.secuencia_id,
	s.obra_id,
	s.v_ini,
	s.v_fin,
	s.estrofa_tipo_id,
	voc.termino as termino_legado,
	f.forma_id as forma_propuesta_id,
	f.nombre as forma_propuesta,
	-- Si la reclamación no señala arquitectura, se propone la principal de la forma.
	coalesce(arq_directa.arquitectura_id, arq_principal.arquitectura_id) as arquitectura_propuesta_id,
	coalesce(arq_directa.nombre, arq_principal.nombre) as arquitectura_propuesta,
	coalesce(r.via, 'sin_tipo') as via,
	r.detalle,
	r.heredado_de
from public.secuencias_metricas s
left join public.vocabularios voc on voc.termino_id = s.estrofa_tipo_id
left join resolucion r on r.termino_id = s.estrofa_tipo_id
left join public.formas_metricas f on f.forma_id = r.forma_id
left join public.arquitecturas_forma arq_directa
	on arq_directa.arquitectura_id = r.arquitectura_id
left join lateral (
	select a.arquitectura_id, a.nombre
	from public.arquitecturas_forma a
	where a.forma_id = f.forma_id and a.activo and r.arquitectura_id is null
	order by a.principal desc, a.orden nulls last
	limit 1
) arq_principal on true;

comment on view public.propuesta_metrica_secuencia is
	'Qué forma y arquitectura del catálogo nuevo corresponden a cada secuencia ya anotada, y por qué vía: directa, rasgo (la forma viene del padre y el término aporta precisión) o ascendencia (la forma viene del padre y las respuestas las pone el editor). Es una propuesta para revisar, no una asignación. Debe decir lo mismo que `npm run migracion:informe`.';

grant select on public.propuesta_metrica_secuencia to authenticated;

commit;
