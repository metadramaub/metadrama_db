-- El pareado tiene dos arquitecturas: la isométrica y la alirada
--
-- El 22 de septiembre de 2026 la arquitectura «De cualquier medida» pasó a `medida_uniforme = true`
-- para que el demarcador dejara de resumir sus nueve medidas en «mixto» y de descartar una sucesión
-- de pareados endecasílabos en la primera pregunta. El esquema quedó bien y **lo que cuelga de él se
-- quedó atrás**, porque no todo se deriva:
--
--   * `opciones_eleccion_metrica` **sí** se deriva, y pasó sola de dieciocho opciones posicionales
--     —«Verso 1 · Endecasílabo», «Verso 2 · Endecasílabo»— a nueve medidas a secas.
--   * `selecciones_min` y `selecciones_max` **no**: son columnas guardadas, siguen en `2` desde el
--     31 de julio, y desde entonces la pregunta exige dos respuestas que su repertorio ya no puede
--     dar. Marcar «Endecasílabo» dos veces es imposible, así que **un pareado endecasílabo no se
--     podía anotar**: el editor decía «Revisa la pregunta» y `guardar_anotacion_metrica` rechazaba
--     la secuencia entera, de modo que al recargar la respuesta había desaparecido.
--   * La equivalencia de `pareado_endecasilabo` **tampoco**: declaraba `posicion_unidad` 1 y 2, y
--     `propuesta_elecciones_secuencia` empareja la posición con `is not distinct from`, así que
--     desde ayer la propuesta de esas dos secuencias había perdido su medida sin decirlo.
--
-- Se completa aquí lo que aquel cambio dejó a medias, y se le pone a la arquitectura el nombre de lo
-- que es: **isométrica**. El repertorio no se toca —del tetrasílabo al alejandrino— porque lo libre
-- sigue siendo cuánto miden; lo que la norma fija es que los dos midan igual. La heterometría del
-- pareado no se pierde: es la mezcla italiana de siete y once, y tiene arquitectura propia desde el
-- 24 de agosto. Quilis, que es quien precisa que los dos versos «pueden ser iguales o diferentes en
-- medida», documenta la forma entera, que es donde su afirmación cuelga: la definición del pareado
-- no cambia, porque las dos arquitecturas juntas son las dos cosas que dice.
--
-- Un pareado heterométrico que no sea de siete y once no tiene hoy dónde caer, y es deliberado: no
-- hay ninguno registrado —ni en las anotaciones nuevas, ni en las dos secuencias legadas, ni en los
-- cinco términos de pareado del vocabulario heredado, todos isosilábicos salvo el alirado—. Mientras
-- no aparezca, se anota como desviación de dimensión `metro`, que es para lo que está.
--
-- El nombre sigue la pareja que el catálogo ya usa: seis arquitecturas de las liras se llaman
-- «Heterométrico/a». El slug se queda como está, con los demás slugs pendientes de un día tranquilo.

begin;

do $cambio$
declare
	v_forma uuid;
	v_arq uuid;
	v_alirado uuid;
	v_grupo uuid;
	v_termino uuid;
	v_endeca uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'pareado';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'cualquier_medida';
	select arquitectura_id into v_alirado from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'alirado';
	if v_arq is null or v_alirado is null then
		raise exception 'El pareado no tiene sus dos arquitecturas.';
	end if;

	-- La premisa de todo lo que sigue. Si alguien devolviera el esquema a mixto, esta migración
	-- estaría diciendo lo contrario que el catálogo.
	if not exists (
		select 1 from public.esquemas_metricos
		where arquitectura_id = v_arq and tipo_secuencia = 'conjunto' and medida_uniforme = true
	) then
		raise exception 'La arquitectura del pareado libre ya no declara medida uniforme.';
	end if;

	-- ------------------------------------------------------------------ El nombre y la prosa
	update public.arquitecturas_forma
	set nombre = 'Isométrico',
		descripcion =
			'Los dos versos miden lo mismo, y la norma no dice cuánto: el repertorio va del '
			|| 'tetrasílabo al alejandrino, y cuál de esas medidas se usa lo decide el pasaje. Es el '
			|| 'pareado que se lee suelto —el octosílabo de los estribillos, los refranes, las '
			|| 'máximas, los motes y las divisas, y el endecasílabo de las intervenciones breves y '
			|| 'tajantes— y también el que se sucede cuando una tirada de dísticos sostiene un pasaje '
			|| 'entero. Cuando los dos versos no miden igual, la mezcla es la italiana de siete y '
			|| 'once y el pareado es alirado.',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- ------------------------------------------------------------------ La pregunta
	-- Una medida uniforme se responde una vez. El `2-2` venía de cuando la pregunta era posicional.
	select grupo_eleccion_id into v_grupo from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug = 'medida_del_pareado';
	if v_grupo is null then
		raise exception 'El pareado isométrico no tiene su pregunta de medida.';
	end if;

	update public.grupos_eleccion_metrica
	set selecciones_min = 1,
		selecciones_max = 1,
		ayuda_editor =
			'Los dos versos miden lo mismo: señala su medida. Si uno es heptasílabo y el otro '
			|| 'endecasílabo, la arquitectura no es esta sino el pareado alirado.',
		updated_at = now()
	where grupo_eleccion_id = v_grupo;

	-- ------------------------------------------------------------------ La equivalencia legada
	-- `pareado_endecasilabo` declaraba su medida verso por verso, y ya no hay versos que numerar.
	select termino_id into v_termino from public.vocabularios
	where termino = 'pareado_endecasilabo' and categoria = 'estrofa_tipo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';
	if v_termino is null or v_endeca is null then
		raise exception 'Falta el término legado del pareado endecasílabo o el metro endecasílabo.';
	end if;

	delete from public.equivalencias_respuestas_legadas
	where termino_id = v_termino and arquitectura_id = v_arq and dimension = 'metro'
		and posicion_unidad is not null;

	insert into public.equivalencias_respuestas_legadas
		(termino_id, arquitectura_id, dimension, metro_id, posicion_unidad, nota)
	select v_termino, v_arq, 'metro', v_endeca, null,
		'El término declara la medida: los dos versos son endecasílabos.'
	where not exists (
		select 1 from public.equivalencias_respuestas_legadas
		where termino_id = v_termino and arquitectura_id = v_arq and dimension = 'metro'
			and metro_id = v_endeca and posicion_unidad is null
	);

	select count(*) into v_n from public.equivalencias_respuestas_legadas
	where termino_id = v_termino and dimension = 'metro';
	if v_n <> 1 then
		raise exception 'El pareado endecasílabo declara % equivalencias de medida, no una.', v_n;
	end if;
