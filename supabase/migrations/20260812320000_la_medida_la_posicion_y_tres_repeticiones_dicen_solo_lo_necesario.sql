-- Una descripción métrica y una nota de posición salen; tres repeticiones conservan su función.
--
-- Los dos primeros textos duplicaban literalmente la rejilla o la descripción de arquitectura.
-- Las repeticiones de la sextina, en cambio, necesitan explicar cómo circulan las palabras: se
-- reescriben sin hablar del catálogo ni atribuir al modelo lo que las fuentes no determinan.

do $$
declare
	metricas_actualizadas integer;
	posiciones_actualizadas integer;
	repeticiones_actualizadas integer;
begin
	-- La lectura del remate clásico permanece respaldada en la tabla bibliográfica antes de
	-- condensar las descripciones de la clásica y la doble petrarquista.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'sextina'
			and af.resumen ilike '%una palabra interior y otra final por verso%'
			and af.resumen ilike '%no lo impone como pareja universal%'
	) then
		raise exception 'falta la afirmación sobre las palabras interiores y finales del remate';
	end if;

	-- La formulación positiva de Montemayor solo resume lo que ya afirma Navarro Tomás.
	if not exists (
		select 1
		from public.afirmaciones_fuentes_metricas af
		join public.formas_metricas f on f.forma_id = af.forma_id
		where f.slug = 'sextina'
			and af.resumen ilike '%doce estrofas con combinaciones distintas%'
			and af.resumen ilike '%no detalla su disposición dentro de los dos tercetos%'
	) then
		raise exception 'falta la afirmación ampliada de Navarro Tomás sobre la doble sextina';
	end if;

	update public.esquemas_metricos em
	set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where em.arquitectura_id = a.arquitectura_id
		and f.slug = 'sextina' and a.slug = 'doble_montemayor'
		and em.slug = '11-repetido'
		and em.descripcion = 'La misma medida endecasilábica ocupa los versos de los dos tercetos finales.';

	get diagnostics metricas_actualizadas = row_count;
	if metricas_actualizadas <> 1 then
		raise exception 'se esperaba vaciar una descripción métrica y se vaciaron %', metricas_actualizadas;
	end if;

	update public.esquema_rima_posiciones p
	set nota = null, updated_at = now()
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where p.esquema_rima_id = er.esquema_rima_id
		and f.slug = 'decima' and a.slug = 'aumentada'
		and er.slug = 'abbaaccddeed' and p.posicion = 7
		and p.nota = 'El miembro final crece de cuatro versos a seis con una clase de rima nueva; la primera redondilla y el enlace no cambian.'
		and a.descripcion = 'Alarga el miembro final de cuatro versos a seis, con una clase de rima nueva; la primera redondilla y los versos de enlace no cambian. Aparece intercalada entre décimas normales, no como forma aparte.';

	get diagnostics posiciones_actualizadas = row_count;
	if posiciones_actualizadas <> 1 then
		raise exception 'se esperaba vaciar una nota de posición y se vaciaron %', posiciones_actualizadas;
	end if;

	with objetivo(arquitectura_slug, descripcion_actual, descripcion_nueva) as (values
		(
			'clasica',
			'Seis palabras finales permutadas en seis estrofas y recuperadas en el terceto. En el terceto aparecen las seis, una interior y otra final en cada verso: la forma no impone una única asociación por parejas.',
			'Las seis palabras finales se permutan durante seis estrofas y reaparecen en el terceto final, una en el interior y otra al final de cada verso. No se prescribe una única asociación por parejas.'
		),
		(
			'doble_petrarquista',
			'Seis palabras finales permutadas durante dos ciclos estróficos y recuperadas en el terceto. En el terceto aparecen las seis, una interior y otra final en cada verso: la forma no impone una única asociación por parejas.',
			'Las seis palabras finales se permutan durante dos ciclos estróficos y reaparecen en el terceto final, una en el interior y otra al final de cada verso. No se prescribe una única asociación por parejas.'
		),
		(
			'doble_montemayor',
			'Seis palabras finales distribuidas en doce combinaciones estróficas distintas y dos tercetos finales. No se declaran sus posiciones porque la fuente no da ni la secuencia de las doce permutaciones ni una distribución por parejas.',
			'Las seis palabras finales se distribuyen en doce combinaciones estróficas distintas y reaparecen en dos tercetos finales.'
		)
	)
	update public.repeticiones_metricas r
	set descripcion = o.descripcion_nueva, updated_at = now()
	from objetivo o
	join public.arquitecturas_forma a on a.slug = o.arquitectura_slug
	join public.formas_metricas f on f.forma_id = a.forma_id and f.slug = 'sextina'
	where r.arquitectura_id = a.arquitectura_id
		and r.slug = 'palabra_final'
		and r.descripcion = o.descripcion_actual;

	get diagnostics repeticiones_actualizadas = row_count;
	if repeticiones_actualizadas <> 3 then
		raise exception 'se esperaban tres repeticiones actualizadas y se cambiaron %', repeticiones_actualizadas;
	end if;
end;
$$;
