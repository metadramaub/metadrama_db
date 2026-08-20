-- La novena dice cómo se llama y quién la escribió
--
-- Revisión de su prosa. Se le había tocado el 20 de agosto para declararle el pie quebrado, y lo
-- que quedaba son dos huecos de nombre, dos notas que hablaban de más y una afirmación que dejaba
-- fuera lo mejor de su fuente.
--
-- 1. **La definición usaba un nombre que la ficha no registraba.** Dice «entre las formas
--    históricas más caracterizadas se encuentra la **copla novena**», y esa forma no tenía ni un
--    solo nombre declarado: la ficha ni siquiera abría el bloque «También llamada». Jauralde lo
--    acuña con todas las letras — «denominamos redondilla a la primera secuencia, quintilla a la
--    segunda y "copla novena" a la unión de ambas para formar una nueva estrofa».
--
-- 2. **«Novena de pie quebrado» tampoco tenía fuente.** Se creó ese mismo 20 de agosto colgada del
--    rasgo, y su respaldo es el índice de Navarro Tomás, que la indiza como entrada propia.
--
-- 3. **Las notas del rasgo atribuían y repetían.** Decían «Navarro Tomás llama novena de pie
--    quebrado a la estrofa así realizada», contra la regla de que la nota da el dato y quién lo
--    dice va en fuentes; y desde que las denominaciones cuelgan de un rasgo, la fila ya imprime
--    ese nombre al lado. Se quedan con el dato, y la del orden 4+5 gana además la precisión de
--    Jauralde: el ejemplo de Castillejo tiene el quebrado **abriendo** la quintilla final.
--
-- 4. **La afirmación de Jauralde dejaba fuera el teatro.** Su apartado documenta la copla novena
--    en el *Diálogo entre el amor y un viejo* de Rodrigo Cota, en Villamediana y **en Cervantes,
--    en *El laberinto de amor*** — que es lo que justifica esta forma en un catálogo de verso
--    dramático y no se leía en ninguna parte de la ficha. Y da el único ejemplo concreto del
--    quiebro que hay: Castillejo, `8a 8b 8b 8a 4c 8c 8d 8d 8c`.
--
-- 5. **Quilis no registra estrofas de nueve versos**, y eso merece constar como consta en otras
--    fichas. Comprobado en su índice: 5.4.5 son las de seis, 5.4.6 las de siete, 5.4.7 las de ocho
--    y 5.4.8 salta directamente a las de diez. No hay epígrafe de nueve.
--
-- 6. **Los dos vínculos de composición llevaban el mismo párrafo**, que en la ficha se leía dos
--    veces seguidas. Cada uno dice ahora el papel de su componente, que es además lo que se lee
--    desde las fichas de la quintilla y de la redondilla.

begin;

