-- El septeto-lira cierra la serie alirada
--
-- Segunda de las cinco. El catálogo tiene la **lira** de cinco versos y el **sexteto-lira** de
-- seis, las dos como formas. **La de siete faltaba**, y no es una rareza tardía: el ejemplo con que
-- el *Diccionario* la define es de **fray Luis de León** —«El ánimo constante / armado de verdad,
-- mil aceradas…»—, `7a 11B 7a 11B 7b 7c 11C`.
--
-- > «**septeto alirado.** Lira de siete versos. […] Es una clase de lira que sirve de estrofa en la
-- > canción alirada.» OTROS TÉRMINOS: lira heptástica; septeto-estancia.
--
-- Se crea como forma, por coherencia con sus dos hermanas: la serie lira → sexteto-lira →
-- septeto-lira son tres formas y no tres arquitecturas de una, porque lo que las distingue es la
-- extensión de la unidad, y eso no lo cambia una arquitectura.
--
-- **Una sola disposición declarada, y a propósito.** Jauralde advierte que el septeto-lira tiene
-- «múltiples variedades» pero no las enumera, y el *Diccionario* da una. Se declara esa como
-- habitual —no como definitoria— para no convertir un ejemplo en repertorio cerrado, que es el
-- error que se cometió con la sextilla el 18 de agosto de 2026 y hubo que deshacer el mismo día.
-- Tampoco lleva `variedades_arquitectura`: con un esquema de rima y uno métrico no hay parejas que
-- restringir.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_lira uuid;
	v_sexteto_lira uuid;
	v_septeto uuid;
	v_metrico uuid;
	v_italiana uuid := 'af269fe5-f67f-4991-9dc2-49ea12c40abd';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_hepta uuid := '4f2d2610-1e55-40a2-8ad4-e57708d80489';
	v_endeca uuid := '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de siete versos que combina heptasílabos y endecasílabos y cierra en endecasílabo, '
		|| 'con rima consonante. Es la lira llevada a siete versos, y sirve de estrofa a la canción '
		|| 'alirada: en la realización que la documenta —`7a 11B 7a 11B 7b 7c 11C`— los cuatro '
		|| 'primeros alternan dos clases, el quinto recoge la segunda y los dos últimos forman un '
		|| 'pareado que remata en verso largo. Fray Luis de León la emplea en «El ánimo constante». '
		|| 'La tradición le reconoce más variedades de las que enumera, de modo que esa disposición '
		|| 'es la corriente y no la única. Cierra la serie de las estrofas aliradas breves: la lira '
		|| 'de cinco, el sexteto-lira de seis y esta de siete.';