end
$cambio$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

-- ---------------------------------------------------------------------------------------------
-- Las guardas ejecutan lo que vigilan: las opciones se derivan de verdad y la propuesta se resuelve
-- de verdad. Comprobar la columna no habría visto ninguno de los dos fallos que esto arregla.
-- ---------------------------------------------------------------------------------------------
do $guarda$
declare
	v_arq uuid;
	v_alirado uuid;
	v_n integer;
	v_posiciones integer;
	v_min integer;
	v_max integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'cualquier_medida';
	select a.arquitectura_id into v_alirado
	from public.arquitecturas_forma a join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'alirado';

	-- 1. El isométrico ofrece medidas a secas, y su pregunta pide exactamente una.
	select count(*), count(o.posicion_unidad), min(g.selecciones_min), max(g.selecciones_max)
	into v_n, v_posiciones, v_min, v_max
	from public.grupos_eleccion_metrica g
	join public.opciones_eleccion_metrica o on o.grupo_eleccion_id = g.grupo_eleccion_id
	where g.arquitectura_id = v_arq and g.slug = 'medida_del_pareado';

	if v_n < 2 or v_posiciones <> 0 then
		raise exception
			'La medida del pareado isométrico ofrece % opciones, % de ellas por posición.',
			v_n, v_posiciones;
	end if;
	if v_min <> 1 or v_max <> 1 then
		raise exception 'La medida del pareado isométrico pide entre % y % respuestas.', v_min, v_max;
	end if;

	-- 2. El alirado no se ha movido: sigue preguntando cuál de los dos versos es el heptasílabo.
	select count(*), count(o.posicion_unidad), min(g.selecciones_min), max(g.selecciones_max)
	into v_n, v_posiciones, v_min, v_max
	from public.grupos_eleccion_metrica g
	join public.opciones_eleccion_metrica o on o.grupo_eleccion_id = g.grupo_eleccion_id
	where g.arquitectura_id = v_alirado and g.slug = 'medida_del_pareado';

	if v_n <> 4 or v_posiciones <> 4 or v_min <> 2 or v_max <> 2 then
		raise exception
			'El pareado alirado ha cambiado: % opciones, % por posición, entre % y % respuestas.',
			v_n, v_posiciones, v_min, v_max;
	end if;

	-- 3. Y ninguna pregunta activa del catálogo vuelve a pedir más respuestas de las que su
	--    repertorio puede distinguir. Es el defecto que esto arregla, dicho en general.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	where g.activo
		and g.selecciones_min > 1
		and exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		)
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id and o.posicion_unidad is not null
		);
	if v_n > 0 then
		raise exception '% preguntas piden varias respuestas sin distinguir posiciones.', v_n;
	end if;

	-- 4. La propuesta del término legado vuelve a traer su medida. Se ejecuta la vista entera.
	select count(*) into v_n
	from public.propuesta_elecciones_secuencia p
	join public.preguntas_metricas g on g.grupo_eleccion_id = p.grupo_eleccion_id
	where g.arquitectura_id = v_arq and g.dimension = 'metro';
	if v_n = 0 and exists (
		select 1 from public.secuencias_metricas s
		join public.vocabularios v on v.termino_id = s.estrofa_tipo_id
		where v.termino = 'pareado_endecasilabo'
	) then
		raise exception 'Hay pareados endecasílabos legados y la propuesta no les da medida.';
	end if;
end
$guarda$;

commit;
