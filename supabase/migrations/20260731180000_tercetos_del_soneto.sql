begin;

-- Los tercetos del soneto son dos secciones, y cada una es un terceto.
--
-- La migración anterior los había fundido en una sola sección de seis versos para que el
-- esquema —`CDCDCD`, `CDECDE`, `CDEDCE`, `CDCEDE`— cupiera en ella. Era resolver un
-- problema de la pregunta cambiando la estructura, y la estructura no es negociable: un
-- soneto tiene dos tercetos, no un bloque de seis versos.
--
-- Se restituyen las dos secciones y se vinculan con la arquitectura del terceto, como hacen
-- las secciones de la novena con la redondilla y la quintilla: la sección no copia lo que
-- el componente ya declara, lo referencia. Un terceto del soneto es exactamente eso, tres
-- endecasílabos consonantes.
--
-- El esquema sigue siendo de seis posiciones porque describe cómo se entrelazan las rimas
-- de un terceto con las del otro: `CDCDCD` es `CDC` y `DCD`, y separarlo en dos mitades
-- perdería justo lo que distingue a los cuatro esquemas entre sí. Por eso la pregunta no se
-- ancla en ninguna de las dos secciones: se hace una vez por unidad y el editor la presenta
-- uniendo los dos tercetos. Que la pregunta abarque dos secciones no obliga a que las
-- secciones dejen de ser dos.

-- ---------------------------------------------------------------------------
-- 1 · Dos tercetos, vinculados con la forma que realizan
-- ---------------------------------------------------------------------------

update public.estructuras_secciones seccion
set tipo_seccion = 'terceto',
	nombre = 'Tercetos',
	versos_min = 3,
	versos_max = 3,
	repeticiones_min = 2,
	repeticiones_max = 2,
	arquitectura_referenciada_id = (
		select componente.arquitectura_id
		from public.arquitecturas_forma componente
		join public.formas_metricas forma_componente
			on forma_componente.forma_id = componente.forma_id
		where forma_componente.slug = 'terceto'
			and componente.slug = 'endecasilabico_consonante'
	),
	nota = 'Cada terceto realiza la arquitectura endecasílaba consonante del terceto. El esquema de rima no se declara aquí porque entrelaza los dos: se pregunta una vez por unidad.'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where seccion.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'soneto'
	and seccion.tipo_seccion = 'tercetos';

-- ---------------------------------------------------------------------------
-- 2 · La pregunta abarca los dos tercetos, así que no se ancla en ninguno
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set seccion_id = null,
	ayuda_editor = coalesce(
		grupo.ayuda_editor,
		'El esquema abarca los dos tercetos: seis posiciones que declaran cómo se reparten las rimas entre ambos.'
	)
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where grupo.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'soneto'
	and grupo.slug = 'esquema_tercetos';

do $$
declare
	v_secciones integer;
	v_referencia integer;
	v_esquemas integer;
begin
	select count(*) into v_secciones
	from public.estructuras_secciones seccion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = seccion.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto';
	if v_secciones <> 2 then
		raise exception 'El soneto debe tener dos secciones y tiene %', v_secciones;
	end if;

	select count(*) into v_referencia
	from public.estructuras_secciones seccion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = seccion.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto'
		and seccion.tipo_seccion = 'terceto'
		and seccion.arquitectura_referenciada_id is not null
		and seccion.versos_min = 3
		and seccion.repeticiones_min = 2
		and seccion.repeticiones_max = 2;
	if v_referencia <> 1 then
		raise exception 'La sección de tercetos no quedó vinculada con la arquitectura del terceto';
	end if;

	-- La extensión sigue cuadrando: dos cuartetos de cuatro y dos tercetos de tres.
	select count(*) into v_esquemas
	from public.esquemas_rima rima
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto'
		and char_length(rima.notacion) = 6;
	if v_esquemas <> 4 then
		raise exception 'Se esperaban 4 esquemas de tercetos de seis posiciones y hay %', v_esquemas;
	end if;
end;
$$;

commit;
