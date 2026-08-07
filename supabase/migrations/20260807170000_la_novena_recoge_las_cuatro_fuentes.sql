-- La revisión anterior de la Novena había conservado solo a Domínguez Caparrós 2014.
-- No era una selección bibliográfica defendible: Navarro Tomás, el Diccionario y Jauralde
-- también la tratan expresamente y sus afirmaciones deben constar aunque coincidan en parte.
--
-- Las fuentes distinguen además dos alcances que el dato actual mezcla: «novena» puede
-- designar cualquier estrofa de nueve versos, mientras «copla novena» nombra la realización
-- histórica de redondilla y quintilla. La separación se aplaza hasta diseñar la representación
-- computable de las formas abiertas; por ahora se corrige la definición sin presentar las dos
-- arquitecturas existentes como repertorio exhaustivo.

begin;

do $$
declare
	v_forma uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_caparros uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_diccionario uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_total integer;
begin
	select forma_id into v_forma
	from public.formas_metricas
	where slug = 'novena';

	if v_forma is null then
		raise exception 'No se encontró la forma Novena';
	end if;

	select count(*) into v_total
	from public.fuentes_metricas
	where fuente_id in (v_navarro, v_caparros, v_diccionario, v_jauralde);

	if v_total <> 4 then
		raise exception 'Falta alguna de las cuatro fuentes que tratan la Novena';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de nueve versos. Sus realizaciones no comparten necesariamente metro, rima ni articulación interna. Entre las formas históricas más caracterizadas se encuentra la copla novena, que combina una redondilla y una quintilla, normalmente en orden 4+5 y también 5+4.',
		updated_at = now()
	where forma_id = v_forma;

	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and fuente_id in (v_navarro, v_caparros, v_diccionario, v_jauralde);

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(
			v_navarro,
			v_forma,
			'§ «Novena, 4-5» y § «Copla de pie quebrado: Novena»',
			'Describe la novena cancioneril como una redondilla seguida de una quintilla: la redondilla suele ser *abba* y la quintilla admite sus distintas variantes. Antes de 1450 documenta dos o tres rimas que enlazan ambas partes y, más tarde, cuatro rimas independientes; registra también el orden 5+4 y realizaciones con versos quebrados.',
			'alta',
			'revisada'
		),
		(
			v_caparros,
			v_forma,
			'p. 204',
			'Define la novena como una estrofa de nueve versos y advierte que no existe otro rasgo común a todas sus realizaciones. Documenta combinaciones de estrofas de cuatro y cinco versos, incluso sin rimas compartidas entre las semiestrofas, y mezclas de versos largos y quebrados.',
			'alta',
			'revisada'
		),
		(
			v_diccionario,
			v_forma,
			's. v. «novena»',
			'Define la novena como estrofa de nueve versos sin más rasgo común necesario. Señala que puede formarse uniendo estrofas de cuatro y cinco versos, añadiendo un verso a una octava o suprimiéndolo de una décima, y que puede combinar octosílabos con tetrasílabos o endecasílabos con heptasílabos.',
			'alta',
			'revisada'
		),
		(
			v_jauralde,
			v_forma,
			'§ 2.5.7 y § «Estrofas de nueve versos»',
			'Denomina «copla novena» a la unión de redondilla y quintilla y la documenta como forma abundante en los cancioneros del siglo XV, con *abba:cdccd* como realización destacada. Registra además el orden 5+4, versos quebrados y otras novenas de metro y organización diferentes.',
			'alta',
			'revisada'
		);

	select count(*) into v_total
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and fuente_id in (v_navarro, v_caparros, v_diccionario, v_jauralde)
		and estado_revision = 'revisada';

	if v_total <> 4 then
		raise exception 'La Novena debe conservar cuatro afirmaciones revisadas y conserva %', v_total;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
