-- La silva consonante deja de explicar el catálogo en boca del Diccionario
--
-- La afirmación cerraba así: «De ahí que esta arquitectura, sola entre las cuatro, declare el
-- pareado como parte de su esquema de rima». Eso no lo dice el *Diccionario*: **habla del catálogo**,
-- no de la fuente. Es la misma familia que el «donde Quilis da CDC DCD» que se retiró del soneto de
-- Jauralde, con la diferencia de que aquí lo colado no es otra fuente sino nuestra propia manera de
-- modelar.
--
-- Y no hay nada que mover a otro sitio, porque **el sitio ya lo dice**. La descripción de la
-- arquitectura «Consonante regular» de la silva reza: «Alterna heptasílabo y endecasílabo en
-- pareados que se suceden sin excepción, de modo que el pareado funciona aquí como unidad. Es la
-- única silva que se ajusta a un esquema». La frase retirada era un duplicado de esa definición
-- puesto en la voz del libro.
--
-- Ningún verificador la marcó: apareció al corregir la cita de esta misma ficha, y la decidió David
-- el 17 de septiembre de 2026 —«esto es asunto de definición, no debe estar en una fuente».

begin;

do $$
declare
	v_silva constant uuid := '871a22ab-99df-411f-b76f-8b97272a436f';
	v_nuevo constant text :=
		'Sostiene de la silva de consonantes que «se trata, en realidad, de una forma estructurada en '
		'pareados, que constituyen su unidad estrófica».';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_silva and resumen like '%sola entre las cuatro%';
	if v_cuantas <> 1 then
		raise exception 'La afirmación de la silva consonante no está como espero; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_nuevo
	where afirmacion_id = v_silva;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_silva and resumen = v_nuevo;
	if v_cuantas <> 1 then
		raise exception 'La silva consonante no ha quedado con el texto aprobado.';
	end if;

	-- Y que lo retirado sigue dicho donde le toca, en la descripción de la arquitectura.
	select count(*) into v_cuantas
	from public.arquitecturas_forma ar
	join public.formas_metricas fo using (forma_id)
	where fo.nombre = 'Silva'
		and ar.nombre = 'Consonante regular'
		and ar.descripcion like '%el pareado funciona aquí como unidad%';
	if v_cuantas <> 1 then
		raise exception 'La descripción de la arquitectura ya no dice que el pareado es su unidad.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
