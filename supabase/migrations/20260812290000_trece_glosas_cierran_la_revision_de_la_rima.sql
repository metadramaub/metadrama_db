-- Trece glosas cierran la revisión de la rima.
--
-- Cierre consolidado de `esquemas_rima.descripcion` después de revisar cada entrada con el IP.
-- Son las seis decisiones de la cuarta tanda y las siete últimas del campo. Todas repiten la
-- notación, las partes, los enlaces o una afirmación bibliográfica que ya vive en su tabla.
--
-- No entra la silva consonante regular: «La clase de rima se renueva en cada bloque» se conserva
-- porque `[aA]…` no permite decidir por sí solo si cada repetición renueva o mantiene la clase.

do $$
declare
	vaciadas integer;
	objetivos integer;
	enlaces_tercetos integer;
begin
	-- Las atribuciones que desaparecerán de las glosas siguen consultables como afirmaciones de
	-- fuente, vinculadas a la forma o al propio esquema cuando existe ese nivel de precisión.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.esquemas_rima er on er.esquema_rima_id = af.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'soneto' and er.slug = 'abbaabba'
			and af.resumen ilike '%rígido orden%'
	) then
		raise exception 'falta la afirmación de Morley y Bruerton sobre ABBA ABBA';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'copla_de_arte_mayor'
			and af.resumen ilike '%Laberinto de Fortuna%'
			and af.resumen ilike '%ABBAACCA%'
	) then
		raise exception 'falta la atribución de ABBAACCA al Laberinto de Fortuna';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'lira'
			and af.resumen ilike '%seña de identidad%'
	) then
		raise exception 'falta la afirmación sobre el pareado como seña de la lira';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'terceto_encadenado'
			and af.resumen ilike '%YZYZ%'
	) then
		raise exception 'falta la afirmación de fuente sobre el cierre YZYZ';
	end if;

	-- Los dos tercetos encadenados conservan los cuatro enlaces que llevan la rima central a los
	-- extremos del bloque siguiente; su prosa no era el único lugar donde se decía el enlace.
	select count(*) into enlaces_tercetos
	from public.esquema_rima_enlaces l
	join public.esquemas_rima er on er.esquema_rima_id = l.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado'
		and er.slug = 'encadenado-con-serventesio'
		and l.posicion_origen = 2
		and l.posicion_destino in (1, 3)
		and l.desplazamiento_bloque = 1;
	if enlaces_tercetos <> 4 then
		raise exception 'los dos tercetos conservan % enlaces y deberían conservar cuatro', enlaces_tercetos;
	end if;

	-- La lista es deliberadamente cerrada: si una entrada ya no existe o perdió su glosa, la
	-- migración se detiene en vez de firmar un cierre incompleto.
	with objetivo(forma_slug, arquitectura_slug, esquema_slug) as (values
		('cancion_petrarquista', 'sin_rima_con_pareado_final', 'aa'),
		('soneto', 'endecasilabica_consonante', 'cdedce'),
		('seguidilla', 'chamberga', 'asonancias-por-pareados'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'ababbccb'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'abbaacac'),
		('endecha_real', 'hexasilabica_con_endecasilabo', 'asonantada'),
		('cuarteto', 'endecasilabica', 'abba'),
		('soneto', 'endecasilabica_consonante', 'abbaabba'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'cruzada'),
		('terceto_encadenado', 'endecasilabica_consonante', 'encadenado-con-serventesio'),
		('lira', 'heptasilabica_endecasilabica', 'ababb'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'abbaacca'),
		('terceto_encadenado', 'octosilabica_consonante', 'encadenado-con-serventesio')
	)
	select count(*) into objetivos
	from objetivo o
	join public.formas_metricas f on f.slug = o.forma_slug
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = o.arquitectura_slug
	join public.esquemas_rima er
		on er.arquitectura_id = a.arquitectura_id and er.slug = o.esquema_slug
	where er.descripcion is not null;
	if objetivos <> 13 then
		raise exception 'se encontraron % de las trece glosas aprobadas', objetivos;
	end if;

	with objetivo(forma_slug, arquitectura_slug, esquema_slug) as (values
		('cancion_petrarquista', 'sin_rima_con_pareado_final', 'aa'),
		('soneto', 'endecasilabica_consonante', 'cdedce'),
		('seguidilla', 'chamberga', 'asonancias-por-pareados'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'ababbccb'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'abbaacac'),
		('endecha_real', 'hexasilabica_con_endecasilabo', 'asonantada'),
		('cuarteto', 'endecasilabica', 'abba'),
		('soneto', 'endecasilabica_consonante', 'abbaabba'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'cruzada'),
		('terceto_encadenado', 'endecasilabica_consonante', 'encadenado-con-serventesio'),
		('lira', 'heptasilabica_endecasilabica', 'ababb'),
		('copla_de_arte_mayor', 'dodecasilabica_compuesta', 'abbaacca'),
		('terceto_encadenado', 'octosilabica_consonante', 'encadenado-con-serventesio')
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
	if vaciadas <> 13 then
		raise exception 'se esperaban trece glosas y se vaciaron %', vaciadas;
	end if;
end;
$$;
