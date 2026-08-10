-- La asonancia de la endecha real no la define: se generalizó.
--
-- Al preguntarse qué hace `definitoria` dentro de una escala de frecuencia salió una respuesta
-- comprobable: una realización definitoria no compite con hermanas, porque no es una alternativa
-- sino la norma que las alternativas cumplen. Si eso vale, **ninguna pregunta del catálogo debería
-- ofrecer una definitoria junto a otra modalidad**.
--
-- Se comprobó sobre las preguntas derivadas y falla en una sola: la disposición de rima de la
-- endecha real heptasílaba, que ofrecía «asonancia sostenida en los cuartos» como definitoria al
-- lado de la abrazada, la cruzada y la suelta. Es decir, **la norma y su negación como hermanas**.
--
-- LO QUE DICEN LAS FUENTES, que están registradas y no sostienen esa lectura:
--
--   Navarro Tomás § 207 narra que Bermúdez y Cervantes la emplearon en versos sueltos, que la
--   abrazada aparece en el *Romancero general*, y que «hacia mediados del siglo XVII **se
--   generalizó** la forma asonantada». Eso no es una definición: es una historia, y describe algo
--   que llegó a ser lo corriente sin serlo desde el principio.
--
--   El glosario del mismo Navarro admite además las cruzadas. El *Diccionario* de 2016 advierte
--   que el endecasílabo puede ocupar otro lugar, que pares e impares pueden rimar por separado en
--   consonante o asonante, y que **puede encontrarse sin rima**. Jauralde § 3.6 recuerda que el
--   cuarteto se usó suelto y que «se denominó endecha real cuando recibió rimas».
--
--   Solo Domínguez Caparrós 2014 la da como parte de la definición, y **el mismo autor la relaja
--   en el Diccionario de 2016**.
--
-- Lo definitorio de la endecha real, y en esto coinciden las seis, es **el metro**: tres
-- heptasílabos y un endecasílabo. La rima es justo lo que queda abierto. La arquitectura se queda
-- por tanto sin ningún esquema de rima definitorio, y es correcto: hay formas que el metro define
-- y la rima no.
--
-- Las otras dos arquitecturas de la forma no se tocan: en ellas el esquema definitorio es el
-- único, que es el caso corriente de los treinta y uno del catálogo.
--
-- Se aprovecha para atar cada afirmación a la arquitectura de la que habla. Doce afirmaciones
-- flotaban sobre la forma entera, y la ficha no dejaba ver que el relato de Navarro es sobre la
-- heptasílaba y no sobre las variedades de sor Juana. Una afirmación apunta **a una sola cosa**
-- —lo exige un `check` con `num_nonnulls(...) = 1`—, así que atarla a la arquitectura es soltarla
-- de la forma; la ficha pública ya recoge las dos maneras y las muestra juntas.

begin;

-- 1 · La asonancia pasa a ser lo habitual, que es lo que Navarro cuenta.

update public.esquemas_rima e
set modalidad = 'habitual',
	descripcion = 'Una sola asonancia recorre la composición entera, en el endecasílabo que cierra cada cuarteto: abcB dBeB. Los tres heptasílabos quedan sueltos. Es la disposición que se generalizó hacia mediados del siglo XVII, cultivada sobre todo por Trillo y Figueroa y por sor Juana Inés de la Cruz.',
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = e.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug = 'endecha_real'
	and a.slug = 'heptasilabica_con_endecasilabo'
	and e.slug = 'asonantada';

-- 2 · Cada afirmación, sobre la arquitectura que describe.

with destino(localizador, aguja, arquitectura) as (
	values
		('§ 207, p. 283', '%se generalizó%', 'heptasilabica_con_endecasilabo'),
		('§ 207, p. 283', '%introdujo en sus endechas%', 'heptasilabica_con_endecasilabo_de_cinco'),
		('§ 268, p. 333', '%asuntos más graves%', 'heptasilabica_con_endecasilabo'),
		('Glosario, s. v. «endecha real»', '%romance heptasílabo%', 'heptasilabica_con_endecasilabo'),
		('p. 189', '%versos pares%', 'heptasilabica_con_endecasilabo'),
		('s. v. «endecha real», p. 150', '%puede encontrarse sin rima%', 'heptasilabica_con_endecasilabo'),
		('§ 3.6, «Cuartetas de heptasílabos»', '%cuando recibió rimas%', 'heptasilabica_con_endecasilabo'),
		('§ 3.6, «Cuartetas de heptasílabos»', '%también la construyó con hexasílabos%', 'hexasilabica_con_endecasilabo')
)
-- Las agujas han de ser inequívocas: dos afirmaciones comparten localizador en tres casos, y
-- `update … from` con dos filas candidatas elige una cualquiera sin avisar. Por eso no valen
-- «sor Juana» ni «hexasílabos», que aparecen en las dos de su pareja.
update public.afirmaciones_fuentes_metricas af
set arquitectura_id = a.arquitectura_id,
	forma_id = null,
	updated_at = now()
