-- La octava aguda rima en los versos que cierran
--
-- Tercera de las seis. Es la tercera estructura de ocho versos, y no es una copla castellana con un
-- rasgo encima: cambia también la rima. El *Diccionario*:
--
-- > «Combinación estrófica de ocho versos de nueve o más sílabas, dividida en dos semiestrofas
-- > simétricas, en que **el cuarto y el octavo llevan rima aguda** consonante o asonante. **Los
-- > restantes versos no se ajustan a un esquema fijo de rima, e incluso pueden quedar algunos
-- > sueltos.**»
--
-- Eso el catálogo sabe escribirlo: `---a---a`, con las posiciones libres marcadas como sueltas,
-- igual que la mudanza asonantada del villancico. Y el apellido «aguda» es el rasgo
-- `final_acentual` con valor `agudo`, que **ya existía y ya se usaba así**: el sexteto alejandrino
-- lo declara con `posiciones_max = 2` y la nota «riman en agudo los versos tercero y sexto, que son
-- los que cierran cada semiestrofa». Aquí son el cuarto y el octavo, y es definitorio.
--
-- **La medida va como arquitectura**, que es donde el catálogo la pone siempre. La octava aguda es
-- de arte mayor —endecasílabos o decasílabos— y la de arte menor se llama **octavilla aguda**: el
-- *Diccionario* la define como «combinación de ocho versos octosílabos o menores que se ajusta a
-- las mismas normas de la octava aguda», de modo que no es otra forma sino la misma en otro metro.
-- Ese nombre cuelga de las arquitecturas de arte menor, que es lo que nombra.
--
-- **Queda fuera del corpus áureo y se crea a propósito.** Las tres fuentes que la tratan la fechan:
-- el *Diccionario*, «muy popular a finales del siglo XVIII y durante el siglo XIX» y «forma muy
-- usada en el Romanticismo»; Jauralde, «durante el siglo XVIII se incorpora al repertorio». El
-- criterio, fijado por el IP el 21 de agosto de 2026, es que el catálogo métrico sea completo y no
-- un inventario del corpus: cada ficha dice su datación, que es un dato y no una disculpa.

begin;

do $$
declare
	v_forma uuid;
	v_castellana uuid;
	v_arq uuid;
	v_metrico uuid;
	v_esquema uuid;
	v_italiana uuid := 'af269fe5-f67f-4991-9dc2-49ea12c40abd';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_asonante uuid := 'c5b9a139-a184-471a-b7a7-aa65ed377e85';
	v_agudo uuid := '3496644d-dae1-4043-8968-baebc16f6858';
	v_rasgo uuid;
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de ocho versos dividida en dos semiestrofas simétricas cuyos versos de cierre —el '
		|| 'cuarto y el octavo— **riman entre sí en aguda**, en consonante o en asonante. Los '
		|| 'demás no se ajustan a ningún esquema fijo: pueden rimar entre sí o quedar sueltos, y es '
		|| 'la rima aguda de los cierres la que sostiene la estrofa entera. En arte mayor '
		|| '—endecasílabos o decasílabos— se la llama octava aguda; en arte menor, de ocho sílabas '
		|| 'o menos, octavilla aguda, y es la misma estructura. Se incorpora al repertorio '
		|| 'castellano en el siglo XVIII sobre modelos italianos, de donde le viene el otro nombre '
		|| 'de octava italiana, y es forma muy usada en el Romanticismo: de carácter ligero, se '
		|| 'acomoda bien al canto y abunda en canciones e himnos. La modalidad aguda no le '
		|| 'pertenece en exclusiva —se extendió a la sextilla y a la décima—, pero aquí es lo que '
		|| 'define la estrofa.';
