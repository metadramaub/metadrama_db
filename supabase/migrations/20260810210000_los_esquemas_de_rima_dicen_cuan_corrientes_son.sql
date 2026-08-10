-- Los esquemas de rima dicen ya cuán corrientes son.
--
-- Segundo tramo de la clasificación de la modalidad. De los 86 esquemas, 38 son definitorios
-- —ahí la frecuencia no se pregunta— y 3 son abiertos o de restricciones. Quedan 45 graduables,
-- y hasta hoy **ninguno de los 86 era `excepcional`**: la columna existía y no distinguía.
--
-- Cambian doce. Los otros treinta y tres se quedan como estaban, y no por descuido: en la copla
-- de arte mayor el *Diccionario* da sus tres disposiciones como «las más frecuentes» sin
-- jerarquía entre ellas, y en la redondilla, el pareado, el terceto, la endecha real, la
-- sextilla y el sexteto-lira ninguna afirmación declarada destaca una sobre otra. Marcar una
-- habitual ahí sería inventarse la jerarquía.
--
-- TODO SALE DE LAS AFIRMACIONES YA DECLARADAS, sin volver a las monografías. Se escribieron
-- durante la revisión forma por forma justamente para esto, y bastaron: la única excepción va
-- señalada abajo como criterio del proyecto.

begin;

-- ---------------------------------------------------------------------------
-- Quintilla · Morley y Bruerton, Rengifo, Quilis
-- ---------------------------------------------------------------------------
--
-- M&B: «la n.º 1 es la más frecuente, le sigue la n.º 5 y la n.º 4 es muy rara»; Rengifo recoge
-- solo las cinco primeras y omite las dos que acaban en pareado, «que se hallan alguna vez pero
-- con muy poca frecuencia»; de ABBBA dicen que aparece «alguna vez» y lo atribuyen a un error de
-- imprenta o a una adaptación especial. Quilis deriva que las combinaciones posibles son cinco.
-- Navarro Tomás numera los tipos, y de ahí se sabe qué número es cada disposición.

update public.esquemas_rima er set modalidad = 'habitual', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'quintilla' and er.slug = 'ababa';

update public.esquemas_rima er set modalidad = 'excepcional', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'quintilla' and er.slug in ('aabab', 'abbaa', 'ababb', 'abbba');

-- Y la octava pierde de su nombre la palabra que ahora dice la columna. Quedó ahí de cuando la
-- etiqueta del editor era el único sitio donde cabía decirlo.
update public.esquemas_rima er set nombre = 'Tipología 8', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'quintilla' and er.slug = 'abbba';

-- ---------------------------------------------------------------------------
-- Soneto · el Diccionario, Morley y Bruerton, Quilis, Jauralde
-- ---------------------------------------------------------------------------
--
-- De los cuartetos, el *Diccionario* dice que ABBA ABBA «es lo normal pero que son posibles
-- otras distribuciones, especialmente la que obedece al esquema ABAB ABAB», y M&B llaman a los
-- ocho primeros versos «de rígido orden». Lo normal frente a lo que se documenta advirtiendo que
-- es raro.
--
-- Los cuatro esquemas de tercetos no se tocan. Quilis da CDC DCD como la disposición clásica y
-- favorita de Petrarca, y ahí se queda `habitual`, aunque Jauralde dé CDE DCE como forma
-- clásica: la discrepancia entre las dos fuentes está registrada en sus afirmaciones y no se
-- resuelve rebajando la que una de ellas consagra.

update public.esquemas_rima er set modalidad = 'habitual', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'soneto' and er.slug = 'abbaabba';

update public.esquemas_rima er set modalidad = 'excepcional', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'soneto' and er.slug = 'abababab';

-- ---------------------------------------------------------------------------
-- Sexteto · Navarro Tomás y Quilis
-- ---------------------------------------------------------------------------
--
-- Navarro Tomás: el sexteto de endecasílabos ABABCC «se usó poco en el Siglo de Oro, frente a su
-- frecuencia en italiano», y progresó después en el Neoclasicismo. Quilis coincide: «de poco uso
-- en el Barroco y mayor difusión en el Neoclasicismo». Dos fuentes lo dicen y el corpus es
-- áureo, así que en este catálogo es excepcional aunque sea la única disposición enumerada de su
-- arquitectura.

