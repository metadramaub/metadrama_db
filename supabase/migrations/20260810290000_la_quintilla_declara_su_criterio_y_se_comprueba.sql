-- La quintilla declara su criterio, y sus ocho tipologías se comprueban contra él.
--
-- Cierre de la transversal de los esquemas abiertos. La quintilla tenía ocho disposiciones
-- enumeradas y **el criterio que las admite vivía fuera del catálogo**: el IP lo enunció de
-- palabra —«nuestra única restricción es que no quede un verso sin rima»— y no había manera de
-- comprobar que las ocho lo cumplieran.
--
-- AL FORMALIZARLO APARECIÓ QUE ESTABA INCOMPLETO. Ese criterio, tal como se enunció, genera
-- **diez** disposiciones y el catálogo declara ocho. Las dos que sobraban son `aaabb` y `aabbb`,
-- y tienen algo en común: son las únicas en que cada clase ocupa un bloque seguido, de modo que
-- la estrofa se parte en un terceto y un pareado y no se entrelaza en ningún punto. Todas las
-- declaradas alternan en algún sitio, incluida `abbba`.
--
-- Le faltaba, pues, una cláusula: **la rima cambia de clase al menos dos veces**. Con ella el
-- criterio genera exactamente las ocho declaradas, ni una más ni una menos.
--
-- DÓNDE VIVE EL CRITERIO. No es de una disposición sino de todas, así que se declara como el
-- **esquema abierto** de la arquitectura, con sus restricciones, y las ocho concretas quedan
-- como sus realizaciones documentadas. Es la fila «abierto más concreto» de las reglas que el
-- catálogo ya tenía escritas, y es fiel: la norma de la quintilla no dice cuál de las ocho, dice
-- qué es admisible. Como ningún esquema abierto se ofrece nunca como opción, **el editor sigue
-- viendo las mismas ocho**.
--
-- *Se descartó hacer que una restricción pudiera colgar de una arquitectura además de un
-- esquema. Sería más fiel en general —las de la silva también son norma de su arquitectura, no
-- de su esquema— pero es una columna nueva, y no se abre por un caso.*
--
-- Y LO QUE DE VERDAD SE GANA es la última guarda: **las ocho se contrastan contra el criterio**.
-- Hasta hoy la enumeración y el criterio no podían contradecirse porque el criterio no existía
-- como dato; a partir de ahora, si alguien añade una novena que no lo cumpla, la migración no
-- entra.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El criterio, como esquema abierto de la arquitectura
-- ---------------------------------------------------------------------------

insert into public.esquemas_rima (
	arquitectura_id, slug, nombre, notacion, ambito, tipo_secuencia, tipo_rima_id,
	modalidad, descripcion, estado_revision
)
select a.arquitectura_id, 'distribucion-variable', 'Distribución admitida', null, 'unidad',
	'abierta',
	(select er.tipo_rima_id from public.esquemas_rima er
	 where er.arquitectura_id = a.arquitectura_id and er.slug = 'ababa'),
	'definitoria',
	'La norma no fija cuál de las disposiciones admitidas presenta la estrofa: fija qué las hace admisibles. Las ocho tipologías declaradas son las que la cumplen.',
	'revisada'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where f.slug = 'quintilla'
	and not exists (
		select 1 from public.esquemas_rima e2
		where e2.arquitectura_id = a.arquitectura_id and e2.slug = 'distribucion-variable'
	);

-- ---------------------------------------------------------------------------
-- 2 · Sus tres restricciones
-- ---------------------------------------------------------------------------

insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_numero, valor_texto, obligatoria)
select er.esquema_rima_id, v.tipo, v.numero, v.texto, true
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
cross join (values
	('numero_clases', 2, null::text),
	('min_alternancias', 2, null::text),
	('versos_sueltos', null::integer, 'ninguno')
) as v(tipo, numero, texto)
where f.slug = 'quintilla' and er.slug = 'distribucion-variable'
	and not exists (
		select 1 from public.esquema_rima_restricciones x
		where x.esquema_rima_id = er.esquema_rima_id and x.tipo = v.tipo
	);

-- ---------------------------------------------------------------------------
-- Las pruebas · las ocho contra el criterio
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	with pos as (
		select er.esquema_rima_id, er.slug, p.clase_rima, p.suelto,
			lag(p.clase_rima) over (
				partition by er.esquema_rima_id order by p.bloque, p.posicion
			) as anterior
		from public.esquemas_rima er
		join public.esquema_rima_posiciones p on p.esquema_rima_id = er.esquema_rima_id
		join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'quintilla' and er.tipo_secuencia <> 'abierta'
	),
	resumen as (
		select esquema_rima_id, slug,
			count(*) as versos,
			count(distinct clase_rima) as clases,
			count(*) filter (where suelto) as marcados_sueltos,
			count(*) filter (where anterior is not null and anterior is distinct from clase_rima)
				as alternancias,
			-- Un verso sin rima es una clase que aparece una sola vez.
			min(veces) as menor_clase
		from pos
		join lateral (
			select count(*) as veces from pos p2
			where p2.esquema_rima_id = pos.esquema_rima_id and p2.clase_rima = pos.clase_rima
		) c on true
		group by 1, 2
	)
	select count(*), string_agg(
		slug || ' (' || versos || ' versos, ' || clases || ' clases, ' || alternancias
		|| ' alternancias, clase menor ' || menor_clase || ')', '; ' order by slug
	)
	into v_n, v_mal
	from resumen
	where versos <> 5 or clases <> 2 or marcados_sueltos > 0 or alternancias < 2 or menor_clase < 2;

	if v_n <> 0 then
		raise exception '% tipologías de la quintilla no cumplen su criterio: %', v_n, v_mal;
	end if;

	-- Y siguen siendo ocho más el abierto.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'quintilla' and er.tipo_secuencia <> 'abierta';
	if v_n <> 8 then
		raise exception 'La quintilla tiene % tipologías concretas en vez de 8', v_n;
	end if;

	select count(*) into v_n
	from public.esquema_rima_restricciones x
	join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'quintilla';
	if v_n <> 3 then
		raise exception 'La quintilla declara % restricciones en vez de 3', v_n;
	end if;

	-- El editor tiene que seguir ofreciendo ocho: un esquema abierto no es una alternativa.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'quintilla' and g.dimension = 'rima';
	if v_n <> 8 then
		raise exception 'La quintilla ofrece % respuestas de rima en vez de 8', v_n;
	end if;

	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then raise exception 'Las opciones dejaron de ser 405 y son %', v_n; end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
