-- Los cinco huecos que impedían derivar las preguntas del editor.
--
-- Sale de la auditoría del 9 de agosto de 2026. De los 61 grupos de elección, 56 se derivan de
-- lo que el catálogo ya declara; los cinco restantes fallaban por **la misma carencia**: la
-- arquitectura no dice qué subconjunto de lo posible admite, y ese recorte vivía únicamente en
-- las opciones escritas a mano.
--
-- Uno de los cinco no era un hueco. La sextilla doble ofrece uno de sus dos esquemas de rima
-- porque el otro es de tipo `abierta`, y **ningún esquema abierto se ofrece nunca como opción**
-- —comprobado: 0 de 11 en todo el catálogo, y 0 de 4 entre los de tipo `restricciones`—. Un
-- esquema abierto no es una alternativa: declara que la norma no fija la disposición. Es regla,
-- no carencia, y no hay nada que declarar.
--
-- Quedan cuatro, en dos parejas.
--
-- 1 · EL PAPEL DEL METRO. La copla de pie quebrado declara tres metros en su esquema —4, 5 y
-- 8— y su pregunta ofrece solo dos, porque el octosílabo es el verso dominante y no se
-- pregunta; esa regla no estaba escrita en ninguna parte. La copla real es peor: su pregunta
-- ofrece tetrasílabo y pentasílabo, pero su arquitectura **no declara ningún conjunto de
-- metros**, de modo que esas dos medidas no salían del catálogo sino solo de las opciones.
--
-- Se añade `rol` a `esquema_metrico_opciones`. Nulo significa lo que significaba hasta ahora,
-- una alternativa entre iguales —los hexasílabos u octosílabos del villancico—; `dominante` y
-- `quebrado` distinguen el verso base del verso corto que lo quiebra. Con eso, la pregunta por
-- los quebrados se deriva: son los metros de rol `quebrado`.
--
-- 2 · EL SUBCONJUNTO ADMITIDO DE UN RASGO. `arquitectura_rasgos` podía decir «este rasgo es
-- definitorio y vale X» o «es admitido y queda abierto», pero no «admite estos dos de los
-- cinco». Por eso la silva y el endecasílabo suelto ofrecían dos grados cada una de los cinco
-- de `organizacion_en_pareados` sin que nada explicara cuáles ni por qué.
--
-- Que la carencia era real lo prueba la propia nota del endecasílabo suelto, que dice en prosa
-- «Ninguna u ocasionales»: el dato estaba escrito, pero como texto y no como hecho computable.
-- La clave primaria pasa a admitir el valor, con `nulls not distinct` para que siga habiendo
-- una sola fila cuando el eje se deja abierto de verdad.
--
-- Esto **no retira todavía ninguna pregunta**: prepara el terreno. Con los cuatro huecos
-- declarados, los 61 grupos pasan a ser derivables y la retirada del sistema de preguntas y
-- respuestas deja de depender de decisiones filológicas.
--
-- Ninguna anotación cambia: no se toca ninguna opción ni ninguna respuesta guardada.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El papel de cada metro dentro de un esquema
-- ---------------------------------------------------------------------------

alter table public.esquema_metrico_opciones
	add column if not exists rol text;

alter table public.esquema_metrico_opciones
	drop constraint if exists esquema_metrico_opciones_rol_check;

alter table public.esquema_metrico_opciones
	add constraint esquema_metrico_opciones_rol_check
	check (rol is null or rol in ('dominante', 'quebrado'));

comment on column public.esquema_metrico_opciones.rol is
	'Papel del metro dentro del esquema. Nulo es una alternativa entre iguales —el hexasílabo o el octosílabo del villancico—. «dominante» es el verso base de la estrofa y «quebrado», el verso corto que lo interrumpe: el editor solo elige entre los quebrados, porque el dominante se da por sentado.';

do $$
declare
	v_esquema uuid;
	v_m4 uuid;
	v_m5 uuid;
	v_m8 uuid;
	v_n integer;
