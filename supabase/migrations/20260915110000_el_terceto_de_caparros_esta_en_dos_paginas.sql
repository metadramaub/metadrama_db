-- El terceto de Caparrós está en dos páginas, con una de ejemplos en medio
--
-- La afirmación funde dos frases del libro y declaraba solo la página de la primera:
--
--   p. 185 (hoja 182, pie «185»), § 10.2.2 «Estrofas de tres versos»
--     «El terceto se compone de tres versos de arte mayor, normalmente endecasílabos, con rima
--      consonante. La forma más usada de disposición de la rima es la del terceto encadenado…»
--   p. 187 (hoja 184, pie «187»)
--     «El terceto en versos de arte menor se llama tercetillo, tercerilla o tercerillo.»
--
-- Entre las dos hay una página entera de ejemplos de tercetos en arte mayor —Espronceda, Díaz
-- Mirón, Lope—, así que no es un salto de página dentro de un párrafo: son dos pasajes. La pasada
-- A y la C lo sitúan igual, y se ha comprobado abriendo las dos hojas y leyendo el número impreso
-- al pie.
--
-- Otra afirmación del catálogo, la `9e0a5051`, cita esa misma frase del tercetillo por apartado y
-- no por página, así que el libro no se contradice: era esta la que se quedaba corta.
--
-- No se toca una palabra de prosa.

begin;

do $$
declare
	v_terceto constant uuid := '43424e08-961c-4315-ba9f-12d1f93afb83';
	v_resumen_antes text;
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_terceto and localizador = 'p. 185';
	if v_cuantas <> 1 then
		raise exception 'La afirmación del terceto no cita hoy «p. 185»; no la toco.';
	end if;

	select resumen into v_resumen_antes
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_terceto;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set localizador = 'pp. 185 y 187'
	where afirmacion_id = v_terceto;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_terceto
		and localizador = 'pp. 185 y 187'
		and resumen = v_resumen_antes;
	if v_cuantas <> 1 then
		raise exception 'El terceto no ha quedado como se pretendía, o le ha cambiado el texto.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