from destino d, public.formas_metricas f, public.arquitecturas_forma a
where f.slug = 'endecha_real'
	and af.forma_id = f.forma_id
	and a.forma_id = f.forma_id
	and a.slug = d.arquitectura
	and af.localizador = d.localizador
	and af.resumen like d.aguja
	and af.arquitectura_id is null;

do $$
declare
	v_n integer;
	v_total integer;
	v_mal text;
	v_json jsonb;
begin
	-- El invariante que motivó todo esto: ninguna pregunta ofrece una realización definitoria
	-- junto a otra modalidad, porque una definitoria no es una alternativa sino la norma.
	with m as (
		select o.grupo_eleccion_id,
			coalesce(er.modalidad, rep.modalidad, va.modalidad, ar.modalidad) as modalidad
		from public.opciones_eleccion_metrica o
		left join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		left join public.repeticiones_metricas rep on rep.repeticion_id = o.repeticion_id
		left join public.variedades_arquitectura va on va.variedad_id = o.variedad_id
		left join public.arquitectura_rasgos ar
			on ar.rasgo_id = o.rasgo_id and ar.valor_id = o.valor_rasgo_id
	)
	select count(*), string_agg(f.slug || '·' || a.slug || '·' || g.slug, ', ')
	into v_n, v_mal
	from (
		select grupo_eleccion_id
		from m
		group by grupo_eleccion_id
		having count(*) filter (where modalidad = 'definitoria') > 0
			and count(*) filter (where modalidad is not null and modalidad <> 'definitoria') > 0
	) malas
	join public.grupos_eleccion_metrica_resueltos g on g.grupo_eleccion_id = malas.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id;
	if v_n <> 0 then
		raise exception '% preguntas ofrecen una definitoria junto a otra modalidad: %', v_n, v_mal;
	end if;

	-- La arquitectura tocada se queda sin esquema definitorio, y sus tres disposiciones siguen
	-- ahí: lo que cambia es cuál se presenta como la corriente, no cuántas hay.
	select count(*) filter (where e.modalidad = 'definitoria'),
		count(*)
	into v_n, v_total
	from public.esquemas_rima e
	join public.arquitecturas_forma a on a.arquitectura_id = e.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo';
	if v_n <> 0 or v_total <> 4 then
		raise exception 'La endecha heptasílaba tiene % definitorias sobre % esquemas', v_n, v_total;
	end if;

	-- Y las otras dos arquitecturas conservan la suya, que es su único esquema.
	select count(*) into v_n
	from public.esquemas_rima e
	join public.arquitecturas_forma a on a.arquitectura_id = e.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and a.slug <> 'heptasilabica_con_endecasilabo'
		and e.modalidad = 'definitoria';
	if v_n <> 2 then
		raise exception 'Las otras arquitecturas de la endecha tienen % definitorias en vez de 2', v_n;
	end if;

	-- Las ocho afirmaciones quedaron atadas a su arquitectura, y las cuatro que hablan de la forma
	-- entera —Quilis, las dos entradas del Diccionario y la variedad de seis versos— siguen en la
	-- forma. Doce en total, que son las que había: no se ha perdido ninguna por el camino.
	select count(*) filter (where af.arquitectura_id is not null),
		count(*)
	into v_n, v_total
	from public.afirmaciones_fuentes_metricas af
	left join public.formas_metricas f on f.forma_id = af.forma_id
	left join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
	left join public.formas_metricas f2 on f2.forma_id = a.forma_id
	where coalesce(f.slug, f2.slug) = 'endecha_real';
	if v_n <> 8 or v_total <> 12 then
		raise exception '% afirmaciones atadas de % en la endecha; se esperaban 8 de 12', v_n, v_total;
	end if;

	-- Se ejecuta lo que lee la modalidad: un cuerpo entrecomillado no se revalida solo.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 411 then
		raise exception 'Las opciones son % en vez de 411', v_n;
	end if;

	select public.obtener_catalogo_demarcador() into v_json;
	if v_json is null then
		raise exception 'El catálogo del demarcador salió vacío';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