do $$
declare
	v_forma uuid;
	v_4_5 uuid;
	v_5_4 uuid;
	v_quintilla uuid;
	v_redondilla uuid;
	v_rasgo uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_actual text;
	v_n integer;

	c_jauralde constant text :=
		'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma '
		|| 'abundante en los cancioneros del siglo XV, con *abba:cdccd* como realización '
		|| 'destacada: así el *Diálogo entre el amor y un viejo* de Rodrigo Cota. La sigue después '
		|| 'en Cervantes —*El laberinto de amor*— y en Villamediana, y señala la preferencia de '
		|| 'Cristóbal de Castillejo, de quien da un ejemplo con el quebrado abriendo la quintilla '
		|| 'final: `8a 8b 8b 8a 4c 8c 8d 8d 8c`. Registra además el orden 5+4 y otras novenas de '
		|| 'metro y organización diferentes.';

	c_quilis constant text :=
		'No registra las estrofas de nueve versos. Su recorrido pasa de las de ocho a las de diez '
		|| 'sin epígrafe intermedio, de modo que la novena no figura entre las combinaciones que '
		|| 'describe.';

	c_nota_4_5 constant text :=
		'En el orden 4+5 el quiebro cae generalmente en la quintilla, y se documenta abriéndola: '
		|| 'el quinto verso de la estrofa.';

	c_nota_5_4 constant text :=
		'En el orden 5+4 el quiebro pasa a la redondilla, con la quintilla en octosílabos plenos.';

	c_nota_quintilla constant text :=
		'La quintilla es el miembro mayor de la copla novena: va detrás en el orden habitual, 4+5, '
		|| 'y delante en el 5+4. Es también donde suele caer el quiebro cuando la estrofa lo lleva '
		|| 'y la redondilla abre.';

	c_nota_redondilla constant text :=
		'La redondilla abre la copla novena en su orden habitual, 4+5, y la cierra en el 5+4, que '
		|| 'es cuando el quiebro se traslada a ella.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'novena';
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_forma is null or v_quintilla is null or v_redondilla is null or v_rasgo is null then
		raise exception 'Falta la novena, alguno de sus componentes o el rasgo del quebrado.';
	end if;

	select arquitectura_id into v_4_5 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'redondilla_quintilla' and activo;
	select arquitectura_id into v_5_4 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'quintilla_redondilla' and activo;

	if v_4_5 is null or v_5_4 is null then
		raise exception 'La novena no tiene sus dos arquitecturas activas.';
	end if;

	-- --------------------------------------------------------------- 1 y 2. Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values (v_forma, 'Copla novena', 'copla_novena', false, v_jauralde)
	on conflict (forma_id, slug_normalizado) do update set fuente_id = excluded.fuente_id;

	update public.denominaciones_metricas set fuente_id = v_navarro
	where forma_id = v_forma and slug_normalizado = 'novena_de_pie_quebrado';

	select count(*) into v_n
	from public.denominaciones_metricas where forma_id = v_forma and fuente_id is null;
	if v_n <> 0 then
		raise exception 'Quedan % nombres de la novena sin fuente.', v_n;
	end if;

	-- La condicionada por el rasgo no se cuela entre los otros nombres de la forma.
	if not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'novena_de_pie_quebrado'
			and rasgo_id = v_rasgo
	) then
		raise exception '«Novena de pie quebrado» ha dejado de colgar del rasgo.';
	end if;

	-- ------------------------------------------------------------------ 3. Las notas
	select nota into v_actual from public.arquitectura_rasgos
	where arquitectura_id = v_4_5 and rasgo_id = v_rasgo;
	if v_actual not like '%Navarro Tomás llama%' and v_actual is distinct from c_nota_4_5 then
		raise exception 'La nota del quiebro en 4+5 no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitectura_rasgos set nota = c_nota_4_5
	where arquitectura_id = v_4_5 and rasgo_id = v_rasgo;

	update public.arquitectura_rasgos set nota = c_nota_5_4
	where arquitectura_id = v_5_4 and rasgo_id = v_rasgo;

	if exists (
		select 1 from public.arquitectura_rasgos ar
		join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
		where a.forma_id = v_forma and ar.nota ilike '%Navarro%'
	) then
		raise exception 'Alguna nota de la novena sigue atribuyendo a su fuente.';
	end if;

	-- --------------------------------------------------------- 4 y 5. Las afirmaciones
	select resumen into v_actual from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id = v_jauralde;

	if not found then
		raise exception 'No existe la afirmación de Jauralde sobre la novena.';
	end if;
	if v_actual not like '%metro y organización diferentes.' then
		raise exception 'La afirmación de Jauralde no es la esperada. Acaba: %', right(v_actual, 50);
	end if;
	update public.afirmaciones_fuentes_metricas set resumen = c_jauralde
	where forma_id = v_forma and fuente_id = v_jauralde;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_quilis
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		values (v_quilis, v_forma, '§§ 5.4.7 y 5.4.8', c_quilis, 'alta');
	else
		update public.afirmaciones_fuentes_metricas set resumen = c_quilis
		where forma_id = v_forma and fuente_id = v_quilis;
	end if;

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 5 then
		raise exception 'La novena tiene % afirmaciones, no las cinco esperadas.', v_n;
	end if;

	-- ------------------------------------------------------- 6. Cada vínculo dice lo suyo
	update public.forma_relaciones set nota = c_nota_quintilla
	where forma_origen_id = v_forma and forma_destino_id = v_quintilla
		and tipo_relacion = 'compuesta_por';

	update public.forma_relaciones set nota = c_nota_redondilla
	where forma_origen_id = v_forma and forma_destino_id = v_redondilla
		and tipo_relacion = 'compuesta_por';

	select count(distinct nota) into v_n
	from public.forma_relaciones
	where forma_origen_id = v_forma and tipo_relacion = 'compuesta_por';
	if v_n <> 2 then
		raise exception 'Los dos vínculos de composición siguen diciendo lo mismo.';
	end if;

	-- ------------------------------------------------------------------ Comprobación
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('novena') -> 'denominaciones'
		) d
		where d ->> 'nombre' = 'Copla novena' and d ->> 'rasgo_id' is null
	) then
		raise exception 'La ficha de la novena no trae «Copla novena» entre sus nombres.';
	end if;
end $$;

commit;
