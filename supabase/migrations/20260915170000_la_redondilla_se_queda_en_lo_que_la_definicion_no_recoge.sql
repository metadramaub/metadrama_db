-- La redondilla se queda en lo que su definición no recoge, y ahí se para
--
-- La migración anterior, la 20260915160000, cambió el texto de esta afirmación aplicando una
-- redacción que David no había visto. Había decidido el 11 de septiembre **que** la afirmación
-- tenía que cambiar, no **cómo**, y esas son dos aprobaciones distintas. Esta corrige la redacción
-- a la que él quiere.
--
-- Lo que sobraba es la coda: «el capítulo no dice si la tratan en otro lugar del libro». Es cierta,
-- pero es una frase sobre lo que no sabemos, y una afirmación de «Lo que dicen las fuentes» está
-- para decir lo que la fuente dice. Que la definición no recoja la disposición cruzada es el hecho;
-- todo lo demás sobra.
--
--   antes: «… Su definición no recoge la disposición cruzada; el capítulo no dice si la tratan en
--           otro lugar del libro.»
--   ahora: «… Su definición no recoge la disposición cruzada.»
--
-- Las dos migraciones se conservan, porque la historia tiene que decir que la primera se aplicó.

begin;

do $$
declare
	v_redondilla constant uuid := '97e53fc1-9a3c-4cd6-90a5-1d7d63b7edbb';
	v_antiguo constant text :=
		'La definen como cuatro octosílabos `ABBA`, y anotan que «se encuentra ocasionalmente con '
		'versos de seis o siete sílabas». Su definición no recoge la disposición cruzada; el capítulo '
		'no dice si la tratan en otro lugar del libro.';
	v_nuevo constant text :=
		'La definen como cuatro octosílabos `ABBA`, y anotan que «se encuentra ocasionalmente con '
		'versos de seis o siete sílabas». Su definición no recoge la disposición cruzada.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_redondilla and resumen = v_antiguo;
	if v_cuantas <> 1 then
		raise exception 'La afirmación de la redondilla no tiene el texto que dejó la migración anterior.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_nuevo
	where afirmacion_id = v_redondilla;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_redondilla
		and resumen = v_nuevo
		and localizador = 'Cap. V, «Redondilla», p. 38';
	if v_cuantas <> 1 then
		raise exception 'La redondilla no ha quedado con el texto aprobado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
