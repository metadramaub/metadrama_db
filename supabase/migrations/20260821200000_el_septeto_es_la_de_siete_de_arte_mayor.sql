-- El septeto es la de siete de arte mayor
--
-- Primera de las cinco que cierran las estrofas de siete versos y las enlazadas. Ayer se creó la
-- **septilla**, de arte menor, con el reparto 4+3 que describe Navarro. Falta su hermana mayor, y
-- las fuentes la separan por la misma regla con que el catálogo separa la sextilla del sexteto y la
-- redondilla del cuarteto.
--
-- Jauralde, al abrir su capítulo de las estrofas de siete: «las septillas y septetos suelen
-- organizarse como estrofas compuestas de dos simples, de 4+3 […] **cabe también la distinción
-- según el tipo de verso que acojan**». Y Caparrós 2014: «se llama septeto, séptima o septilla a
-- toda estrofa de siete versos».
--
-- Se crea con las dos realizaciones que las fuentes describen:
--
-- 1. **Endecasilábica**, la que definen Quilis y el *Diccionario*: siete versos de arte mayor «que
--    riman a gusto del poeta, **con la única condición de que no rimen tres versos seguidos**».
--    Esa condición se declara como restricción `max_consecutivos`. *El auditor todavía no la
--    evalúa —`incumple` devuelve `false` para ese tipo—, y con esta forma pasa a ser el segundo
--    caso que la pide, con el soneto: queda en pendientes.*
--
-- 2. **Compuesta**, el septeto compuesto que el *Diccionario* atribuye a Navarro Tomás: «septeto
--    dividido en un cuarteto y un terceto, unidos o no por la rima». Sus dos miembros reutilizan
--    el cuarteto y el terceto del catálogo, como hacen la novena y la copla real con los suyos.
--
-- Y el **septeto agudo** —«con dos o tres versos agudos; normalmente el último verso es agudo, y el
-- otro agudo se coloca hacia la mitad de la estrofa»— no es una tercera realización sino el rasgo
-- `final_acentual` con valor `agudo`, igual que en la octava aguda de ayer. El nombre cuelga del
-- rasgo, como «Novena de pie quebrado» cuelga del suyo.
--
-- *Es forma poco usada y tardía: los ejemplos que dan las fuentes son de Moratín, Zorrilla, Rubén
-- Darío y Ridruejo. Entra por el criterio de catálogo completo, con su datación dicha.*

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_arq_comp uuid;
	v_cuarteto uuid;
	v_cuarteto_arq uuid;
	v_terceto uuid;
	v_terceto_arq uuid;
	v_septilla uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_italiana uuid := 'af269fe5-f67f-4991-9dc2-49ea12c40abd';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_endecasilabo uuid := '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
	v_rasgo uuid;
	v_agudo uuid := '3496644d-dae1-4043-8968-baebc16f6858';
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de siete versos de arte mayor. Es la hermana mayor de la septilla, y la tradición '
		|| 'las separa por la medida como separa la sextilla del sexteto: septilla en arte menor, '
		|| 'septeto en arte mayor, y séptima como nombre común a las dos. Se realiza de dos '
		|| 'maneras. En la primera, los siete endecasílabos riman a gusto del poeta con una sola '
		|| 'condición: que no rimen tres versos seguidos. En la segunda, la estrofa se divide en un '
		|| 'cuarteto y un terceto, unidos o no por la rima, que es el mismo reparto 4+3 de la '
		|| 'septilla llevado al verso largo. Cuando dos o tres de sus versos son agudos —el último '
		|| 'siempre, y el otro hacia la mitad— se la llama septeto agudo. La combinación de siete '
		|| 'versos de arte mayor no es muy usada en la poesía castellana, y los ejemplos que la '
		|| 'documentan son tardíos.';
