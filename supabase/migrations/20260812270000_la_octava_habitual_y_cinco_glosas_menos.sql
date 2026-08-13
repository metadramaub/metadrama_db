-- La octava habitual y cinco glosas menos.
--
-- Segunda tanda de la revisión una a una de `esquemas_rima.descripcion` con el IP. Cuatro
-- disposiciones de la quintilla leían en prosa lo que la rejilla ya dibuja; sus juicios de
-- frecuencia están además conservados en la afirmación de Morley y Bruerton. La `abbba`
-- conserva solo la comparación que una fila aislada no enseña.
--
-- En la octava real, `ABABABCC` no es definitoria: las fuentes documentan otras disposiciones,
-- menos frecuentes, que suelen conservar el pareado final. Se declara por tanto `habitual` y
-- ese alcance se explica en la definición de la forma, que es donde se sitúa el repertorio sin
-- fingir variantes que el catálogo no ha modelado.

do $$
declare
	vaciadas integer;
	acortadas integer;
	octava_tocada integer;
	definicion_tocada integer;
	respaldo_quintilla integer;
	respaldo_octava integer;
begin
	-- Antes de podar los juicios bibliográficos, su contenido tiene que seguir consultable como
	-- afirmación de fuente.
	select count(*) into respaldo_quintilla
	from public.afirmaciones_fuentes_metricas af
	join public.formas_metricas f on f.forma_id = af.forma_id
	where f.slug = 'quintilla'
		and af.resumen ilike '%le sigue%'
		and af.resumen ilike '%muy rara%'
		and af.resumen ilike '%muy poca frecuencia%';
	if respaldo_quintilla = 0 then
		raise exception 'faltan los juicios de frecuencia de Morley y Bruerton sobre la quintilla';
	end if;

	select count(*) into respaldo_octava
	from public.afirmaciones_fuentes_metricas af
	join public.formas_metricas f on f.forma_id = af.forma_id
	where f.slug = 'octava_real'
		and (
			af.resumen ilike '%otra disposición%'
			or (af.resumen ilike '%variaciones%' and af.resumen ilike '%pareado final%')
		);
	if respaldo_octava < 2 then
		raise exception 'la variación de la octava real solo tiene % respaldos y deberían ser al menos dos', respaldo_octava;
	end if;

	-- `aabba`, `aabab`, `ababb` y `abbaa`: la disposición está completa en las cinco celdas;
	-- las referencias al pareado o a la redondilla son maneras de leer ese mismo dibujo.
	with objetivo(esquema_slug) as (values
		('aabba'),
		('aabab'),
		('ababb'),
		('abbaa')
	)
	update public.esquemas_rima er
	set descripcion = null, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = 'quintilla'
	join public.arquitecturas_forma a
		on a.forma_id = f.forma_id and a.slug = 'octosilabica_consonante'
	where er.arquitectura_id = a.arquitectura_id
		and er.slug = o.esquema_slug
		and er.descripcion is not null;
	get diagnostics vaciadas = row_count;
	if vaciadas <> 4 then
		raise exception 'se esperaban cuatro glosas de quintilla y se vaciaron %', vaciadas;
	end if;

	-- `abbba`: la triple rima se ve, pero no que ninguna otra disposición la admite.
	update public.esquemas_rima er
	set descripcion = 'Tres versos seguidos con la misma rima, lo que ninguna otra disposición admite.',
		updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'quintilla' and a.slug = 'octosilabica_consonante'
		and er.slug = 'abbba'
		and er.descripcion is distinct from
			'Tres versos seguidos con la misma rima, lo que ninguna otra disposición admite.';
	get diagnostics acortadas = row_count;
	if acortadas <> 1 then
		raise exception 'se esperaba acortar una glosa de quintilla y se acortaron %', acortadas;
	end if;

	-- La disposición corriente de la octava deja de hacerse pasar por condición necesaria. Su
	-- glosa se vacía porque la definición de la forma conserva ya el matiz que aportaba.
	update public.esquemas_rima er
	set modalidad = 'habitual', descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'octava_real' and a.slug = 'endecasilabica_consonante'
		and er.slug = 'abababcc'
		and (er.modalidad is distinct from 'habitual' or er.descripcion is not null);
	get diagnostics octava_tocada = row_count;
	if octava_tocada <> 1 then
		raise exception 'se esperaba actualizar una disposición de octava real y se actualizaron %', octava_tocada;
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de ocho versos endecasílabos con rima consonante. Su disposición habitual es ABABABCC: los seis primeros alternan dos rimas y los dos últimos forman un pareado con una tercera. Se documentan variantes menos frecuentes en los seis primeros versos, que suelen conservar el pareado final.',
		updated_at = now()
	where slug = 'octava_real';
	get diagnostics definicion_tocada = row_count;
	if definicion_tocada <> 1 then
		raise exception 'se esperaba actualizar una definición de octava real y se actualizaron %', definicion_tocada;
	end if;

	if not exists (
		select 1 from public.formas_metricas
		where slug = 'octava_real'
			and definicion like 'Estrofa de ocho versos endecasílabos con rima consonante.%'
			and definicion ilike '%variantes menos frecuentes%'
	) then
		raise exception 'la definición matizada de la octava real no quedó guardada';
	end if;
end;
$$;
