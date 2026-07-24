begin;

alter table public.secuencias_metricas
	alter column intervencion_personajes_femeninos drop default,
	alter column intervencion_personajes_femeninos drop not null,
	alter column intervencion_figuras_donaire drop default,
	alter column intervencion_figuras_donaire drop not null,
	alter column intervencion_personajes_sobrenaturales drop default,
	alter column intervencion_personajes_sobrenaturales drop not null;

comment on column public.secuencias_metricas.intervencion_personajes_femeninos is
	'Indica si en esta secuencia métrica intervienen verbalmente personajes femeninos. NULL significa pendiente de revisión.';

comment on column public.secuencias_metricas.intervencion_figuras_donaire is
	'Indica si en esta secuencia métrica intervienen verbalmente figuras de donaire. NULL significa pendiente de revisión.';

comment on column public.secuencias_metricas.intervencion_personajes_sobrenaturales is
	'Indica si en esta secuencia métrica intervienen verbalmente personajes sobrenaturales. NULL significa pendiente de revisión.';

-- La función métrica histórica convierte la ausencia de exclusiva/compartida
-- en "sin_intervencion". Corregimos después sus tres agregados para conservar
-- NULL mientras quede alguna secuencia pendiente de revisar.
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
		intervencion_femenina = agregado.intervencion_femenina,
		intervencion_donaire = agregado.intervencion_donaire,
		intervencion_sobrenaturales = agregado.intervencion_sobrenaturales
	from (
		select
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