update public.esquemas_rima er set modalidad = 'excepcional', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'sexteto' and er.slug = 'ababcc';

-- ---------------------------------------------------------------------------
-- Villancico · Navarro Tomás, y un criterio del proyecto
-- ---------------------------------------------------------------------------
--
-- Navarro Tomás presenta «como modelo preferente del siglo XVI el estribillo de tres versos, la
-- mudanza en redondilla y el enlace, vuelta y represa; junto a abba registra abab y la forma
-- asonantada abcb». Así que la abrazada es el modelo y las otras dos son alternativas: `abab`
-- baja de habitual a admitida.
--
-- Y `abcb` pasa a **excepcional por criterio del IP**, no por las fuentes: Navarro Tomás la
-- registra sin marcarla como rara. Queda dicho aquí porque el proyecto conserva su criterio
-- especializado sobre el corpus, pero no se le atribuye a una monografía lo que no dice.

update public.esquemas_rima er set modalidad = 'admitida', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'villancico' and er.slug = 'abab';

update public.esquemas_rima er set modalidad = 'excepcional', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'villancico' and er.slug = 'abcb';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- La quintilla queda con una habitual, tres admitidas y cuatro excepcionales.
	select string_agg(er.slug || '=' || er.modalidad, ' ' order by er.slug) into v_mal
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'quintilla';
	if v_mal <> 'aabab=excepcional aabba=admitida abaab=admitida ababa=habitual ababb=excepcional '
		|| 'abbaa=excepcional abbab=admitida abbba=excepcional' then
		raise exception 'La quintilla quedó como: %', v_mal;
	end if;

	-- Y ya no lleva la palabra en el nombre.
	select count(*) into v_n from public.esquemas_rima where nombre ilike '%excepcional%';
	if v_n <> 0 then
		raise exception '% esquemas siguen diciendo «excepcional» en su nombre', v_n;
	end if;

	select string_agg(er.slug || '=' || er.modalidad, ' ' order by er.slug) into v_mal
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'soneto';
	if v_mal <> 'abababab=excepcional abbaabba=habitual cdcdcd=habitual cdcede=admitida '
		|| 'cdecde=admitida cdedce=admitida' then
		raise exception 'El soneto quedó como: %', v_mal;
	end if;

	-- El villancico cambia en sus dos arquitecturas, no en una.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and er.slug = 'abab' and er.modalidad = 'admitida';
	if v_n <> 2 then raise exception '% mudanzas abab admitidas en vez de 2', v_n; end if;

	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and er.slug = 'abcb' and er.modalidad = 'excepcional';
	if v_n <> 2 then raise exception '% mudanzas abcb excepcionales en vez de 2', v_n; end if;

	-- Doce cambios en total, y la columna pasa de no distinguir nada a distinguir: de cero
	-- excepcionales a ocho. Los habituales siguen siendo diez, porque suben dos —la quintilla y
	-- los cuartetos del soneto— y bajan las dos mudanzas `abab` del villancico.
	select count(*) into v_n from public.esquemas_rima where modalidad = 'excepcional';
	if v_n <> 8 then raise exception '% esquemas excepcionales en vez de 8', v_n; end if;
	select count(*) into v_n from public.esquemas_rima where modalidad = 'habitual';
	if v_n <> 10 then raise exception '% esquemas habituales en vez de 10', v_n; end if;

	-- Y nada de esto puede haber movido lo que el editor ofrece ni lo que el término legado
	-- proponía: se ha graduado, no se ha quitado ni añadido ninguna disposición.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then raise exception 'Las opciones dejaron de ser 405 y son %', v_n; end if;
	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then raise exception 'Las respuestas propuestas dejaron de ser 91 y son %', v_n; end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
