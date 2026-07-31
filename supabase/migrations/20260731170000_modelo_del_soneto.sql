begin;

-- El esquema de los tercetos del soneto describe los tercetos, no los catorce versos.
--
-- La pregunta que el editor responde es «¿qué esquema presentan los tercetos?», y sus
-- cuatro respuestas se llaman `CDCDCD`, `CDECDE`, `CDEDCE` y `CDCEDE`: seis posiciones.
-- Pero cada una apuntaba a un esquema de catorce, `ABBAABBACDECDE`, que repite en cada
-- opción una parte —los cuartetos— que no se pregunta y que es siempre la misma. Es el
-- defecto D5 del informe de conformidad: la opción distingue menos posiciones que el
-- esquema al que apunta, así que el esquema no modela el nivel que la pregunta distingue.
--
-- Con la unidad envolvente el soneto materializa por fin sus secciones, y el reparto queda
-- como lo dibuja la ontología: los cuartetos son una sección de cuatro versos que se
-- realiza dos veces con el mismo `ABBA`, y los tercetos son **una sola sección de seis**.
--
-- Los tercetos no se dividen en dos secciones de tres porque su esquema no es divisible:
-- `CDECDE` sí se leería como dos tercetos `CDE`, pero `CDCDCD` es `CDC` y `DCD`, y lo que
-- distingue a los cuatro esquemas entre sí es precisamente cómo se entrelazan las rimas de
-- un terceto con las del otro. Un esquema de seis posiciones no cabe en una sección de tres
-- versos, y partirlo perdería la información que la pregunta busca.

-- ---------------------------------------------------------------------------
-- 1 · Los cuartetos declaran su propio esquema
-- ---------------------------------------------------------------------------

with soneto as (
	select arquitectura.arquitectura_id
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto'
),
nuevo as (
	insert into public.esquemas_rima (
		arquitectura_id, nombre, notacion, ambito, comportamiento, fijeza, estado_revision
	)
	select
		soneto.arquitectura_id,
		'Cuartetos abrazados',
		'ABBA',
		'seccion',
		'secuencia_fija',
		'fijo',
		'revisada'
	from soneto
	returning esquema_rima_id, arquitectura_id
)
update public.estructuras_secciones seccion
set esquema_rima_id = nuevo.esquema_rima_id
from nuevo
where seccion.arquitectura_id = nuevo.arquitectura_id
	and seccion.tipo_seccion = 'cuarteto';

-- ---------------------------------------------------------------------------
-- 2 · Los tercetos son una sola sección de seis versos
-- ---------------------------------------------------------------------------

update public.estructuras_secciones seccion
set tipo_seccion = 'tercetos',
	nombre = 'Tercetos',
	versos_min = 6,
	versos_max = 6,
	repeticiones_min = 1,
	repeticiones_max = 1,
	nota = 'Los dos tercetos forman una sola sección porque su esquema los entrelaza: lo que distingue a CDCDCD de CDECDE es cómo se reparten las rimas entre ambos.'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where seccion.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'soneto'
	and seccion.tipo_seccion = 'terceto';

-- ---------------------------------------------------------------------------
-- 3 · Los cuatro esquemas dejan de describir el soneto entero
--
-- Se transforman en el sitio, sin crear filas nuevas: así conservan su identidad y siguen
-- valiendo las opciones que los eligen y las trazas de la migración del vocabulario que
-- apuntan a ellos. El disparador de sincronización rehace sus posiciones desde la notación
-- nueva, que pasa de catorce a seis.
-- ---------------------------------------------------------------------------

update public.esquemas_rima rima
set notacion = substring(rima.notacion from 9),
	ambito = 'seccion'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where rima.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'soneto'
	and rima.ambito = 'composicion'
	and rima.notacion like 'ABBAABBA______';

-- ---------------------------------------------------------------------------
-- 4 · La pregunta se ancla en los tercetos
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set seccion_id = seccion.seccion_id
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
join public.estructuras_secciones seccion
	on seccion.arquitectura_id = arquitectura.arquitectura_id
	and seccion.tipo_seccion = 'tercetos'
where grupo.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'soneto'
	and grupo.slug = 'esquema_tercetos';

do $$
declare
	v_esquemas integer;
	v_posiciones integer;
	v_seccion uuid;
begin
	select count(*) into v_esquemas
	from public.esquemas_rima rima
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto'
		and rima.ambito = 'seccion'
		and char_length(rima.notacion) = 6;
	if v_esquemas <> 4 then
		raise exception 'Se esperaban 4 esquemas de tercetos de seis posiciones y hay %', v_esquemas;
	end if;

	-- El disparador tuvo que rehacer las posiciones: seis por esquema, más cuatro del
	-- esquema de los cuartetos.
	select count(*) into v_posiciones
	from public.esquema_rima_posiciones posicion
	join public.esquemas_rima rima
		on rima.esquema_rima_id = posicion.esquema_rima_id
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto';
	if v_posiciones <> 28 then
		raise exception 'Se esperaban 28 posiciones de rima en el soneto y hay %', v_posiciones;
	end if;

	select grupo.seccion_id into v_seccion
	from public.grupos_eleccion_metrica grupo
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto'
		and grupo.slug = 'esquema_tercetos';
	if v_seccion is null then
		raise exception 'La pregunta por el esquema de tercetos no quedó anclada en su sección';
	end if;
end;
$$;

commit;