begin
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'final_acentual';
	select forma_id into v_castellana from public.formas_metricas where slug = 'copla_castellana';
	if v_rasgo is null or v_castellana is null then
		raise exception 'Falta el rasgo del final acentual o la copla castellana.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'octava_aguda') then
		select forma_id into v_forma from public.formas_metricas where slug = 'octava_aguda';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('octava_aguda', 'Octava aguda', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_italiana) on conflict do nothing;

	-- ------------------------------------------------- Una arquitectura por medida
	foreach v_fila slice 1 in array array[
		array['endecasilabica', 'Endecasilábica', 'habitual', '1', '72fbe06d-9f46-4690-9df8-a4d9f0611d0d', 'mayor'],
		array['decasilabica', 'Decasilábica', 'admitida', '2', 'e582a94f-e84e-4831-9861-620ea5363199', 'mayor'],
		array['octosilabica', 'Octosilábica', 'habitual', '3', '82bd7a89-675e-41a9-9324-538589731000', 'menor'],
		array['heptasilabica', 'Heptasilábica', 'admitida', '4', '4f2d2610-1e55-40a2-8ad4-e57708d80489', 'menor'],
		array['hexasilabica', 'Hexasilábica', 'admitida', '5', '6e6e3a7e-40d2-4aff-bab7-27044174b5e5', 'menor'],
		array['pentasilabica', 'Pentasilábica', 'admitida', '6', 'eac128ba-e438-49b4-8a13-057733271b38', 'menor']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];

		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			values (
				v_forma, v_fila[1], v_fila[2],
				'Ocho versos en dos semiestrofas de cuatro. Riman entre sí el cuarto y el octavo, '
				|| 'en aguda; los demás quedan a lo que traiga el poema.',
				v_fila[1] = 'endecasilabica', true, v_fila[3],
				null, true, v_fila[4]::integer, 8, 8
			)
			returning arquitectura_id into v_arq;
		end if;

		-- La medida
		select esquema_metrico_id into v_metrico from public.esquemas_metricos
		where arquitectura_id = v_arq;
		if v_metrico is null then
			insert into public.esquemas_metricos (arquitectura_id, tipo_secuencia, slug)
			values (v_arq, 'ciclo', 'repetido')
			returning esquema_metrico_id into v_metrico;

			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_fila[5]::uuid, 1);
		end if;

		-- Las dos disposiciones: la misma figura en los dos regímenes que la fuente admite.
		select esquema_rima_id into v_esquema from public.esquemas_rima
		where arquitectura_id = v_arq and slug = 'aguda-consonante';
		if v_esquema is null then
			insert into public.esquemas_rima (
				arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
				descripcion
			)
			values (v_arq, 'aguda-consonante', 'Aguda consonante', '---a---a', v_consonante,
				'habitual', 'secuencia',
				'Solo el cuarto y el octavo verso están fijados: riman entre sí y en aguda. Los '
				|| 'seis restantes pueden rimar entre ellos o quedar sueltos.');
		end if;

		select esquema_rima_id into v_esquema from public.esquemas_rima
		where arquitectura_id = v_arq and slug = 'aguda-asonante';
		if v_esquema is null then
			insert into public.esquemas_rima (
				arquitectura_id, slug, nombre, notacion, tipo_rima_id, modalidad, tipo_secuencia,
				descripcion
			)
			values (v_arq, 'aguda-asonante', 'Aguda asonante', '---a---a', v_asonante,
				'admitida', 'secuencia',
				'La misma figura con la rima de los cierres en asonante, que la fuente admite junto '
				|| 'a la consonante.');
		end if;

		-- El apellido de la forma, dicho como rasgo
		insert into public.arquitectura_rasgos
			(arquitectura_id, rasgo_id, modalidad, valor_id, posiciones_max, nota)
		select v_arq, v_rasgo, 'definitoria', v_agudo, 2,
			'Riman en agudo los versos cuarto y octavo, que son los que cierran cada semiestrofa. '
			|| 'Es lo que da nombre a la estrofa y lo único que su norma fija.'
		where not exists (
			select 1 from public.arquitectura_rasgos
			where arquitectura_id = v_arq and rasgo_id = v_rasgo
		);

		-- El nombre de arte menor cuelga de las arquitecturas que nombra
		if v_fila[6] = 'menor' then
			insert into public.denominaciones_metricas
				(arquitectura_id, nombre, slug_normalizado, preferente, fuente_id)
			select v_arq, x.nombre, x.slug, false, v_dc16
			from (values ('Octavilla aguda', 'octavilla_aguda'),
				('Octavilla italiana', 'octavilla_italiana')) as x(nombre, slug)
			where not exists (
				select 1 from public.denominaciones_metricas
				where arquitectura_id = v_arq and slug_normalizado = x.slug
			);
		end if;
	end loop;

	-- -------------------------------------------------------------------- Los nombres
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Octava italiana', 'octava_italiana', false, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'octava_italiana'
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_dc16::text, 's. v. «octava aguda», «octavilla aguda» y «octavilla»',
			'La define como ocho versos de nueve o más sílabas en dos semiestrofas simétricas, en '
			|| 'que el cuarto y el octavo llevan rima aguda consonante o asonante, mientras «los '
			|| 'restantes versos no se ajustan a un esquema fijo de rima, e incluso pueden quedar '
			|| 'algunos sueltos». La octavilla aguda es la misma en ocho sílabas o menos. Registra '
			|| 'octava italiana y octavilla italiana como otros nombres, y la sitúa: forma muy usada '
			|| 'en el Romanticismo, de carácter ligero, «muy popular a finales del siglo XVIII y '
			|| 'durante el siglo XIX», que se acomoda bien al canto y abunda en canciones de '
			|| 'carácter arcádico y en himnos patrióticos. Recoge también el juicio de Antonio '
			|| 'Machado, que la llamó «estrofa de bazar de rimas hechas».'],
		array[v_dc14::text, 'pp. 205 y ss.',
			'La incluye en su recuento de las estrofas de ocho versos —«la copla de arte menor, la '
			|| 'copla castellana, la octava real, la octava y la octavilla agudas»— y precisa que '
			|| 'cuando la octava aguda va en versos de arte menor se llama octavilla aguda u octava '
			|| 'italiana.'],
		array[v_jauralde::text, 'Apartado «Octavillas y octavas»',
			'La fecha con precisión: «durante el siglo XVIII se incorpora al repertorio la octavilla '
			|| 'aguda, en variedades octosilábicas, heptasilábicas y pentasilábicas sobre todo: los '
			|| 'finales de cada semiestrofa (versos 4.º y 8.º) riman en aguda entre sí». Añade que '
			|| '«la modalidad aguda se extendió a otras muchas variedades estróficas, como la '
			|| 'sextilla y la décima», y también a estrofas de arte mayor. Ejemplifica la '
			|| 'octosilábica con *El reo de muerte* de Espronceda, que llama «octavilla de '
			|| 'octosílabos o copla castellana aguda», y la heptasilábica con *La orgía* de Zorrilla. '
			|| 'Señala que las estrofas agudas decayeron en el Modernismo.'],
		array[v_quilis::text, '§ 5.4.7.4',
			'No la separa de las demás estrofas de ocho versos: las trata todas bajo «octavilla», '
			|| 'sin epígrafe ni nombre propio para la aguda.']
	] loop
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		select v_fila[1]::uuid, v_forma, v_fila[2], v_fila[3], 'alta'
		where not exists (
			select 1 from public.afirmaciones_fuentes_metricas
			where forma_id = v_forma and fuente_id = v_fila[1]::uuid
		);
	end loop;

	-- ------------------------------------------------------------------ El vínculo
	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_castellana, 'contrasta_con',
		'Las dos reparten ocho versos en dos semiestrofas de cuatro, y se separan por lo que su '
		|| 'norma fija: la castellana fija las cuatro rimas y no dice nada del acento; la aguda fija '
		|| 'solo los versos de cierre —que riman entre sí y en agudo— y deja libres los demás. '
		|| 'Cuando una octavilla aguda va en octosílabos, la tradición llega a llamarla copla '
		|| 'castellana aguda.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_castellana)
			or (forma_origen_id = v_castellana and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 6 then
		raise exception 'La octava aguda tiene % arquitecturas, no las seis.', v_n;
	end if;

	-- Las doce disposiciones fijan dos posiciones y dejan sueltas las otras seis.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where a.forma_id = v_forma
		and (select count(*) from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id and p.suelto) = 6
		and (select count(*) from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id and p.clase_rima = 'a') = 2;
	if v_n <> 12 then
		raise exception 'Solo % de las doce disposiciones dibujan la figura aguda.', v_n;
	end if;

	-- Y las seis arquitecturas declaran el rasgo que da nombre a la forma.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.forma_id = v_forma and ar.rasgo_id = v_rasgo and ar.modalidad = 'definitoria'
		and ar.valor_id = v_agudo and ar.posiciones_max = 2;
	if v_n <> 6 then
		raise exception 'Solo % arquitecturas declaran el final agudo como definitorio.', v_n;
	end if;

	if public.get_forma_metrica_publica('octava_aguda') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la octava aguda no responde.';
	end if;
end $$;

commit;
