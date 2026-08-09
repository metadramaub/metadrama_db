-- Tres arquitecturas que existían sin declarar de qué término legado vienen.
--
-- `Silva · Libre`, `Redondilla · Heptasilábica` y `Redondilla · Hexasilábica` corresponden
-- exactamente a los términos legados `silva_libre`, `redondilla_heptasilaba` y
-- `redondilla_hexasilaba`, pero tenían `origen_termino_id` a nulo. El término y la arquitectura
-- existían los dos; lo que faltaba era el puente entre ellos.
--
-- La consecuencia es que ninguna cadena de equivalencia los une: si una obra usara uno de esos
-- tres términos, `propuesta_metrica_secuencia` lo resolvería por ascendencia a la forma —Silva o
-- Redondilla— **sin proponer arquitectura**, aunque exista una que le corresponde con exactitud.
-- Estaba registrado en `equivalencias-pendientes.md` como «sin origen declarado» desde el 4 de
-- agosto; ahora se cierra.
--
-- Que la correspondencia es exacta se comprueba en el vocabulario heredado:
--
--   silva_libre             → «serie métrica abierta que combina heptasílabos y endecasílabos
--                             con rima consonante distribuida al arbitrio del poeta, sin un
--                             orden fijo… No contiene pareados» = `Silva · Libre`, que declara
--                             el grado `ninguna` de organización en pareados.
--   redondilla_heptasilaba  → la redondilla en versos de siete sílabas.
--   redondilla_hexasilaba   → la redondilla en versos de seis sílabas.
--
-- **Hoy ninguna obra usa los tres términos**, así que la vista no cambia de tamaño ni se mueve
-- ninguna anotación: la migración prepara el destino para cuando aparezcan. Las dos redondillas
-- sí tienen 63 usos de familia cada una —es decir, secuencias que usan un término hermano—, y
-- esos siguen resolviendo como hasta ahora.
--
-- `origen_termino_id` es único en `arquitecturas_forma`, de modo que la propia restricción
-- impide que dos arquitecturas reclamen el mismo término.

begin;

do $$
declare
	v_silva_libre uuid;
	v_redon_hepta uuid;
	v_redon_hexa uuid;
	v_t_silva uuid;
	v_t_hepta uuid;
	v_t_hexa uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_silva_libre
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'silva' and a.slug = 'libre';

	select a.arquitectura_id into v_redon_hepta
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'redondilla' and a.slug = 'heptasilabica';

	select a.arquitectura_id into v_redon_hexa
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'redondilla' and a.slug = 'hexasilabica';

	select termino_id into v_t_silva from public.vocabularios
	where termino = 'silva_libre';
	select termino_id into v_t_hepta from public.vocabularios
	where termino = 'redondilla_heptasilaba';
	select termino_id into v_t_hexa from public.vocabularios
	where termino = 'redondilla_hexasilaba';

	if num_nonnulls(
		v_silva_libre, v_redon_hepta, v_redon_hexa, v_t_silva, v_t_hepta, v_t_hexa
	) <> 6 then
		raise exception 'Falta una de las tres arquitecturas o uno de los tres términos legados';
	end if;

	-- Si alguna de las tres declarase ya un origen distinto, hay que detenerse y mirarlo.
	select count(*) into v_n from public.arquitecturas_forma
	where arquitectura_id in (v_silva_libre, v_redon_hepta, v_redon_hexa)
		and origen_termino_id is not null;
	if v_n <> 0 then
		raise exception 'Alguna de las tres arquitecturas ya declaraba origen: %', v_n;
	end if;

	update public.arquitecturas_forma
	set origen_termino_id = v_t_silva, updated_at = now()
	where arquitectura_id = v_silva_libre;

	update public.arquitecturas_forma
	set origen_termino_id = v_t_hepta, updated_at = now()
	where arquitectura_id = v_redon_hepta;

	update public.arquitecturas_forma
	set origen_termino_id = v_t_hexa, updated_at = now()
	where arquitectura_id = v_redon_hexa;

	select count(*) into v_n from public.arquitecturas_forma
	where arquitectura_id in (v_silva_libre, v_redon_hepta, v_redon_hexa)
		and origen_termino_id is not null;
	if v_n <> 3 then
		raise exception 'Las tres arquitecturas deben declarar su origen, y declaran %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
