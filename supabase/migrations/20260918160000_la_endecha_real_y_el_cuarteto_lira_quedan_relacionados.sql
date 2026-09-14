-- La endecha real y el cuarteto-lira quedan relacionados
--
-- Salió al escribir la afirmación de Jauralde sobre el cuarteto-lira. En su apartado «Cuartetos
-- mixtos» las trata juntas y las separa por **qué medida domina**: «cuando sobre la misma estructura
-- de cuatro versos impares lo que domina es el heptasílabo sobre el endecasílabo se prefiere hablar
-- de cuartetos de endecha».
--
-- El catálogo ya recogía «Cuarteto de endecha» como denominación de la endecha real —el
-- *Diccionario* se lo atribuye a Navarro Tomás— pero las dos formas no se declaraban relacionadas.
-- Ahora sí, sin fundirlas: la endecha real fija la disposición y se repite como serie; el
-- cuarteto-lira deja la proporción variable y es una estrofa suelta.
--
-- **Queda anotado para el IP** que hoy nada en la base distingue una realización del cuarteto-lira
-- con siete dominante de otra con once dominante, porque su arquitectura declara «proporción
-- variable» sin posiciones: el criterio de Jauralde no se puede aplicar al anotar aunque se acepte.
--
-- Nota aprobada por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_endecha constant uuid := (select forma_id from public.formas_metricas where nombre = 'Endecha real');
	v_cuarteto constant uuid := (select forma_id from public.formas_metricas where nombre = 'Cuarteto-lira');
	v_nota constant text :=
			'Jauralde Pou trata las dos en el mismo apartado y las separa por qué medida domina: «cuando '
			'sobre la misma estructura de cuatro versos impares lo que domina es el heptasílabo sobre el '
			'endecasílabo se prefiere hablar de cuartetos de endecha». El catálogo las mantiene aparte '
			'porque la endecha real fija la disposición —tres heptasílabos y un endecasílabo final, '
			'repetida a lo largo de la serie— y el cuarteto-lira deja la proporción variable y no se repite '
			'como serie. «Cuarteto de endecha» está recogido como denominación de la endecha real, y el '
			'*Diccionario* se lo atribuye a Navarro Tomás.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_endecha is null or v_cuarteto is null then
		raise exception 'No encuentro la endecha real o el cuarteto-lira.';
	end if;

	-- Que no estaban relacionadas ya, en ninguna dirección.
	select count(*) into v_cuantas
	from public.forma_relaciones
	where (forma_origen_id = v_endecha and forma_destino_id = v_cuarteto)
		or (forma_origen_id = v_cuarteto and forma_destino_id = v_endecha);
	if v_cuantas <> 0 then
		raise exception 'Ya hay % relaciones entre las dos formas.', v_cuantas;
	end if;

	-- Y que «Cuarteto de endecha» sigue siendo denominación de la endecha real, que es lo que la nota
	-- da por sabido.
	select count(*) into v_cuantas
	from public.denominaciones_metricas
	where forma_id = v_endecha and nombre = 'Cuarteto de endecha';
	if v_cuantas <> 1 then
		raise exception 'No encuentro «Cuarteto de endecha» como denominación de la endecha real.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	values (v_endecha, v_cuarteto, 'relacionada_con', v_nota)
	on conflict (forma_origen_id, forma_destino_id, tipo_relacion) do nothing;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_cuantas
	from public.forma_relaciones
	where forma_origen_id = v_endecha and forma_destino_id = v_cuarteto
		and tipo_relacion = 'relacionada_con' and nota = v_nota;
	if v_cuantas <> 1 then
		raise exception 'La relación no ha quedado con la nota aprobada.';
	end if;

	-- Que no se ha perdido lo que la endecha real ya tenía: deriva del romance y se relaciona con la
	-- seguidilla.
	select count(*) into v_cuantas
	from public.forma_relaciones
	where (forma_origen_id = v_endecha or forma_destino_id = v_endecha);
	if v_cuantas <> 3 then
		raise exception 'La endecha real tiene % relaciones y esperaba tres.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
