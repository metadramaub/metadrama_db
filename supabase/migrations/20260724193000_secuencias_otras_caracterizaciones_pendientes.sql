begin;

-- Solo se modifican restricciones y valores por defecto. Los valores ya
-- guardados se conservan exactamente como están.
alter table public.secuencias_metricas
	alter column inaugura_espacio drop default,
	alter column inaugura_espacio drop not null,
	alter column versos_partidos drop default,
	alter column versos_partidos drop not null,
	alter column evocacion_metrica drop default,
	alter column evocacion_metrica drop not null;

comment on column public.secuencias_metricas.inaugura_espacio is
	'Indica si la secuencia inaugura un espacio escénico. NULL significa pendiente de revisión.';

comment on column public.secuencias_metricas.versos_partidos is
	'Indica si la secuencia contiene versos partidos. NULL significa pendiente de revisión.';

comment on column public.secuencias_metricas.evocacion_metrica is
	'Indica si hay evocación métrica en la secuencia. NULL significa pendiente de revisión.';

-- La función métrica histórica usa coalesce(..., false). Sobrescribimos los
-- agregados afectados después de ejecutarla para que una secuencia pendiente
-- no se publique como una respuesta negativa.
create or replace function public.recompute_obra_resumen(p_obra_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	perform public.recompute_obra_resumen_metricas(p_obra_id);

	update public.obras_resumen resumen
	set
		tiene_versos_partidos = agregado.tiene_versos_partidos,
		tiene_cambio_espacio = agregado.tiene_cambio_espacio,
		intervencion_femenina = agregado.intervencion_femenina,
		intervencion_donaire = agregado.intervencion_donaire,
		intervencion_sobrenaturales = agregado.intervencion_sobrenaturales
	from (
		select
			case
				when count(*) = 0 then null
				when bool_or(sm.versos_partidos is null) then null
				else bool_or(sm.versos_partidos)
			end as tiene_versos_partidos,
			case
				when count(*) = 0 then null
				when bool_or(sm.inaugura_espacio is null) then null
				else bool_or(sm.inaugura_espacio)
			end as tiene_cambio_espacio,
			case
				when count(*) = 0 then null
				when count(*) filter (where sm.intervencion_personajes_femeninos is null) > 0 then null
				when count(*) filter (where sm.intervencion_personajes_femeninos = 'exclusiva') > 0
					and count(*) filter (where sm.intervencion_personajes_femeninos = 'compartida') > 0
					then 'mixta'
				when count(*) filter (where sm.intervencion_personajes_femeninos = 'exclusiva') > 0
					then 'exclusiva'
				when count(*) filter (where sm.intervencion_personajes_femeninos = 'compartida') > 0
					then 'compartida'
				else 'sin_intervencion'
			end as intervencion_femenina,
			case
				when count(*) = 0 then null
				when count(*) filter (where sm.intervencion_figuras_donaire is null) > 0 then null
				when count(*) filter (where sm.intervencion_figuras_donaire = 'exclusiva') > 0
					and count(*) filter (where sm.intervencion_figuras_donaire = 'compartida') > 0
					then 'mixta'
				when count(*) filter (where sm.intervencion_figuras_donaire = 'exclusiva') > 0
					then 'exclusiva'
				when count(*) filter (where sm.intervencion_figuras_donaire = 'compartida') > 0
					then 'compartida'
				else 'sin_intervencion'
			end as intervencion_donaire,
			case
				when count(*) = 0 then null
				when count(*) filter (where sm.intervencion_personajes_sobrenaturales is null) > 0 then null
				when count(*) filter (where sm.intervencion_personajes_sobrenaturales = 'exclusiva') > 0
					and count(*) filter (where sm.intervencion_personajes_sobrenaturales = 'compartida') > 0
					then 'mixta'
				when count(*) filter (where sm.intervencion_personajes_sobrenaturales = 'exclusiva') > 0
					then 'exclusiva'
				when count(*) filter (where sm.intervencion_personajes_sobrenaturales = 'compartida') > 0
					then 'compartida'
				else 'sin_intervencion'
			end as intervencion_sobrenaturales
		from public.secuencias_metricas sm
		where sm.obra_id = p_obra_id
	) agregado
	where resumen.obra_id = p_obra_id;

	perform public.recompute_obra_resumen_estructura(p_obra_id);
end;
$$;

grant execute on function public.recompute_obra_resumen(uuid) to authenticated;
grant execute on function public.recompute_obra_resumen(uuid) to service_role;

commit;
