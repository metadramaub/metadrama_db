-- La novena no quiebra por norma
--
-- Corrige lo que la migración de esta misma mañana hizo de más. Al declarar el pie quebrado en
-- la novena se le dio el mecanismo completo de la copla real —medidas quebradas en su esquema
-- métrico y una pregunta por las posiciones—, y con eso su medida pasó a leerse «Variable ·
-- verso a verso — 8 de base, con quebrados de 4 · 5», perdiendo la rejilla de nueve octosílabos.
--
-- Las cuatro fuentes de la novena dicen lo contrario, y con el mismo adverbio: Navarro Tomás
-- «registra **también** el orden 5+4 y realizaciones con versos quebrados»; Caparrós 2014
-- documenta «**mezclas** de versos largos y quebrados»; el *Diccionario* dice que «**puede**
-- combinar octosílabos con tetrasílabos»; y Jauralde «registra **además** el orden 5+4, versos
-- quebrados y otras novenas», dando como realización destacada `abba:cdccd`, de octosílabos
-- plenos. El quebrado es realización añadida, no la norma de la estrofa.
--
-- La copla real sí conserva el mecanismo, y la diferencia se sostiene en el dato: de ella Navarro
-- dice que «**suele ser afectado** por el pie quebrado, sobre todo en su segunda mitad», y el
-- corpus tiene anotada una copla real quebrada de cincuenta versos en *El caballero de Olmedo*.
-- De la novena no hay ninguna.
--
-- Así que la novena queda como la redondilla: medida fija y el rasgo admitido a secas. Dónde cae
-- el quiebro lo siguen diciendo las notas de cada arquitectura, que es lo que Navarro precisa —la
-- quintilla en el orden 4+5, la redondilla en el 5+4— y lo único que precisa: ninguna fuente fija
-- el verso, de modo que el tope de posiciones también se retira.
--
-- Se conservan la definición y los vínculos, que no dicen nada que esto desmienta.

begin;

do $$
declare
	v_novena uuid;
	v_rasgo uuid;
	v_n integer;
begin
	select forma_id into v_novena from public.formas_metricas where slug = 'novena';
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_novena is null or v_rasgo is null then
		raise exception 'Falta la forma «novena» o el rasgo «pie_quebrado».';
	end if;

	-- Nadie ha llegado a usar la pregunta: se creó hoy. Si alguien la hubiera usado, esto lo dice
	-- antes de borrar nada.
	select count(*) into v_n
	from public.elecciones_editor_metrico e
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = e.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where a.forma_id = v_novena and g.slug = 'posiciones_pie_quebrado';
	if v_n <> 0 then
		raise exception 'Hay % anotaciones que usan la pregunta de quebrados de la novena.', v_n;
	end if;

	delete from public.grupos_eleccion_metrica g
	using public.arquitecturas_forma a
	where a.arquitectura_id = g.arquitectura_id
		and a.forma_id = v_novena
		and g.slug = 'posiciones_pie_quebrado';

	delete from public.esquema_metrico_opciones o
	using public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = o.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_novena;

	update public.esquemas_metricos em
	set medida_uniforme = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = em.arquitectura_id and a.forma_id = v_novena;

	update public.arquitectura_rasgos ar
	set posiciones_max = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = ar.arquitectura_id
		and a.forma_id = v_novena
		and ar.rasgo_id = v_rasgo;

	-- El rasgo se queda, con sus dos notas, que es lo que esta corrección no toca.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_novena
		and ar.rasgo_id = v_rasgo
		and ar.modalidad = 'admitida'
		and ar.posiciones_max is null
		and ar.nota is not null;
	if v_n <> 2 then
		raise exception 'Las dos arquitecturas de la novena no declaran el quebrado como se espera (son %).', v_n;
	end if;

	-- Y su medida vuelve a ser la de nueve octosílabos: ni opciones quebradas ni pregunta.
	if exists (
		select 1 from public.esquema_metrico_opciones o
		join public.esquemas_metricos em on em.esquema_metrico_id = o.esquema_metrico_id
		join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
		where a.forma_id = v_novena
	) then
		raise exception 'La novena conserva opciones métricas quebradas.';
	end if;
	if exists (
		select 1 from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		where a.forma_id = v_novena and g.slug = 'posiciones_pie_quebrado'
	) then
		raise exception 'La novena conserva la pregunta por las posiciones quebradas.';
	end if;

	-- La copla real, en cambio, la conserva entera: es la que sí la tiene ganada.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_real' and g.slug = 'posiciones_pie_quebrado';
	if v_n <> 20 then
		raise exception 'La copla real deriva % opciones de quebrado, no las 20 de siempre.', v_n;
	end if;
end $$;

commit;
