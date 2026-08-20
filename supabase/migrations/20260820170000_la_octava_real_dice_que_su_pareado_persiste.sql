-- La octava real dice que su pareado persiste
--
-- Dos remates de la revisión anterior, los dos señalados por el IP al leer la ficha.
--
-- 1. **El bloque de rima no anunciaba que hubiera más disposiciones.** El esquema abierto estaba
--    declarado, pero no se veía: la tarjeta imprime, para un esquema abierto, *o* sus
--    restricciones *o* el texto «La disposición no está fijada» — nunca los dos. Al ponerle la
--    restricción de tres clases desapareció el aviso y quedó solo la cifra, que no anuncia nada.
--    No hace falta tocar código: la tarjeta ya pinta la **descripción** del esquema debajo de sus
--    restricciones, y este no tenía. Se la damos, y dice lo que la restricción no puede decir —
--    **qué** es lo que varía—, que es el dato del *Diccionario*: «otra disposición de la rima de
--    los seis primeros versos».
--
-- 2. **El pareado final se declara como rasgo, que es donde cabe decirlo con frecuencia.** Una
--    «restricción blanda» no existe: `esquema_rima_restricciones` no tiene modalidad y sus reglas
--    son absolutas. El rasgo `distico_final` sí la tiene, y `habitual` es literalmente lo que dice
--    Jauralde: «conservando **casi siempre** de manera fija el pareado final».
--
--    Al auditar la forma se descartó este rasgo con el argumento de que el dibujo ya muestra el
--    pareado de `ABABABCC`, y escribir lo que la figura dibuja es lo que la regla prohíbe. **Ese
--    argumento dejó de valer** en cuanto se declaró el esquema abierto: desde que el orden puede
--    variar, el pareado es justamente lo que **persiste entre disposiciones**, y eso ninguna
--    figura lo dice.
--
--    No se marca `definitoria` porque sería afirmar que no falta nunca, y las fuentes dicen «casi
--    siempre». Con `habitual` aparecerá bajo «Rasgos permitidos», que se lee más flojo de lo que
--    es; lo corrige la modalidad impresa al lado, y es como se comporta el resto del catálogo.
--
-- El rasgo y su valor estaban redactados para series —«La **serie** concluye con dos versos
-- rimados entre sí»— porque hasta hoy solo los usaba el endecasílabo suelto. Se generalizan a la
-- unidad, que es lo que son en una estrofa y en una serie. Es texto interno del catálogo y no
-- llega a la ficha pública, pero quedaría mal escrito.

begin;

do $$
declare
	v_arq uuid;
	v_abierto uuid;
	v_rasgo uuid;
	v_valor uuid;
	v_ficha jsonb;
	v_actual text;

	c_descripcion constant text :=
		'Los seis primeros versos admiten otro orden; es realización poco frecuente.';

	c_nota constant text :=
		'Las variantes documentadas alteran el orden de los seis primeros versos y conservan el '
		|| 'pareado.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'octava_real' and a.slug = 'endecasilabica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'La octava real no tiene su arquitectura activa.';
	end if;

	select esquema_rima_id into v_abierto from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';

	if v_abierto is null then
		raise exception 'La octava real no tiene su esquema de disposición variable.';
	end if;

	-- ------------------------------------------------- 1. El aviso que la restricción tapó
	update public.esquemas_rima set descripcion = c_descripcion
	where esquema_rima_id = v_abierto;

	-- ------------------------------------------- 2. El pareado, con su frecuencia
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'distico_final';
	select valor_id into v_valor
	from public.rasgo_valores where rasgo_id = v_rasgo and slug = 'presente';

	if v_rasgo is null or v_valor is null then
		raise exception 'No existe el rasgo «distico_final» con valor «presente».';
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values (v_arq, v_rasgo, v_valor, 'habitual', c_nota)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update set nota = excluded.nota;

	-- El rasgo deja de hablar solo de series, ahora que lo declara también una estrofa.
	update public.rasgos_metricos
	set descripcion = 'La unidad concluye con dos versos rimados entre sí.'
	where rasgo_id = v_rasgo;

	update public.rasgo_valores
	set descripcion = 'La unidad concluye con un dístico rimado.'
	where valor_id = v_valor;

	-- ------------------------------------------------------------------ Comprobaciones
	v_ficha := public.get_forma_metrica_publica('octava_real');

	-- La descripción llega a la ficha, que es de lo que se trataba.
	if not exists (
		select 1 from jsonb_array_elements(v_ficha -> 'esquemasRima') e
		where e ->> 'esquema_rima_id' = v_abierto::text
			and e ->> 'descripcion' = c_descripcion
	) then
		raise exception 'La ficha no trae la descripción del esquema de disposición variable.';
	end if;

	-- Y el pareado se declara con su frecuencia, no como norma.
	if not exists (
		select 1 from jsonb_array_elements(v_ficha -> 'arquitecturaRasgos') r
		where r ->> 'rasgo_id' = v_rasgo::text
			and r ->> 'valor_id' = v_valor::text
			and r ->> 'modalidad' = 'habitual'
	) then
		raise exception 'La ficha no declara el dístico final como habitual.';
	end if;

	-- La restricción sigue acotando el esquema **abierto**, que es lo que acota de verdad: dice
	-- que una disposición no catalogada tampoco puede estrenar una cuarta clase de rima.
	select count(*)::text into v_actual
	from public.esquema_rima_restricciones r
	join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
	where er.arquitectura_id = v_arq and er.tipo_secuencia = 'abierta' and r.tipo = 'numero_clases';
	if v_actual <> '1' then
		raise exception 'La restricción de tres clases ya no cuelga del esquema abierto.';
	end if;
end $$;

commit;
