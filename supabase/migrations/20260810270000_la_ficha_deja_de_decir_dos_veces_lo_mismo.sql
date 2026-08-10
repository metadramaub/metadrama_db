-- La ficha deja de decir dos veces lo mismo, y el remate dice lo que es.
--
-- Cinco arreglos salidos de leer la ficha pública ahora que enseña las restricciones. Cuatro son
-- prosa que repite un dato que ya se ve, y uno es una tilde.
--
-- 1 · «EQUIVALE A» ERA CIRCULAR. La descripción del esquema de la estancia empezaba «Equivale a
--     la notación métrico-rimática abCabC:cdeeDfF», y la notación que la ficha enseña encima
--     **es** `abCabC:cdeeDfF`. Lo único que añadía —que las mayúsculas indican la medida y no
--     clases de rima distintas— no es de ese esquema: es la convención de todo el catálogo, que
--     escribe `ABBA` en el soneto por endecasílabo y `ababa` en la quintilla por octosílabo. Pasa
--     a explicarse una vez en la ficha, que es donde vale para todas.
--
-- 2 · LA NOTA DE LA ESTANCIA REPETÍA LOS RANGOS. Decía «la fronte ocupa los versos 1–6 y la
--     sirima los versos 7–13; el verso 7 es el eslabón», que es exactamente lo que la ficha
--     deriva de las posiciones. Y lo que la nota añadía —que el eslabón pertenece a la sirima
--     aunque rime con la fronte— ya lo dice la nota de la posición 7.
--
-- 3 · «ESLABON» LE FALTABA LA TILDE. El nombre de la parte sale del valor guardado en las
--     posiciones, y la ficha capitaliza pero no acentúa. Es el único de los quince que la lleva.
--
-- 4 · EL REMATE NO DECÍA LO QUE ES. «Fragmento final de estancia; la extensión concreta se
--     registra cuando aparece» no cuenta ni para qué sirve. Las fuentes sí: el *Diccionario*
--     2014 dice que es el fragmento «en el que el poeta suele dirigirse a la canción», y el de
--     2016 que «normalmente tiene el primer verso suelto». Jauralde añade que en él «se señala
--     explícitamente a la canción esa dedicatoria».
--
--     Y en la otra arquitectura la nota decía «se mantiene opcional **hasta confirmar con el
--     IP** si debe exigirse en el corpus», que es proceso del proyecto y no métrica: justo lo
--     que el criterio de la prosa prohíbe que lleve una nota.
--
-- 5 · LAS RESTRICCIONES DE VERSOS SUELTOS DECÍAN LO MISMO DE CINCO MANERAS. Las tres de la silva
--     tienen el mismo valor, `admitidos`, y describían «Puede contener versos sueltos
--     intercalados», «Puede contener versos sueltos» y «Puede contener versos sueltos». La
--     diferencia era azar de redacción. Se retiran las cinco descripciones y la fórmula derivada
--     pasa a decirlo bien: «Admite versos sueltos intercalados», «Predominan los versos sueltos
--     sobre los rimados», «Todos los versos quedan sueltos».

begin;

-- ---------------------------------------------------------------------------
-- 1 y 2 · La prosa que repetía la notación y las posiciones
-- ---------------------------------------------------------------------------

update public.esquemas_rima er
set descripcion = null, updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'cancion_petrarquista' and er.slug = 'abcabccdeedff';

update public.estructuras_secciones s
set nota = null, updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'cancion_petrarquista' and a.slug = 'regular_13_versos' and s.slug = 'estancia';

-- La guarda de abajo encontró una tercera al aplicarse: la del sexteto cerraba «…con un pareado
-- de tercera rima, ABABCC», con la notación que la ficha enseña al lado. La explicación se queda;
-- la repetición se va.
update public.esquemas_rima er
set descripcion = 'Los cuatro primeros versos alternan dos rimas y los dos últimos cierran con un pareado de tercera rima.',
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'sexteto' and er.slug = 'ababcc';

-- ---------------------------------------------------------------------------
-- 3 · La tilde
-- ---------------------------------------------------------------------------

update public.esquema_rima_posiciones
set seccion = 'eslabón', updated_at = now()
where seccion = 'eslabon';

-- ---------------------------------------------------------------------------
-- 4 · El remate
-- ---------------------------------------------------------------------------

update public.estructuras_secciones s
set nota = 'El poeta suele dirigirse en él a la propia canción, y el Diccionario registra que normalmente lleva el primer verso suelto.',
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'cancion_petrarquista' and s.slug = 'remate';

-- ---------------------------------------------------------------------------
-- 5 · Las restricciones dicen su valor una sola vez
-- ---------------------------------------------------------------------------

update public.esquema_rima_restricciones
set descripcion = null, updated_at = now()
where tipo = 'versos_sueltos';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Nada de lo que queda escrito puede repetir la notación que tiene al lado.
	select count(*), string_agg(er.slug, ', ') into v_n, v_mal
	from public.esquemas_rima er
	where er.notacion is not null and er.descripcion is not null
		and position(er.notacion in er.descripcion) > 0;
	if v_n <> 0 then
		raise exception '% descripciones repiten su propia notación: %', v_n, v_mal;
	end if;

	-- Ni una nota puede contar lo que el proyecto tiene pendiente decidir. Con límite de palabra:
	-- sin él, «sin verso de enlace independiente» del zéjel salta por llevar «pendiente» dentro.
	select count(*), string_agg(slug, ', ') into v_n, v_mal
	from public.estructuras_secciones
	where nota ~* '(\mpendiente\M|hasta confirmar|con el IP|por decidir|falta decidir)';
	if v_n <> 0 then
		raise exception '% notas de sección cuentan el proceso del proyecto: %', v_n, v_mal;
	end if;

	select count(*) into v_n from public.esquema_rima_posiciones where seccion = 'eslabon';
	if v_n <> 0 then
		raise exception 'Quedan % posiciones con «eslabon» sin tilde', v_n;
	end if;
	select count(*) into v_n from public.esquema_rima_posiciones where seccion = 'eslabón';
	if v_n <> 1 then
		raise exception 'Hay % eslabones en vez de 1', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_restricciones where tipo = 'versos_sueltos' and descripcion is not null;
	if v_n <> 0 then
		raise exception '% restricciones de versos sueltos siguen con descripción propia', v_n;
	end if;

	-- Y el valor sigue estando, que es lo que ahora tiene que decirlo todo.
	select count(*) into v_n
	from public.esquema_rima_restricciones where tipo = 'versos_sueltos' and valor_texto is null;
	if v_n <> 0 then
		raise exception '% restricciones de versos sueltos se quedaron sin valor', v_n;
	end if;

	-- La ficha de la canción sigue compilando: es la que más se ha tocado.
	if public.get_forma_metrica_publica_jerarquica('cancion_petrarquista') is null then
		raise exception 'La ficha de la canción dejó de responder';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
