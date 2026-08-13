-- Tres endechas y tres silvas sin repetirse.
--
-- Tercera tanda de la revisión una a una de `esquemas_rima.descripcion` con el IP. Las tres
-- endechas repetían medida, notación o régimen y dejaban en la glosa hechos históricos que ya
-- viven como afirmaciones de fuente. Las tres silvas repetían la distinción estructurada por
-- medida, densidad de rima y organización en pareados.
--
-- La poda de las silvas se hace solo después de comprobar que no las vuelve indistinguibles
-- entre sí ni del endecasílabo suelto, que fue un deslinde problemático durante la revisión.

do $$
declare
	vaciadas integer;
	acortadas integer;
	perfil_suelto integer;
	perfil_silva_endecasilabica integer;
	perfil_silva_irregular integer;
	perfil_silva_regular integer;
begin
	-- La generalización de la asonantada, la introducción de la variedad de cinco versos por sor
	-- Juana y el empleo anterior en versos sueltos deben seguir en afirmaciones de fuente.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
		where a.slug = 'heptasilabica_con_endecasilabo'
			and af.resumen ilike '%generalizó%forma asonantada%'
	) then
		raise exception 'falta el respaldo histórico de la endecha asonantada';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
		where a.slug = 'heptasilabica_con_endecasilabo_de_cinco'
			and af.resumen ilike '%sor Juana%introdujo%variedades métricas%'
	) then
		raise exception 'falta el respaldo de sor Juana para la endecha de cinco versos';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		left join public.formas_metricas f on f.forma_id = af.forma_id
		left join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
		where (f.slug = 'endecha_real' or a.slug = 'heptasilabica_con_endecasilabo')
			and af.resumen ilike '%emplead%versos sueltos%'
			and (af.resumen ilike '%antes%' or af.resumen ilike '%cuando recibió rimas%')
	) then
		raise exception 'falta el respaldo del empleo anterior de la endecha en versos sueltos';
	end if;

	-- El endecasílabo suelto ocupa el extremo de baja densidad y baja organización.
	select count(*) into perfil_suelto
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	join public.rasgos_metricos rg using (rasgo_id)
	left join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	where f.slug = 'endecasilabo_suelto' and a.slug = 'endecasilabica'
		and (
			(rg.slug = 'densidad_de_rima' and rv.slug in ('ninguna', 'esporadica'))
			or (rg.slug = 'organizacion_en_pareados' and rv.slug in ('ninguna', 'ocasionales'))
		);
	if perfil_suelto <> 4 then
		raise exception 'el perfil distintivo del endecasílabo suelto tiene % filas y debería tener 4', perfil_suelto;
	end if;

	-- La silva de endecasílabos se distingue por rima mayoritaria y pareados que llegan a ser
	-- habituales o predominantes.
	select count(*) into perfil_silva_endecasilabica
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	join public.rasgos_metricos rg using (rasgo_id)
	left join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	where f.slug = 'silva' and a.slug = 'endecasilabica'
		and (
			(rg.slug = 'densidad_de_rima' and rv.slug = 'mayoritaria')
			or (rg.slug = 'organizacion_en_pareados' and rv.slug in ('habituales', 'predominantes'))
		);
	if perfil_silva_endecasilabica <> 3 then
		raise exception 'el perfil distintivo de la silva endecasilábica tiene % filas y debería tener 3', perfil_silva_endecasilabica;
	end if;

	-- La irregular admite 7 y 11 sílabas, rima mayoritaria o total y pareados predominantes.
	select count(*) into perfil_silva_irregular
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	join public.rasgos_metricos rg using (rasgo_id)
	left join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	where f.slug = 'silva' and a.slug = 'consonante_irregular'
		and (
			(rg.slug = 'densidad_de_rima' and rv.slug in ('mayoritaria', 'total'))
			or (rg.slug = 'organizacion_en_pareados' and rv.slug = 'predominantes')
		);
	if perfil_silva_irregular <> 3 then
		raise exception 'el perfil distintivo de la silva irregular tiene % filas y debería tener 3', perfil_silva_irregular;
	end if;

	-- La regular declara pareados regulares y un esquema fijo de dos posiciones `aA`.
	select count(*) into perfil_silva_regular
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	join public.rasgos_metricos rg using (rasgo_id)
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	where f.slug = 'silva' and a.slug = 'consonante_regular'
		and rg.slug = 'organizacion_en_pareados' and rv.slug = 'regulares';
	if perfil_silva_regular <> 1 or not exists (
		select 1
		from public.esquemas_rima er
		join public.arquitecturas_forma a using (arquitectura_id)
		join public.formas_metricas f using (forma_id)
		where f.slug = 'silva' and a.slug = 'consonante_regular'
			and er.slug = 'pareados-regulares' and er.notacion = '[aA]…'
	) then
		raise exception 'la silva regular no conserva su organización y su ciclo aA';
	end if;

	-- Tres endechas y dos silvas quedan sin glosa: todo su contenido vive ya en datos
	-- estructurados o en afirmaciones bibliográficas.
	with objetivo(forma_slug, arquitectura_slug, esquema_slug) as (values
		('endecha_real', 'heptasilabica_con_endecasilabo', 'asonantada'),
		('endecha_real', 'heptasilabica_con_endecasilabo_de_cinco', 'redondilla_con_endecasilabo'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'suelta'),
		('silva', 'endecasilabica', 'consonante-con-pareados-no-sistematicos'),
		('silva', 'consonante_irregular', 'consonante-orden-libre')
	)
	update public.esquemas_rima er
	set descripcion = null, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	where er.arquitectura_id = a.arquitectura_id
		and er.slug = o.esquema_slug and er.descripcion is not null;
	get diagnostics vaciadas = row_count;
	if vaciadas <> 5 then
		raise exception 'se esperaban cinco glosas vaciadas y se vaciaron %', vaciadas;
	end if;

	-- En la regular solo queda lo que `[aA]…` no dice por sí solo: cada repetición renueva la
	-- clase, en vez de mantener la misma `a` durante toda la serie.
	update public.esquemas_rima er
	set descripcion = 'La clase de rima se renueva en cada bloque.', updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'consonante_regular'
		and er.slug = 'pareados-regulares'
		and er.descripcion is distinct from 'La clase de rima se renueva en cada bloque.';
	get diagnostics acortadas = row_count;
	if acortadas <> 1 then
		raise exception 'se esperaba acortar una glosa de silva y se acortaron %', acortadas;
	end if;
end;
$$;
