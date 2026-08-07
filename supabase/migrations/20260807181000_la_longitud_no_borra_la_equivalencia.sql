-- La incompatibilidad de longitud no debe borrar información legada.
--
-- La versión anterior dejaba la arquitectura nula cuando ninguna encajaba. Eso marcaba bien
-- la duda, pero hacía desaparecer respuestas que el término antiguo sí declara, como las siete
-- asonancias de romances con rangos irregulares. Se conserva la arquitectura principal como
-- hipótesis revisable y se mantiene el aviso de longitud. Si hay alguna compatible, sigue
-- teniendo prioridad sobre la principal.

begin;

create or replace view public.propuesta_metrica_secuencia as
with recursive
reclamaciones as (
	select f.origen_termino_id as termino_id, f.forma_id, null::uuid as arquitectura_id,
		null::text as detalle, 1 as prioridad
	from public.formas_metricas f where f.origen_termino_id is not null
	union all
	select f.forma_id, f.forma_id, null::uuid, null::text, 2
	from public.formas_metricas f join public.vocabularios v on v.termino_id = f.forma_id
	union all
	select a.origen_termino_id, a.forma_id, a.arquitectura_id, null::text, 1
	from public.arquitecturas_forma a where a.origen_termino_id is not null
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
	select rv.origen_termino_id, null::uuid, null::uuid,
		r.nombre || ' = ' || rv.nombre, 4
	from public.rasgo_valores rv
	join public.rasgos_metricos r on r.rasgo_id = rv.rasgo_id
	where rv.origen_termino_id is not null
	union all
	select m.origen_termino_id, null::uuid, null::uuid, 'metro «' || m.nombre || '»', 4
	from public.metros m where m.origen_termino_id is not null
),
reclamacion as (
	select distinct on (termino_id) termino_id, forma_id, arquitectura_id, detalle
	from reclamaciones
	order by termino_id, (forma_id is null), prioridad
),
ascendencia as (
	select v.termino_id as origen, v.termino_id as actual, 0 as salto
	from public.vocabularios v where v.categoria = 'estrofa_tipo'
	union all
	select a.origen, padre.termino_id, a.salto + 1
	from ascendencia a
	join public.vocabularios hijo on hijo.termino_id = a.actual
	join public.vocabularios padre on padre.termino_id = hijo.termino_padre_id
	where a.salto < 8
),
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
	select v.termino_id,
		case
			when d.forma_id is not null then 'directa'
			when d.termino_id is not null and h.forma_id is not null then 'rasgo'
			when d.termino_id is not null then 'rasgo'
			when h.forma_id is not null then 'ascendencia'
			else 'sin_destino'
		end as via,
		coalesce(d.forma_id, h.forma_id) as forma_id,
		case when d.forma_id is not null then d.arquitectura_id else h.arquitectura_id end
			as arquitectura_id,
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
	coalesce(arq_directa.arquitectura_id, arq_compatible.arquitectura_id)
		as arquitectura_propuesta_id,
	coalesce(arq_directa.nombre, arq_compatible.nombre) as arquitectura_propuesta,
	coalesce(r.via, 'sin_tipo') as via,
	r.detalle,
	r.heredado_de,
	case
		when f.forma_id is null then null
		when arq_directa.arquitectura_id is not null then
			regla_directa.arquitectura_id is null
			or (
				(s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos
					= regla_directa.residuo_versos
			)
		else arq_compatible.compatible
	end as longitud_compatible,
	case
		when f.forma_id is null then null
		when arq_directa.arquitectura_id is not null
			and regla_directa.arquitectura_id is not null
			and not (
				(s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos
					= regla_directa.residuo_versos
			)
		then format(
			'La arquitectura «%s» no admite una secuencia de %s versos: %s.',
			arq_directa.nombre, s.v_fin - s.v_ini + 1, regla_directa.explicacion
		)
		when r.arquitectura_id is null and not arq_compatible.compatible
		then format(
			'Ninguna arquitectura activa de «%s» admite una secuencia de %s versos.',
			f.nombre, s.v_fin - s.v_ini + 1
		)
		else null
	end as motivo_revision
from public.secuencias_metricas s
left join public.vocabularios voc on voc.termino_id = s.estrofa_tipo_id
left join resolucion r on r.termino_id = s.estrofa_tipo_id
left join public.formas_metricas f on f.forma_id = r.forma_id
left join public.arquitecturas_forma arq_directa
	on arq_directa.arquitectura_id = r.arquitectura_id
left join public.arquitecturas_reglas_longitud regla_directa
	on regla_directa.arquitectura_id = arq_directa.arquitectura_id
left join lateral (
	select
		a.arquitectura_id,
		a.nombre,
		regla.arquitectura_id is null
			or (
				(s.v_fin - s.v_ini + 1) >= regla.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla.modulo_versos = regla.residuo_versos
			) as compatible
	from public.arquitecturas_forma a
	left join public.arquitecturas_reglas_longitud regla
		on regla.arquitectura_id = a.arquitectura_id
	where a.forma_id = f.forma_id
		and a.activo
		and r.arquitectura_id is null
	order by compatible desc, a.principal desc, a.orden nulls last
	limit 1
) arq_compatible on true;

comment on view public.propuesta_metrica_secuencia is
	'Propuesta revisable de forma y arquitectura para cada secuencia legada. La vía explica el origen de la equivalencia; longitud_compatible y motivo_revision comprueban por separado si la extensión cabe en la arquitectura. Cuando el término solo da la forma, se elige la arquitectura principal entre las compatibles; si no existe ninguna, se conserva la principal y se marca la incompatibilidad. Una arquitectura sin regla derivada se considera de longitud abierta.';

grant select on public.propuesta_metrica_secuencia to authenticated;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

