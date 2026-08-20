-- La copla de arte mayor llega al teatro como arcaísmo
--
-- Revisión de su prosa y de su rima. La ficha no decía **por qué esta forma está en un catálogo
-- de verso dramático**, y esa es su pregunta principal: es estrofa medieval, Morley y Bruerton no
-- la registran en Lope y el corpus no tiene ninguna. La respuesta estaba enterrada en una
-- afirmación de Navarro Tomás, que la documenta en el teatro y explica cómo llega: «Una carta en
-- el tercer acto de *Quien calla otorga*, de Tirso de Molina, consiste en una copla de arte
-- mayor… **Los personajes aluden al carácter antiguo de la estrofa**, aunque en realidad difiera
-- bastante del modelo tradicional». Entra en la definición.
--
-- Y esa misma carta entra como disposición, porque es la única documentada en el teatro:
-- `ABBA:CDDC`, con **cuatro** rimas donde la norma sostiene dos o tres. No contradice la
-- definición: la modalidad mide frecuencia, y `excepcional` es exactamente lo que es — un caso.
-- Que la norma se describa y no se prescriba es lo que permite recogerlo sin romper nada.
--
-- Lo demás:
--
--   * **Las tres disposiciones salían empatadas en `admitida`** y las fuentes no las igualan:
--     Quilis da solo `ABBAACCA`, Navarro dice «generalmente en forma abrazada ABBA:ACCA», y
--     Caparrós la encabeza en sus dos ediciones. Pasa a `habitual`.
--   * **Las notaciones no marcaban la división en semiestrofas.** La estrofa son dos cuartetos y
--     la ficha lo dibuja, pero la notación escrita los corría de seguido. Se escriben con dos
--     puntos, como ya hace la décima.
--   * **La medida.** La rejilla dibuja doce sílabas fijas ocho veces, y el verso de arte mayor no
--     se mide así: Jauralde precisa que «su número de sílabas varía entre diez y dieciséis», y la
--     descripción solo hablaba de «alguna fluctuación». El metro se queda en el dodecasílabo, que
--     es la realización regular, y la cifra pasa a la descripción, que es donde cabe.
--   * **Faltaba el cuarto nombre.** El *Diccionario* cierra su entrada con «antigua octava
--     castellana; copla de Juan de Mena; octava de arte mayor; **octava de Juan de Mena**», y el
--     catálogo tenía los tres primeros.
--
-- **Orden de las operaciones:** el esquema de Tirso se crea primero **sin** los dos puntos, para
-- que el disparador `sincronizar_posiciones_esquema_rima_fijo` le genere sus ocho posiciones —solo
-- reparte notaciones de letras y guiones—, y solo después se le añade la división. A los tres que
-- ya existían les basta con el `update`: el disparador no toca posiciones que no puede regenerar,
-- que es justamente lo que le pasa a la décima desde hace semanas.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_tirso uuid;
	v_actual text;
	v_n integer;
	fila record;

	c_definicion constant text :=
		'Estrofa de ocho versos de arte mayor, cada uno partido por una cesura en dos '
		|| 'hemistiquios, distribuidos en dos cuartetos de rima cruzada o abrazada. Los dos '
		|| 'cuartetos no son independientes: una rima es común a ambos y los versos cuarto y '
		|| 'quinto riman entre sí, de modo que la estrofa se sostiene sobre dos o tres rimas '
		|| 'consonantes y no sobre cuatro. Fue la estrofa de la poesía culta y solemne del siglo '
		|| 'XV —la de Santillana, Mena e Imperial—, y al teatro del Siglo de Oro llega ya como '
		|| 'arcaísmo: cuando Tirso la emplea en una carta, los personajes aluden a lo antiguo de '
		|| 'la forma, aunque la estrofa que escribe se aparte del modelo y llegue a cuatro rimas.';

	c_descripcion constant text :=
		'Ocho versos de arte mayor de dos hemistiquios separados por cesura. El dodecasílabo 6 + 6 '
		|| 'es su realización regular, pero el verso se mide por su ritmo y no por sus sílabas: el '
		|| 'cómputo oscila entre diez y dieciséis.';

	c_tirso constant text :=
		'La única documentada en el teatro: cuatro rimas en vez de tres, en una carta de *Quien '
		|| 'calla otorga*, de Tirso de Molina.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'copla_de_arte_mayor';
	if v_forma is null then
		raise exception 'No existe la copla de arte mayor.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'dodecasilabica_compuesta' and activo;
	if v_arq is null then
		raise exception 'La copla de arte mayor no tiene su arquitectura activa.';
	end if;

	-- ------------------------------------------------ La disposición que las fuentes destacan
	select modalidad into v_actual from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'abbaacca';

	if not found then
		raise exception 'No existe la disposición ABBAACCA de la copla de arte mayor.';
	end if;
	if v_actual is distinct from 'admitida' and v_actual is distinct from 'habitual' then
		raise exception 'La modalidad de ABBAACCA no es la esperada. Dice: %', v_actual;
	end if;
	update public.esquemas_rima set modalidad = 'habitual'
	where arquitectura_id = v_arq and slug = 'abbaacca';

	-- ------------------------------------------------- La carta de Tirso, con cuatro rimas
	-- Primero sin los dos puntos, para que el disparador reparta sus ocho posiciones.
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
		descripcion
	)
	select v_arq, 'abbacddc', null, 'ABBACDDC', a.tipo_rima_id, 'excepcional', 'secuencia', c_tirso
	from public.arquitecturas_forma a
	where a.arquitectura_id = v_arq
	on conflict (arquitectura_id, slug) do update
		set modalidad = excluded.modalidad, descripcion = excluded.descripcion;

	select esquema_rima_id into v_tirso from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'abbacddc';

	if (
		select string_agg(clase_rima, '' order by posicion)
		from public.esquema_rima_posiciones where esquema_rima_id = v_tirso
	) is distinct from 'ABBACDDC' then
		raise exception 'Las posiciones de la disposición de Tirso no dicen ABBACDDC.';
	end if;

	-- ---------------------------------- Las notaciones marcan la división en semiestrofas
	for fila in
		select *
		from (values
			('ababbccb', 'ABAB:BCCB'),
			('abbaacac', 'ABBA:ACAC'),
			('abbaacca', 'ABBA:ACCA'),
			('abbacddc', 'ABBA:CDDC')
		) as t(slug, notacion)
	loop
		update public.esquemas_rima set notacion = fila.notacion
		where arquitectura_id = v_arq and slug = fila.slug;
	end loop;

	-- Y las posiciones sobreviven al cambio: el disparador no regenera lo que no sabe leer.
	select count(*) into v_n
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er on er.esquema_rima_id = p.esquema_rima_id
	where er.arquitectura_id = v_arq;
	if v_n <> 32 then
		raise exception 'Las cuatro disposiciones suman % posiciones, no las 32 esperadas.', v_n;
	end if;

	-- ------------------------------------------------------------ La prosa
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%y no sobre cuatro.' and v_actual is distinct from c_definicion then
		raise exception 'La definición no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual not like '%alguna fluctuación de medida.' and v_actual is distinct from c_descripcion
	then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_descripcion where arquitectura_id = v_arq;

	-- ------------------------------------------------------------ El cuarto nombre
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	values (v_forma, 'Octava de Juan de Mena', 'octava_de_juan_de_mena', false, v_dc16)
	on conflict (forma_id, slug_normalizado) do update set fuente_id = excluded.fuente_id;

	select count(*) into v_n
	from public.denominaciones_metricas where forma_id = v_forma and rasgo_id is null;
	if v_n <> 4 then
		raise exception 'La copla de arte mayor tiene % nombres, no los cuatro del Diccionario.', v_n;
	end if;

	-- ------------------------------------------------------------ Comprobación en la ficha
	select count(*) into v_n
	from jsonb_array_elements(
		public.get_forma_metrica_publica('copla_de_arte_mayor') -> 'esquemasRima'
	) e
	where e ->> 'notacion' like '%:%';
	if v_n <> 4 then
		raise exception 'La ficha trae % disposiciones con la división marcada, no las cuatro.', v_n;
	end if;
end $$;

commit;
