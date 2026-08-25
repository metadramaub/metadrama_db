-- El quiebro de la novena abre la quintilla
--
-- Corrección de una afirmación que ninguna fuente sostenía, y que se descubrió al preguntar el IP
-- dónde caería el quiebro en el orden 5+4.
--
-- **Lo que dicen las fuentes, comprobado.** De las seis, **solo Jauralde trata la copla novena como
-- estrofa** —Navarro no la recoge; sus quince menciones de «novena» son de posición de acento, y
-- Quilis pasa de las de ocho a las de diez sin epígrafe intermedio—. Y Jauralde documenta **un solo
-- ejemplo con quebrado**, de Castillejo:
--
-- > «…de él es este ejemplo **con quebrado abriendo la quintilla final** (4+5 = 8a 8b 8b 8a **4c**
-- > 8c 8d 8d 8c)»
--
-- Es decir: **un** quiebro, tetrasílabo, en el **quinto verso** de la estrofa, que con el orden 4+5
-- es el primero de la quintilla. La nota del orden 4+5 lo decía bien.
--
-- **La del orden 5+4 no.** Decía «el quiebro pasa a la redondilla, con la quintilla en octosílabos
-- plenos», y eso **no sale de ninguna fuente**: Jauralde menciona que el orden 5+4 se ensayó
-- —«incluyendo la de 5+4»— pero no da ningún ejemplo suyo con quebrado. La nota era una
-- extrapolación escrita al crear la forma, y además **extrapolaba mal**: lo que el ejemplo documenta
-- no es que el quebrado abra el segundo miembro, sino que **abre la quintilla**. Con el orden 5+4 la
-- quintilla va primera, de modo que por ese patrón el quiebro caería en el **primer verso de la
-- estrofa**, no en el sexto.
--
-- *Decisión del IP el 25 de agosto de 2026: se corrige la nota al patrón documentado.* El techo de
-- uno se mantiene en las dos, y ahora descansa en el ejemplo y no en una lectura del singular.
--
-- **Y la afirmación de fuente gana el dato**, que es donde debe vivir: el resumen de Jauralde
-- recogía la disposición `abba:cdccd` de Cota y no el ejemplo quebrado de Castillejo, que es el
-- único que documenta el rasgo.

begin;

do $$
declare
	v_forma uuid;
	v_rasgo uuid;
	v_jauralde uuid;
	v_arq_45 uuid;
	v_arq_54 uuid;
	v_n integer;
	v_actual text;

	c_nota_45 constant text :=
		'En el orden 4+5 el quiebro abre la quintilla, que con ese orden es el quinto verso de la '
		|| 'estrofa. Es el único caso que las fuentes documentan: Jauralde recoge de Castillejo '
		|| '«8a 8b 8b 8a 4c 8c 8d 8d 8c», con un solo quebrado tetrasílabo.';

	c_nota_54 constant text :=
		'En el orden 5+4 ninguna fuente documenta un ejemplo con quebrado. Por el patrón que sí se '
		|| 'documenta —el quebrado abre la quintilla—, caería en el primer verso de la estrofa, que '
		|| 'es donde la quintilla empieza con este orden. Sigue siendo uno solo.';

	c_resumen constant text :=
		'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma '
		|| 'abundante en los cancioneros del siglo XV, con *abba:cdccd* como realización destacada: '
		|| 'así el *Diálogo entre el amor y un viejo* de Rodrigo Cota, y también Cervantes en *El '
		|| 'Laberinto de amor* y Villamediana. Señala que el orden inicial fue redondilla más '
		|| 'quintilla (4+5) y que la forma derivó a juegos de rima más complicados hasta aislar cada '
		|| 'semiestrofa y ensayar variantes, incluida la de 5+4. Atribuye a Cristóbal de Castillejo '
		|| 'cierta preferencia por la novena y da de él **el único ejemplo con quebrado**, que abre '
		|| 'la quintilla final: «8a 8b 8b 8a 4c 8c 8d 8d 8c».';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'novena' and activo;
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado' and activo;
	select fuente_id into v_jauralde from public.fuentes_metricas
	where autoria like 'Pablo Jauralde%';
	if v_forma is null or v_rasgo is null or v_jauralde is null then
		raise exception 'Falta la novena, el rasgo del quiebro o la fuente de Jauralde.';
	end if;

	select arquitectura_id into v_arq_45 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'redondilla_quintilla' and activo;
	select arquitectura_id into v_arq_54 from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'quintilla_redondilla' and activo;
	if v_arq_45 is null or v_arq_54 is null then
		raise exception 'La novena no tiene sus dos arquitecturas activas.';
	end if;

	-- La nota que se retira es la que la cabecera cita. Si alguien la cambió, esta corrección
	-- estaría discutiendo con otro texto.
	select nota into v_actual from public.arquitectura_rasgos
	where arquitectura_id = v_arq_54 and rasgo_id = v_rasgo;
	if v_actual is null or v_actual not like '%pasa a la redondilla%' then
		raise exception 'La nota del orden 5+4 no es la esperada. Dice: «%».', v_actual;
	end if;

	update public.arquitectura_rasgos set nota = c_nota_45
	where arquitectura_id = v_arq_45 and rasgo_id = v_rasgo;
	update public.arquitectura_rasgos set nota = c_nota_54
	where arquitectura_id = v_arq_54 and rasgo_id = v_rasgo;

	update public.afirmaciones_fuentes_metricas set resumen = c_resumen
	where forma_id = v_forma and fuente_id = v_jauralde;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n
	from public.arquitectura_rasgos
	where arquitectura_id in (v_arq_45, v_arq_54) and rasgo_id = v_rasgo
		and nota like '%abre la quintilla%';
	if v_n <> 2 then
		raise exception 'Solo % de las dos notas dice que el quiebro abre la quintilla.', v_n;
	end if;

	-- Ya no queda la afirmación que ninguna fuente sostenía.
	select count(*) into v_n
	from public.arquitectura_rasgos
	where arquitectura_id in (v_arq_45, v_arq_54) and rasgo_id = v_rasgo
		and nota like '%pasa a la redondilla%';
	if v_n <> 0 then
		raise exception 'Sigue habiendo % notas diciendo que el quiebro pasa a la redondilla.', v_n;
	end if;

	-- El techo de uno se mantiene en las dos, y con él lo que el editor puede marcar.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.grupos_eleccion_metrica g
		on g.arquitectura_id = ar.arquitectura_id
		and g.slug = 'posiciones_pie_quebrado' and g.activo
	where ar.arquitectura_id in (v_arq_45, v_arq_54) and ar.rasgo_id = v_rasgo
		and ar.posiciones_max = 1 and g.selecciones_max = 1;
	if v_n <> 2 then
		raise exception 'El techo de uno no se sostiene en las dos arquitecturas (% de 2).', v_n;
	end if;

	-- Y la afirmación de Jauralde recoge ya el ejemplo que documenta el rasgo.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_jauralde and resumen like '%Castillejo%'
	) then
		raise exception 'La afirmación de Jauralde no recoge el ejemplo de Castillejo.';
	end if;

	if public.get_forma_metrica_publica('novena') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la novena ha dejado de responder.';
	end if;
end $$;

commit;
