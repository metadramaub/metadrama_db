-- La quintilla no prescribe lo que describe
--
-- Rectifica `20260819090000`, del mismo día, en el único punto que importaba: **la prosa había
-- colado lenguaje prescriptivo donde el modelo dice expresamente que no lo hay**.
--
-- La decisión «Modalidad: frecuencia reconocida, no prescripción» ya está escrita en el modelo
-- aplicado, con su escala y su consecuencia: «lo excepcional puede llegar a ser admitido o
-- habitual si su empleo se extiende, y toda realización reconocida fue nueva en algún momento de
-- su historia». Es decir que **una disposición no infringe nada por ser rara**: `excepcional`
-- mide cuánto aparece, no si obedece.
--
-- La descripción de la arquitectura decía en cambio que tres disposiciones «se apartan de la
-- regla», y la del esquema abierto que la tradición las «documenta incumpliéndola». Las dos
-- convierten una descripción en una ley y, de paso, dejan a `abbba` en una infracción permanente
-- que ningún hallazgo futuro podría levantar. Lo que hay es más simple: las cinco clásicas son
-- las que la tradición describe, y hay tres realizaciones documentadas que esa descripción no
-- contempla.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_viejo constant text :=
		'Es de las estrofas más usadas del teatro del Siglo de Oro, sobre todo en los pasajes narrativos y líricos. De sus ocho disposiciones, la primera es con diferencia la más corriente y cuatro se marcan como excepcionales por lo poco que aparecen: una lo es aun siendo de las clásicas, y las otras tres se apartan además de la regla —dos cierran en pareado y una repite la misma rima en tres versos seguidos—.';
	v_nuevo constant text :=
		'Es de las estrofas más usadas del teatro del Siglo de Oro, sobre todo en los pasajes narrativos y líricos. De sus ocho disposiciones, la primera es con diferencia la más corriente, y cuatro se marcan excepcionales por lo poco que aparecen. Tres de esas cuatro quedan además fuera de las cinco que la tradición describe como propias de la forma: dos cierran en pareado y otra repite la misma rima en tres versos seguidos.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa quintilla/octosilabica_consonante.';
	end if;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;

	update public.arquitecturas_forma set descripcion = v_nuevo where arquitectura_id = v_arq;
end $$;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_viejo constant text :=
		'El criterio declarado es más amplio que la regla clásica: la admite entera y deja pasar además las tres disposiciones que la tradición documenta incumpliéndola, como el final en pareado.';
	v_nuevo constant text :=
		'El criterio declarado es más amplio que la descripción clásica: la recoge entera y admite además tres disposiciones que aquella no contempla, como el final en pareado.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and a.activo;

	select descripcion into v_actual
	from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';

	if not found then
		raise exception 'No existe el esquema abierto de la quintilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La descripción del esquema abierto no es la esperada. Dice: %', v_actual;
	end if;

	update public.esquemas_rima
	set descripcion = v_nuevo
	where arquitectura_id = v_arq and slug = 'distribucion-variable';
end $$;

commit;