begin
	select forma_id into v_lira from public.formas_metricas where slug = 'lira';
	select forma_id into v_sexteto_lira from public.formas_metricas where slug = 'sexteto_lira';
	select forma_id into v_septeto from public.formas_metricas where slug = 'septeto';
	if v_lira is null or v_sexteto_lira is null or v_septeto is null then
		raise exception 'Falta la lira, el sexteto-lira o el septeto.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'septeto_lira') then
		select forma_id into v_forma from public.formas_metricas where slug = 'septeto_lira';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('septeto_lira', 'Septeto-lira', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_italiana) on conflict do nothing;

	-- ------------------------------------------------------------------ La arquitectura
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heterometrica_consonante';
	if v_arq is null then
		insert into public.arquitecturas_forma (
			forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
			tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
		)
		values (v_forma, 'heterometrica_consonante', 'Heterométrica consonante',
			'Siete versos que combinan heptasílabos y endecasílabos y terminan siempre en '
			|| 'endecasílabo. La disposición documentada alterna las dos primeras clases en los '
			|| 'cuatro versos iniciales y cierra con un pareado; la tradición reconoce más '
			|| 'variedades sin enumerarlas.',
			true, true, 'habitual', v_consonante, true, 1, 7, 7)
		returning arquitectura_id into v_arq;
	end if;

	-- La medida, verso a verso
	select esquema_metrico_id into v_metrico from public.esquemas_metricos
	where arquitectura_id = v_arq;
	if v_metrico is null then
		insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
		values (v_arq, 'secuencia', '7-11-7-11-7-7-11')
		returning esquema_metrico_id into v_metrico;

		insert into public.esquema_metrico_posiciones
			(esquema_metrico_id, posicion, metro_id, alternativa)
		select v_metrico, x.posicion, x.metro, 1
		from (values (1, v_hepta), (2, v_endeca), (3, v_hepta), (4, v_endeca),
			(5, v_hepta), (6, v_hepta), (7, v_endeca)) as x(posicion, metro);
	end if;

	-- La disposición
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia, descripcion
	)
	select v_arq, 'ababbcc', 'Alterna con pareado final', 'ababbcc', v_consonante, 'habitual',
		'secuencia',
		'Los cuatro primeros versos alternan dos clases, el quinto recoge la segunda y los dos '
		|| 'últimos forman un pareado. Es la que documenta el ejemplo de fray Luis; la tradición '
		|| 'reconoce otras que no enumera.'
	where not exists (
		select 1 from public.esquemas_rima where arquitectura_id = v_arq and slug = 'ababbcc'
	);

	-- ------------------------------------------------------------------- Los nombres
	foreach v_fila slice 1 in array array[
		array['Septeto alirado', 'septeto_alirado'],
		array['Lira de siete versos', 'lira_de_siete_versos'],
		array['Lira heptástica', 'lira_heptastica'],
		array['Septeto-estancia', 'septeto_estancia']
	] loop
		insert into public.denominaciones_metricas
			(forma_id, nombre, slug_normalizado, preferente, fuente_id)
		select v_forma, v_fila[1], v_fila[2], false, v_dc16
		where not exists (
			select 1 from public.denominaciones_metricas
			where forma_id = v_forma and slug_normalizado = v_fila[2]
		);
	end loop;

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_dc16::text, 's. v. «septeto alirado», «septeto-estancia» y «lira»',
			'Es la fuente que le da entrada propia: «septeto alirado. Lira de siete versos», y '
			|| 'precisa que «es una clase de lira que sirve de estrofa en la canción alirada». '
			|| 'Registra lira heptástica y septeto-estancia como otros términos, y ejemplifica con '
			|| 'fray Luis de León —«El ánimo constante / armado de verdad, mil aceradas…»—, cuya '
			|| 'disposición es `7a 11B 7a 11B 7b 7c 11C`.'],
		array[v_jauralde::text, 'Apartado «Estrofas de siete versos»',
			'La cuenta entre las formas mixtas de siete versos y advierte que tiene «múltiples '
			|| 'variedades», sin enumerarlas: «asimismo son importantes algunas de sus formas '
			|| 'mixtas, como el septeto-lira con sus múltiples variedades». En los poetas del siglo '
			|| 'XX la ve aparecer como semiestrofa de poemas poliestróficos.'],
		array[v_dc14::text, 'Apartado de la canción alirada',
			'Describe la canción alirada y sus estrofas —el cuarteto lira entre ellas— sin dar '
			|| 'epígrafe propio a la de siete versos, que sí recoge en el *Diccionario*.'],
		array[v_navarro::text, '§§ 161, 162 y 229',
			'Trata las estrofas aliradas como familia y no forma por forma: sigue la lira de '
			|| 'Garcilaso y de fray Luis, que da por poco empleada en el Siglo de Oro después de las '
			|| 'canciones de san Juan de la Cruz, y documenta su entrada en el teatro con Juan de la '
			|| 'Cueva, Rey de Artieda y Jerónimo Bermúdez, y en Cervantes con la canción de Lenio de '
			|| '*La Galatea*. En el período siguiente registra el sexteto de heptasílabos y '
			|| 'endecasílabos con pareado final y hasta octavas aliradas, pero no da epígrafe a la de '
			|| 'siete versos.'],
		array[v_quilis::text, '§§ 5.4.4.3 y 5.4.5.2',
			'Registra la lira de cinco versos y el sexteto-lira de seis, y no pasa de ahí: no hay en '
			|| 'su recorrido una estrofa alirada de siete.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Liras»',
			'Su «lira» es la de seis versos de siete y once sílabas con tres rimas, cuya forma más '
			|| 'corriente llaman regular, `aBaBcC`; anotan que el nombre se aplica también a la de '
			|| 'cinco versos, `aBabB`, que ellos llaman quintilla de fray Luis de León, y que «todas '
			|| 'las liras no son más que formas especializadas de la *canzone*». No registran la de '
			|| 'siete.']
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
	select v_forma, x.destino, x.tipo, x.nota
	from (values
		(v_sexteto_lira, 'derivada_de',
			'Es el sexteto-lira con un verso más: la misma combinación de heptasílabos y '
			|| 'endecasílabos y el mismo pareado final, con una clase recogida antes del remate. '
			|| 'Las dos salen de la lira de cinco versos.'),
		(v_septeto, 'contrasta_con',
			'Las dos miden siete versos de arte mayor, y se separan por la medida: el septeto es '
			|| 'isosilábico y el septeto-lira mezcla heptasílabos y endecasílabos, que es lo que lo '
			|| 'hace alirado.')
	) as x(destino, tipo, nota)
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = x.destino)
			or (forma_origen_id = x.destino and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	-- Siete posiciones métricas, y la última es larga: es lo que hace alirada a la estrofa.
	select count(*) into v_n
	from public.esquema_metrico_posiciones where esquema_metrico_id = v_metrico;
	if v_n <> 7 then
		raise exception 'El septeto-lira declara % posiciones métricas, no las siete.', v_n;
	end if;
	if not exists (
		select 1 from public.esquema_metrico_posiciones
		where esquema_metrico_id = v_metrico and posicion = 7 and metro_id = v_endeca
	) then
		raise exception 'El septeto-lira no cierra en endecasílabo.';
	end if;

	-- Y la disposición dibuja siete posiciones con su pareado final.
	if not exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = v_arq
			and (select count(*) from public.esquema_rima_posiciones p
				where p.esquema_rima_id = er.esquema_rima_id) = 7
			and (select p.clase_rima from public.esquema_rima_posiciones p
				where p.esquema_rima_id = er.esquema_rima_id and p.posicion = 6)
				= (select p.clase_rima from public.esquema_rima_posiciones p
					where p.esquema_rima_id = er.esquema_rima_id and p.posicion = 7)
	) then
		raise exception 'La disposición del septeto-lira no acaba en pareado.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'El septeto-lira cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('septeto_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha del septeto-lira no responde.';
	end if;
end $$;

commit;
