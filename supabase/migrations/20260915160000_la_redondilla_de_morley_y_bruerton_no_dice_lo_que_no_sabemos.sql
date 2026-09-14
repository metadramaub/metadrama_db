-- La redondilla de Morley y Bruerton no dice lo que no podemos saber
--
-- La afirmación cerraba con «No incluyen la cruzada, **que tratan aparte**». Esa segunda mitad
-- afirma algo positivo —que existe un tratamiento separado de la redondilla cruzada en otro lugar
-- del libro— y **no lo podemos sostener**, porque de Morley y Bruerton no tenemos el libro: tenemos
-- una copia a mano del capítulo V, fiel y confirmada, que son cuatro páginas y diecinueve
-- epígrafes. Lo que sí se puede decir es lo que ese capítulo hace y no hace.
--
-- El epígrafe entero, en la p. 38, es este:
--
--   «Cuatro octosílabos: ABBA. Se encuentra ocasionalmente con versos de seis o siete sílabas.»
--
-- No hay ninguna otra línea bajo «Redondilla», y «cruzada» y «cuarteta» no aparecen en ninguna
-- parte del documento. Así que la definición no recoge la disposición cruzada —eso es un hecho— y
-- si la tratan en otro sitio del volumen es algo que este material no permite afirmar ni negar.
--
-- La pasada A no la dio por defectuosa sino por **no confirmada**, que es el único veredicto de la
-- taxonomía que dice «no tengo con qué». Es el caso que justifica que ese veredicto exista.
--
-- El texto nuevo lo fijó David el 11 de septiembre de 2026 y quedó redactado en `propuestas.json`
-- esperando su migración. Se aprovecha para completar el localizador con la página, que la copia
-- lleva marcada desde ese mismo día.

begin;

do $$
declare
	v_redondilla constant uuid := '97e53fc1-9a3c-4cd6-90a5-1d7d63b7edbb';
	v_antiguo constant text :=
		'Reservan el nombre para la disposición abrazada: cuatro octosílabos ABBA, ocasionalmente de '
		'seis o siete sílabas. No incluyen la cruzada, que tratan aparte.';
	v_nuevo constant text :=
		'La definen como cuatro octosílabos `ABBA`, y anotan que «se encuentra ocasionalmente con '
		'versos de seis o siete sílabas». Su definición no recoge la disposición cruzada; el capítulo '
		'no dice si la tratan en otro lugar del libro.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_redondilla
		and resumen = v_antiguo
		and localizador = 'Cap. V, «Redondilla»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación de la redondilla no está como espero; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_nuevo,
		localizador = 'Cap. V, «Redondilla», p. 38'
	where afirmacion_id = v_redondilla;

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Que ya no afirma lo que no se puede saber, que sí dice lo comprobable, y que no se ha perdido
	-- la definición, que era exacta.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_redondilla
		and resumen not like '%que tratan aparte%'
		and resumen like '%no dice si la tratan en otro lugar del libro%'
		and resumen like '%cuatro octosílabos%'
		and resumen like '%seis o siete sílabas%'
		and localizador = 'Cap. V, «Redondilla», p. 38';
	if v_cuantas <> 1 then
		raise exception 'La redondilla no ha quedado como se pretendía.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