begin
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'final_acentual';
	select forma_id into v_cuarteto from public.formas_metricas where slug = 'cuarteto';
	select forma_id into v_terceto from public.formas_metricas where slug = 'terceto';
	select forma_id into v_septilla from public.formas_metricas where slug = 'septilla';
	select arquitectura_id into v_cuarteto_arq from public.arquitecturas_forma
	where forma_id = v_cuarteto and slug = 'endecasilabica';
	select arquitectura_id into v_terceto_arq from public.arquitecturas_forma
	where forma_id = v_terceto and slug = 'endecasilabica_consonante';

	if v_rasgo is null or v_cuarteto_arq is null or v_terceto_arq is null or v_septilla is null then
		raise exception 'Falta el rasgo acentual, el cuarteto endecasílabo, el terceto o la septilla.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'septeto') then
		select forma_id into v_forma from public.formas_metricas where slug = 'septeto';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('septeto', 'Septeto', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_italiana) on conflict do nothing;

	-- ------------------------------------------------- 1. Endecasilábica, de rima libre
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'endecasilabica', 'Endecasilábica',
			'Siete endecasílabos consonantes cuya disposición no está fijada: el poeta la elige, con '
			|| 'una sola condición, que no rimen tres versos seguidos. Es la realización que las '
			|| 'fuentes describen como poco usada en la poesía castellana.',
			true, true, 'habitual', v_consonante, true, 1, 7, 7)
		returning arquitectura_id into v_arq;
	end if;

	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq;
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq, 'ciclo', '11-repetido')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		values (v_metrico, 1, v_endecasilabo, 1);
	end if;

	select esquema_rima_id into v_esquema from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';
	if v_esquema is null then
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, tipo_rima_id, modalidad, tipo_secuencia, descripcion
		)
		values (v_arq, 'distribucion-variable', 'Distribución variable', v_consonante,
			'definitoria', 'abierta',
			'La norma no fija la disposición: riman a gusto del poeta. Lo único que acota es que no '
			|| 'haya tres versos seguidos con la misma rima.')
		returning esquema_rima_id into v_esquema;

		insert into public.esquema_rima_restricciones
			(esquema_rima_id, tipo, valor_numero, descripcion)
		values (v_esquema, 'max_consecutivos', 2,
			'No riman tres versos seguidos: es la única condición que la norma pone a la libertad '
			|| 'de disposición.');
	end if;

	-- ------------------------------------------------- 2. Compuesta, cuarteto y terceto
	select arquitectura_id into v_arq_comp from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'compuesta';
	if v_arq_comp is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'compuesta', 'Compuesta',
			'Los siete versos se reparten en un cuarteto y un terceto, que pueden estar unidos por '
			|| 'la rima o no estarlo. Es el mismo reparto 4+3 de la septilla, aquí en verso largo.',
			false, true, 'admitida', v_consonante, true, 2, 7, 7)
		returning arquitectura_id into v_arq_comp;

		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq_comp, 'ciclo', '11-repetido')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		values (v_metrico, 1, v_endecasilabo, 1);

		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, tipo_rima_id, modalidad, tipo_secuencia, descripcion
		)
		values (v_arq_comp, 'distribucion-variable', 'Distribución variable', v_consonante,
			'definitoria', 'abierta',
			'Cada miembro trae la disposición de la forma que lo realiza. Lo que la norma deja '
			|| 'abierto es si el terceto recoge alguna rima del cuarteto o estrena las suyas.');
	end if;

	insert into public.estructuras_secciones (
		arquitectura_id, tipo_seccion, slug, nombre, orden,
		repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id
	)
	select v_arq_comp, x.tipo, x.slug, x.nombre, x.orden, 1, 1, x.versos, x.versos, x.ref
	from (values
		('cuarteto', 'cuarteto', 'Cuarteto', 1, 4, v_cuarteto_arq),
		('terceto', 'terceto', 'Terceto', 2, 3, v_terceto_arq)
	) as x(tipo, slug, nombre, orden, versos, ref)
	where not exists (
		select 1 from public.estructuras_secciones s
		where s.arquitectura_id = v_arq_comp and s.slug = x.slug
	);

	-- ------------------------------------------------------------- El septeto agudo
	foreach v_fila slice 1 in array array[array[v_arq::text], array[v_arq_comp::text]] loop
		insert into public.arquitectura_rasgos
			(arquitectura_id, rasgo_id, modalidad, valor_id, posiciones_max, nota)
		select v_fila[1]::uuid, v_rasgo, 'admitida', v_agudo, 3,
			'Dos o tres versos agudos. El último lo es siempre, y el otro se coloca hacia la mitad '
			|| 'de la estrofa —el tercero o el cuarto—; cuando son tres, los otros dos van '
			|| 'alternados en la primera mitad.'
		where not exists (
			select 1 from public.arquitectura_rasgos
			where arquitectura_id = v_fila[1]::uuid and rasgo_id = v_rasgo
		);
	end loop;

	-- -------------------------------------------------------------------- Los nombres
	foreach v_fila slice 1 in array array[
		array['Séptima', 'septima'], array['Septina', 'septina'], array['Seteta', 'seteta']
	] loop
		insert into public.denominaciones_metricas
			(forma_id, nombre, slug_normalizado, preferente, fuente_id)
		select v_forma, v_fila[1], v_fila[2], false, v_dc16
		where not exists (
			select 1 from public.denominaciones_metricas
			where forma_id = v_forma and slug_normalizado = v_fila[2]
		);
	end loop;

	-- El nombre que solo vale cuando el rasgo está presente cuelga del rasgo.
	insert into public.denominaciones_metricas
		(forma_id, rasgo_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, v_rasgo, 'Septeto agudo', 'septeto_agudo', false, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'septeto_agudo'
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_dc16::text, 's. v. «séptima», «septeto», «septeto agudo» y «septeto compuesto»',
			'Da «séptima» como nombre de la estrofa de siete versos, «de arte mayor, menor o '
			|| 'mezclados los de arte mayor con los de arte menor», con septeto, septilla, septina y '
			|| 'seteta como otros términos. En su segunda acepción recoge la definición de Quilis: '
			|| 'siete versos de arte mayor «que riman a gusto del poeta, con la única condición de '
			|| 'que no rimen tres versos seguidos», y ejemplifica con Dionisio Ridruejo, cerrando '
			|| 'con que «la combinación de siete versos de arte mayor no es muy usada en la poesía '
			|| 'castellana». Atribuye a Navarro Tomás dos variedades: el **septeto agudo**, «con dos '
			|| 'o tres versos agudos —normalmente el último, y el otro hacia la mitad de la '
			|| 'estrofa—», con ejemplo de Leandro Fernández de Moratín; y el **septeto compuesto**, '
			|| '«dividido en un cuarteto y un terceto, unidos o no por la rima», con ejemplo de '
			|| 'Zorrilla.'],
		array[v_quilis::text, '§ 5.4.6.1',
			'Le da epígrafe propio bajo «estrofas de siete versos», con el nombre de séptima: «poco '
			|| 'usada en nuestra métrica. Está constituida por siete versos de arte mayor, cuya rima '
			|| 'queda a gusto del poeta, con la sola condición de que tres versos no vayan seguidos '
			|| 'de la misma rima total». Ejemplifica con Rubén Darío. Es la única de las seis fuentes '
			|| 'que la trata como forma con entrada propia y no como término.'],
		array[v_dc14::text, 'pp. 205 y ss.',
			'Reúne los tres nombres bajo una misma extensión: «se llama septeto, séptima o septilla '
			|| 'a toda estrofa de siete versos», y advierte que no son muy frecuentes.'],
		array[v_jauralde::text, 'Apartado «Estrofas de siete versos»',
			'Es quien fija el reparto entre las dos: «las septillas y septetos suelen organizarse '
			|| 'como estrofas compuestas de dos simples, de 4+3 […] para ellas cabe también **la '
			|| 'distinción según el tipo de verso que acojan**», y señala aparte las formas mixtas, '
			|| 'como el septeto-lira. En los poetas del siglo XX las ve asomar «ocasionalmente, sin '
			|| 'que la forma se reitere a lo largo de un poema», como semiestrofas de poemas '
			|| 'poliestróficos.'],
		array[v_navarro::text, '§ 67 e índice',
			'Registra la estrofa de siete versos por su reparto 4-3, que indiza como «séptima o '
			|| 'septilla de 4-3» y describe en octosílabos, y documenta también una septilla aguda. '
			|| 'El *Diccionario* le atribuye los términos septeto, septeto agudo y septeto compuesto, '
			|| 'que son los que este catálogo recoge para la de arte mayor.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas»',
			'No la registran. Su repertorio no tiene ninguna estrofa de siete versos, ni entre los '
			|| 'metros españoles ni entre las formas italianas.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ Los vínculos
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_septilla, 'contrasta_con',
		'Son la misma estrofa de siete versos en las dos artes: septilla en arte menor, septeto en '
		|| 'arte mayor, y séptima como nombre común. Es el mismo reparto que separa la sextilla del '
		|| 'sexteto y la redondilla del cuarteto. Las dos admiten organizarse en cuatro y tres.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_septilla)
			or (forma_origen_id = v_septilla and forma_destino_id = v_forma)
	);

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, x.destino, 'compuesta_por', x.nota
	from (values
		(v_cuarteto, 'El cuarteto abre el septeto compuesto y aporta cuatro de sus siete versos.'),
		(v_terceto, 'El terceto cierra el septeto compuesto, recogiendo alguna rima del cuarteto o '
			|| 'estrenando las suyas.')
	) as x(destino, nota)
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = x.destino
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 2 then
		raise exception 'El septeto tiene % arquitecturas, no las dos.', v_n;
	end if;

	if not exists (
		select 1 from public.esquema_rima_restricciones r
		join public.esquemas_rima er on er.esquema_rima_id = r.esquema_rima_id
		where er.arquitectura_id = v_arq and r.tipo = 'max_consecutivos' and r.valor_numero = 2
	) then
		raise exception 'El septeto no declara la única condición que su norma pone.';
	end if;

	select count(*) into v_n
	from public.estructuras_secciones s
	where s.arquitectura_id = v_arq_comp and s.arquitectura_referenciada_id is not null;
	if v_n <> 2 then
		raise exception 'La compuesta tiene % miembros reutilizados, no los dos.', v_n;
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El septeto cita % fuentes, no las seis.', v_n;
	end if;

	-- «Septeto agudo» nombra la forma solo cuando el rasgo está, y no se cuela entre los demás.
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('septeto') -> 'denominaciones'
		) d
		where d ->> 'nombre' = 'Septeto agudo' and d ->> 'rasgo_id' is not null
	) then
		raise exception '«Septeto agudo» no ha quedado colgado del rasgo acentual.';
	end if;
end $$;

commit;
