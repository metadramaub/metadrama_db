-- El villancico sin cabeza no existe: se retira la arquitectura «Estribillo tras la primera copla»
--
-- Nació el 29 de julio de 2026 y nunca tuvo fuente. Lo que la sostenía en la ficha —«como modalidad
-- moderna general, una cuarteta octosilábica seguida por un estribillo en cuarteta hexasílaba»,
-- atribuido a Navarro Tomás— resultó falso y se retiró el 13 de septiembre (`20260913120000`): no lo
-- dice en ninguno de los seis §§ citados, y lo que sí dice lo contradice, porque en la *Gacela* de
-- Lorca el estribillo va delante y es heptasílabo.
--
-- Buscado después en los seis libros, **ninguno describe un villancico que empiece por la copla**.
-- Las cinco fuentes que describen la forma ponen el estribillo al principio, y el *Diccionario* usa
-- esa palabra: «un estribillo inicial —llamado cabeza, villancico, letra o tema—». Tampoco aparece
-- la cabeza pospuesta. Y tampoco estaba en el vocabulario legado, así que no se perdió al migrar:
-- no se declaró nunca. Fue una mala interpretación de las fuentes, y David la retira.
--
-- **Se retira con `activo = false`**, que es el interruptor real: la saca de la ficha, del catálogo
-- público y del demarcador de una vez, sin borrar lo que cuelga de ella. Borrarla del todo no se
-- puede mientras una anotación la use, porque las claves de `anotacion_elecciones` son
-- `on delete restrict`, y esa garantía se respeta aquí en vez de sortearla.
--
-- **La anotación que la usaba se borra.** Es el villancico de *Lo fingido y lo cierto (prueba)*,
-- obra de prueba con datos inventados. No se remapea a la otra arquitectura porque **las dos no son
-- intercambiables**: esta declara tres realizaciones de `estribillo`, una por ciclo, y «Estribillo
-- inicial» tiene una `cabeza` obligatoria, única y anterior a los ciclos. Cualquier traslado
-- inventaría estructura. La secuencia queda sin anotar, que es un estado que el editor y la ficha
-- ya saben tratar, y se vuelve a anotar desde la pantalla o regenerando las obras de prueba.
--
-- El guion que las genera se cambia en el mismo commit: `scripts/guion-obras-de-prueba.mjs` y
-- `xml-lope/guiones/AL0634.json` pasan a «estribillo_inicial».

begin;

do $$
declare
	v_arq uuid;
	v_anotaciones integer;
	v_realizaciones integer;
	v_elecciones integer;
	v_revision bigint;
	v_despues bigint;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'villancico' and a.slug = 'estribillo_tras_primera_copla';

	if v_arq is null then
		raise exception 'No está la arquitectura que esta migración retira.';
	end if;

	select revision into v_revision from public.catalogo_metrico_estado;

	-- Lo que se va a borrar, contado antes, para poder comprobarlo después.
	select count(*) into v_anotaciones
	from public.anotaciones_metricas where arquitectura_id = v_arq;

	select count(*) into v_realizaciones
	from public.anotacion_realizaciones r
	join public.anotaciones_metricas a using (anotacion_id)
	where a.arquitectura_id = v_arq;

	select count(*) into v_elecciones
	from public.anotacion_elecciones e
	join public.anotaciones_metricas a using (anotacion_id)
	where a.arquitectura_id = v_arq;

	if v_anotaciones <> 1 or v_elecciones <> 16 then
		raise exception 'Se esperaba 1 anotación con 16 respuestas y hay % con %. Esta migración se escribió para el villancico de *Lo fingido y lo cierto (prueba)*: si el dato es otro, hay que mirarlo antes.',
			v_anotaciones, v_elecciones;
	end if;

	-- Solo se borra lo de obras de prueba. Si alguna vez lo usara una obra real, se planta.
	if exists (
		select 1
		from public.anotaciones_metricas a
		join public.secuencias_metricas s using (secuencia_id)
		join public.obras o using (obra_id)
		where a.arquitectura_id = v_arq and o.titulo not ilike '%(prueba)%'
	) then
		raise exception 'Hay una anotación con esta arquitectura en una obra que no es de prueba. No se borra nada.';
	end if;

	delete from public.anotacion_elecciones e
	using public.anotaciones_metricas a
	where e.anotacion_id = a.anotacion_id and a.arquitectura_id = v_arq;

	delete from public.anotacion_realizaciones r
	using public.anotaciones_metricas a
	where r.anotacion_id = a.anotacion_id and a.arquitectura_id = v_arq;

	delete from public.anotaciones_metricas where arquitectura_id = v_arq;

	update public.arquitecturas_forma
	set activo = false, principal = false
	where arquitectura_id = v_arq;

	-- La definición de la forma la nombraba como una de sus configuraciones.
	update public.formas_metricas
	set definicion = replace(
		definicion,
		', así como configuraciones en las que una copla precede a la primera aparición del estribillo',
		''
	)
	where slug = 'villancico'
		and definicion like '%una copla precede a la primera aparición del estribillo%';

	-- ── Comprobaciones, ejecutando lo que se toca ──────────────────────────────
	if exists (select 1 from public.arquitecturas_forma where arquitectura_id = v_arq and activo) then
		raise exception 'La arquitectura sigue activa.';
	end if;

	if exists (select 1 from public.anotaciones_metricas where arquitectura_id = v_arq) then
		raise exception 'Queda alguna anotación colgando de la arquitectura retirada.';
	end if;

	if (select count(*) from public.arquitecturas_forma a
		join public.formas_metricas f using (forma_id)
		where f.slug = 'villancico' and a.activo) <> 1 then
		raise exception 'El villancico debe quedarse con una sola arquitectura activa.';
	end if;

	if exists (
		select 1 from public.formas_metricas
		where slug = 'villancico' and definicion like '%precede a la primera aparición del estribillo%'
	) then
		raise exception 'La definición del villancico sigue nombrando la configuración retirada.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado;
	if v_despues <= v_revision then
		raise exception 'La revisión del catálogo no subió: % -> %', v_revision, v_despues;
	end if;

	raise notice 'Retirada la arquitectura y borradas % realizaciones y % respuestas de la obra de prueba.',
		v_realizaciones, v_elecciones;
end $$;

commit;
