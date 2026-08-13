-- Dos juicios bibliográficos que la poda no debía dejar solo en una glosa.
--
-- La rejilla hace innecesario explicar en prosa cómo se leen `ababa` y `CDE CDE`, pero no
-- puede dibujar ni la antigüedad de una disposición ni la preferencia de un autor. Esos dos
-- datos estaban en las descripciones podadas y se restituyen en su nivel propio: como
-- afirmaciones de fuente vinculadas al esquema de rima concreto.

do $$
declare
	insertadas integer;
begin
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id,
		esquema_rima_id,
		localizador,
		resumen,
		confianza,
		estado_revision
	)
	select
		fu.fuente_id,
		er.esquema_rima_id,
		'«Estrofas de cinco versos» → «Quintillas»',
		'Presenta `ababa` como «la fórmula más simple y más antigua» de la quintilla octosilábica.',
		'alta',
		'revisada'
	from public.fuentes_metricas fu
	join public.formas_metricas f on f.slug = 'quintilla'
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = 'octosilabica_consonante'
	join public.esquemas_rima er
		on er.arquitectura_id = a.arquitectura_id and er.slug = 'ababa'
	where fu.autoria like '%Jauralde%'
		and fu.titulo = 'Métrica española'
		and not exists (
			select 1
			from public.afirmaciones_fuentes_metricas previa
			where previa.fuente_id = fu.fuente_id
				and previa.esquema_rima_id = er.esquema_rima_id
				and previa.resumen ilike '%más simple y más antigua%'
		);
	get diagnostics insertadas = row_count;
	if insertadas <> 1 then
		raise exception 'se esperaba añadir una afirmación de Jauralde sobre ababa y se añadieron %',
			insertadas;
	end if;

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id,
		esquema_rima_id,
		localizador,
		resumen,
		confianza,
		estado_revision
	)
	select
		fu.fuente_id,
		er.esquema_rima_id,
		'§ 156',
		'Enumera las combinaciones más usadas en los tercetos del soneto por orden de frecuencia y señala que `CDE CDE`, la segunda, fue la preferida por Garcilaso y Herrera.',
		'alta',
		'revisada'
	from public.fuentes_metricas fu
	join public.formas_metricas f on f.slug = 'soneto'
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = 'endecasilabica_consonante'
	join public.esquemas_rima er
		on er.arquitectura_id = a.arquitectura_id and er.slug = 'cdecde'
	where fu.autoria like '%Navarro Tomás%'
		and fu.titulo = 'Métrica española'
		and not exists (
			select 1
			from public.afirmaciones_fuentes_metricas previa
			where previa.fuente_id = fu.fuente_id
				and previa.esquema_rima_id = er.esquema_rima_id
				and previa.resumen ilike '%preferida por Garcilaso y Herrera%'
		);
	get diagnostics insertadas = row_count;
	if insertadas <> 1 then
		raise exception 'se esperaba añadir una afirmación de Navarro Tomás sobre CDE CDE y se añadieron %',
			insertadas;
	end if;
end;
$$;
