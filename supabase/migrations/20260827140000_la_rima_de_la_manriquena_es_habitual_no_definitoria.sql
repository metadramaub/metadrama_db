-- La rima de la manriqueña es habitual, no definitoria
--
-- El editor preguntaba el esquema de rima de la copla manriqueña teniendo **una sola opción**, y esa
-- opción estaba marcada como `definitoria`: la norma la fijaba, así que preguntarla no tenía sentido
-- —si rima de otro modo, no es una manriqueña—.
--
-- Contado sobre el catálogo activo, era la **única** arquitectura en esa situación: de las seis que
-- preguntan la rima con una sola opción, en las otras cinco —décima-lira, octava real, los dos
-- sextetos y la sextilla— la opción es `habitual` o `admitida`, y ahí preguntar está bien.
--
-- Pero dos cosas decían que la marca era la equivocada, y el IP ha resuelto por ahí:
--
--   1. **La propia definición de la forma dice que hay otras.** «La tradición documenta antes otras:
--      sextillas de dos rimas repetidas en las dos mitades, o con el orden invertido en la segunda.»
--   2. **La sextilla marca lo mismo como habitual.** `abcabc` es `habitual` en la sextilla de pie
--      quebrado, y la manriqueña —que es dos sextillas seguidas— marcaba `abcabc|defdef` como
--      definitoria. La misma disposición con dos estatutos.
--
-- Así que lo que cambia es el dato, no la interfaz: `abcabc|defdef` pasa a **habitual**, la pregunta
-- queda justificada y el hueco se cierra sin tocar una línea de código.
--
-- **No se toca el otro esquema de la arquitectura**, «Distribución consonante variable», que sigue
-- siendo definitorio: la norma de la manriqueña es que las dos sextillas riman en consonante con sus
-- rimas independientes, y `abcabc|defdef` es la realización corriente de esa norma, no la norma.

begin;

do $$
declare
	v_esquema uuid;
	v_modalidad text;
begin
	select er.esquema_rima_id, er.modalidad into v_esquema, v_modalidad
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla manriqueña'
		and a.nombre = 'De pie quebrado'
		and er.notacion = 'abcabc|defdef';

	if v_esquema is null then
		raise exception 'No está el esquema abcabc|defdef de la copla manriqueña: revisa el catálogo antes de seguir.';
	end if;

	-- Idempotente: si ya se aplicó, no hay nada que hacer y tampoco nada que romper.
	if v_modalidad = 'habitual' then
		raise notice 'La rima de la manriqueña ya era habitual.';
		return;
	end if;

	if v_modalidad <> 'definitoria' then
		raise exception 'La rima de la manriqueña no era definitoria sino %, que no es lo que se acordó cambiar.', v_modalidad;
	end if;

	update public.esquemas_rima
	set modalidad = 'habitual'
	where esquema_rima_id = v_esquema;
end $$;

do $$
declare
	v_modalidad text;
	v_variable text;
	v_opciones integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se lee lo que ha quedado escrito**, no lo que se pretendía escribir.
	select er.modalidad into v_modalidad
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla manriqueña' and er.notacion = 'abcabc|defdef';

	if v_modalidad is distinct from 'habitual' then
		raise exception 'La rima de la manriqueña sigue en %.', v_modalidad;
	end if;

	-- El otro esquema de la arquitectura no se ha movido.
	select er.modalidad into v_variable
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla manriqueña' and er.nombre = 'Distribución consonante variable';

	if v_variable is distinct from 'definitoria' then
		raise exception 'La distribución variable de la manriqueña ha cambiado a %, y no debía tocarse.', v_variable;
	end if;

	-- Y la pregunta sigue en pie con su opción: lo que se arregla es que ahora está justificada.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Copla manriqueña' and g.dimension = 'rima' and g.activo;

	if v_opciones < 1 then
		raise exception 'La manriqueña se ha quedado sin opciones de rima.';
	end if;
end $$;

commit;
