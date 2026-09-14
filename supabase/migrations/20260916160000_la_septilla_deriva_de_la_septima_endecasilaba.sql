-- La septilla deriva de la séptima endecasílaba, y lo dice una sola fuente
--
-- El catálogo ya relacionaba septeto y septilla por contraste: «son la misma estrofa de siete
-- versos en las dos artes». Lo que faltaba es que esa pareja tiene además un orden, y quién lo
-- dice.
--
-- Navarro Tomás, § 460, «Séptima», p. 473: «Una estrofa endecasílaba de antigua tradición
-- provenzal, compuesta de cuarteto y terceto, **modelo de la copla mixta octosílaba de la poesía
-- castellana medieval**». La octosílaba se hizo sobre la endecasílaba, no al revés. Es la misma
-- dirección que el catálogo ya registra en otras cinco derivaciones: el origen va en el destino y
-- la forma derivada en el origen.
--
-- **Lo sostiene una sola de las seis fuentes**, y la nota lo dice con su nombre. Las otras cinco
-- tratan las dos estrofas sin ordenarlas: Caparrós reúne los tres nombres «bajo una misma
-- extensión», el Diccionario da «séptima» como nombre común de las de arte mayor, menor o mezclado,
-- y Jauralde fija el reparto 4+3 para las dos sin decir cuál viene de cuál. Que una relación
-- descanse en un solo testimonio no la invalida, pero tiene que verse al leerla.
--
-- La relación anterior no se toca: siguen siendo las dos cosas a la vez, formas que contrastan por
-- el arte del verso y formas con un orden histórico entre ellas.

begin;

do $$
declare
	v_septeto constant uuid := '11beb378-43a0-4c5b-bf00-798deaaa1baf';
	v_septilla constant uuid := '7a0faa54-7a15-4945-9a3b-b228eef14664';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que las dos formas son las que se cree y que el contraste sigue ahí.
	select count(*) into v_cuantas
	from public.formas_metricas
	where (forma_id = v_septeto and nombre = 'Septeto')
		or (forma_id = v_septilla and nombre = 'Septilla');
	if v_cuantas <> 2 then
		raise exception 'No encuentro el septeto y la septilla donde se espera.';
	end if;

	select count(*) into v_cuantas
	from public.forma_relaciones
	where forma_origen_id = v_septeto
		and forma_destino_id = v_septilla
		and tipo_relacion = 'contrasta_con';
	if v_cuantas <> 1 then
		raise exception 'Esperaba el contraste ya registrado entre septeto y septilla.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values (
		v_septilla,
		v_septeto,
		'derivada_de',
		'La octosílaba se hizo sobre la endecasílaba. Navarro Tomás describe la séptima como «una '
		'estrofa endecasílaba de antigua tradición provenzal, compuesta de cuarteto y terceto» y la '
		'presenta como «modelo de la copla mixta octosílaba de la poesía castellana medieval» (§ 460). '
		'Es el único de los seis manuales que ordena la pareja: los demás tratan las dos estrofas '
		'como variantes de una misma extensión, separadas por el arte del verso, sin decir cuál viene '
		'de cuál.'
	)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do nothing;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_cuantas
	from public.forma_relaciones
	where forma_origen_id = v_septilla
		and forma_destino_id = v_septeto
		and tipo_relacion = 'derivada_de'
		and nota like '%modelo de la copla mixta octosílaba%'
		and nota like '%único de los seis manuales%';
	if v_cuantas <> 1 then
		raise exception 'La derivación no ha quedado registrada.';
	end if;

	-- Y que no se ha perdido el contraste, que es lo que ya había.
	select count(*) into v_cuantas
	from public.forma_relaciones
	where forma_origen_id = v_septeto
		and forma_destino_id = v_septilla
		and tipo_relacion = 'contrasta_con';
	if v_cuantas <> 1 then
		raise exception 'Se ha perdido el contraste entre septeto y septilla.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