begin
	select metro_id into v_m4 from public.metros where slug = 'tetrasilabo';
	select metro_id into v_m5 from public.metros where slug = 'pentasilabo';
	select metro_id into v_m8 from public.metros where slug = 'octosilabo';

	if num_nonnulls(v_m4, v_m5, v_m8) <> 3 then
		raise exception 'Faltan el tetrasílabo, el pentasílabo o el octosílabo';
	end if;

	-- Copla de pie quebrado: el esquema ya declaraba los tres metros, sin decir cuál es cuál.
	select em.esquema_metrico_id into v_esquema
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_de_pie_quebrado' and em.slug = 'octosilabos-con-quebrados-4-5';

	if v_esquema is null then
		raise exception 'No está el esquema de la copla de pie quebrado';
	end if;

	update public.esquema_metrico_opciones set rol = 'dominante', updated_at = now()
	where esquema_metrico_id = v_esquema and metro_id = v_m8;
	update public.esquema_metrico_opciones set rol = 'quebrado', updated_at = now()
	where esquema_metrico_id = v_esquema and metro_id in (v_m4, v_m5);

	-- Copla real: su esquema no declaraba ningún metro, aunque la pregunta ofrecía 4 y 5.
	select em.esquema_metrico_id into v_esquema
	from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_real' and a.slug = 'octosilabica_consonante';

	if v_esquema is null then
		raise exception 'No está el esquema métrico de la copla real';
	end if;

	insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, rol, orden, nota)
	values
		(v_esquema, v_m8, 'dominante', 1,
		 'Los diez versos son octosílabos; uno o dos pueden aparecer quebrados.'),
		(v_esquema, v_m4, 'quebrado', 2, null),
		(v_esquema, v_m5, 'quebrado', 3, null)
	on conflict (esquema_metrico_id, metro_id) do update
	set rol = excluded.rol, orden = excluded.orden, updated_at = now();

	select count(*) into v_n from public.esquema_metrico_opciones
	where esquema_metrico_id = v_esquema and rol = 'quebrado';
	if v_n <> 2 then
		raise exception 'La copla real debe declarar dos medidas de quebrado, no %', v_n;
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Qué valores de un rasgo admite una arquitectura
-- ---------------------------------------------------------------------------

alter table public.arquitectura_rasgos
	drop constraint arquitectura_rasgos_pkey;

-- `nulls not distinct` conserva la unicidad de la fila abierta: una arquitectura no puede
-- declarar dos veces «este rasgo es admitido y su valor queda abierto».
alter table public.arquitectura_rasgos
	add constraint arquitectura_rasgos_pkey
	unique nulls not distinct (arquitectura_id, rasgo_id, modalidad, valor_id);

comment on table public.arquitectura_rasgos is
	'Qué rasgos declara una arquitectura y con qué modalidad. Con `valor_id` fija el valor; con varias filas del mismo rasgo declara el subconjunto de valores que admite; con `valor_id` nulo deja el eje abierto.';

do $$
declare
	v_rasgo uuid;
	v_silva uuid;
	v_suelto uuid;
	v_ninguna uuid;
	v_ocasionales uuid;
	v_habituales uuid;
	v_predominantes uuid;
	v_n integer;
begin
	select rasgo_id into v_rasgo from public.rasgos_metricos
	where slug = 'organizacion_en_pareados';

	select arquitectura_id into v_silva from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'silva' and a.slug = 'endecasilabica';

	select arquitectura_id into v_suelto from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecasilabo_suelto' and a.slug = 'endecasilabica';

	select valor_id into v_ninguna from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'ninguna';
	select valor_id into v_ocasionales from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'ocasionales';
	select valor_id into v_habituales from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'habituales';
	select valor_id into v_predominantes from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'predominantes';

	if num_nonnulls(
		v_rasgo, v_silva, v_suelto,
		v_ninguna, v_ocasionales, v_habituales, v_predominantes
	) <> 7 then
		raise exception 'Falta el rasgo, una de las dos arquitecturas o uno de sus cuatro grados';
	end if;

	-- Se sustituye la fila abierta por las filas de los grados que cada una admite.
	delete from public.arquitectura_rasgos
	where rasgo_id = v_rasgo and valor_id is null
		and arquitectura_id in (v_silva, v_suelto);

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values
		(v_silva, v_rasgo, v_habituales, 'admitida', null),
		(v_silva, v_rasgo, v_predominantes, 'admitida', null),
		(v_suelto, v_rasgo, v_ninguna, 'admitida', null),
		(v_suelto, v_rasgo, v_ocasionales, 'admitida',
		 'Si los pareados llegaran a organizar la serie, el pasaje sería una silva o una tirada de pareados.');

	select count(*) into v_n from public.arquitectura_rasgos
	where rasgo_id = v_rasgo and arquitectura_id = v_silva;
	if v_n <> 2 then
		raise exception 'La silva endecasilábica debe admitir dos grados, no %', v_n;
	end if;

	select count(*) into v_n from public.arquitectura_rasgos
	where rasgo_id = v_rasgo and arquitectura_id = v_suelto;
	if v_n <> 2 then
		raise exception 'El endecasílabo suelto debe admitir dos grados, no %', v_n;
	end if;

	-- Lo declarado debe coincidir con lo que las preguntas ofrecen hoy: si no, uno de los dos
	-- está mal y hay que mirarlo antes de derivar nada.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.grupos_eleccion_metrica g on g.arquitectura_id = ar.arquitectura_id
	join public.opciones_eleccion_metrica o on o.grupo_eleccion_id = g.grupo_eleccion_id
	where ar.rasgo_id = v_rasgo
		and g.slug = 'organizacion_en_pareados'
		and o.valor_rasgo_id = ar.valor_id;
	if v_n <> 4 then
		raise exception 'Los grados declarados y los ofrecidos deben coincidir en cuatro filas, y son %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
