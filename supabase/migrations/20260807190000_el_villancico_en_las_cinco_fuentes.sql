-- Cinco de las seis fuentes autorizadas tratan el villancico; Morley y Bruerton no lo
-- incluyen en su repertorio de formas. Todas coinciden en la articulación de cabeza,
-- mudanza y vuelta, pero Navarro Tomás documenta tanto la evolución histórica de esas
-- partes como una modalidad moderna en que la copla precede al estribillo.
--
-- La formalización abierta de la vuelta y el alcance exacto de la modalidad moderna se
-- revisarán junto con los demás casos difíciles. Sí se incorpora ya la mudanza asonantada
-- abcb, posibilidad concreta que faltaba en el repertorio y en las preguntas del editor.

begin;

do $$
declare
	v_forma uuid;
	v_inicial uuid;
	v_posterior uuid;
	v_asonante uuid;
	v_abcb uuid;
	v_arq uuid;
	v_grupo record;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_n integer;
begin
	select forma_id into v_forma
	from public.formas_metricas
	where slug = 'villancico';

	select arquitectura_id into v_inicial
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_inicial';

	select arquitectura_id into v_posterior
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'estribillo_tras_primera_copla';

	select termino_id into v_asonante
	from public.vocabularios
	where categoria = 'tipo_rima' and termino = 'asonante';

	if num_nonnulls(
		v_forma, v_inicial, v_posterior, v_asonante,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 10 then
		raise exception 'Falta el villancico vigente, una arquitectura, la asonancia o una fuente autorizada';
	end if;

	select count(*) into v_n
	from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	update public.formas_metricas
	set definicion = 'Forma compuesta de arte menor articulada por un estribillo y una o más coplas. En su configuración clásica, un estribillo inicial o cabeza de dos a cuatro versos abre la composición; cada copla contiene una mudanza, normalmente de cuatro versos organizados en dos miembros simétricos, y una vuelta cuyo primer verso enlaza con la rima final de la mudanza y cuyos versos finales recuperan la rima de la cabeza. El estribillo puede repetirse total o parcialmente después de cada copla. Predominan los octosílabos y hexasílabos. La tradición documenta ampliaciones y supresiones de estas partes, además de una modalidad moderna en la que una cuarteta precede al estribillo.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'El estribillo inicial funciona como cabeza. Le siguen una o más coplas, formadas por mudanza y vuelta, y las repeticiones totales o parciales del estribillo.',
		updated_at = now()
	where arquitectura_id = v_inicial;

	update public.arquitecturas_forma
	set descripcion = 'Modalidad moderna en la que una primera copla precede a la primera aparición del estribillo. Navarro Tomás documenta como realización general una cuarteta octosilábica seguida, sin enlace ni vuelta, por un estribillo en cuarteta hexasílaba.',
		updated_at = now()
	where arquitectura_id = v_posterior;

	-- Navarro Tomás registra, junto a abba y abab, la mudanza simplemente asonantada abcb.
	foreach v_arq in array array[v_inicial, v_posterior]
	loop
		insert into public.esquemas_rima (
			arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
			modalidad, tipo_secuencia, descripcion, estado_revision
		)
		select v_arq, 'abcb', 'Mudanza asonantada', 'abcb', v_asonante, 'seccion',
			'admitida', 'secuencia',
			'El segundo y el cuarto verso comparten asonancia; los demás no se vinculan a ella.',
			'revisada'
		where not exists (
			select 1 from public.esquemas_rima
			where arquitectura_id = v_arq and slug = 'abcb'
		);
	end loop;

	for v_grupo in
		select g.grupo_eleccion_id, g.arquitectura_id
		from public.grupos_eleccion_metrica g
		where g.arquitectura_id in (v_inicial, v_posterior)
			and g.dimension = 'rima'
			and g.activo
	loop
		select esquema_rima_id into v_abcb
		from public.esquemas_rima
		where arquitectura_id = v_grupo.arquitectura_id and slug = 'abcb';

		insert into public.opciones_eleccion_metrica (
			grupo_eleccion_id, slug, nombre, descripcion, esquema_rima_id, orden, activo
		)
		select v_grupo.grupo_eleccion_id, 'abcb', 'abcb — cuarteta asonantada',
			'El segundo y el cuarto verso comparten asonancia.', v_abcb, 3, true
		where not exists (
			select 1 from public.opciones_eleccion_metrica
			where grupo_eleccion_id = v_grupo.grupo_eleccion_id and slug = 'abcb'
		);
	end loop;

	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (v_inicial, v_posterior);

	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_quilis, v_forma, '§ 6.3.1',
		 'Sitúa el villancico desde la Edad Media y señala su auge entre el siglo XVI y el Barroco. Lo describe en octosílabos o hexasílabos, con estribillo y pies variables de seis o siete versos cuyos finales recuperan total o parcialmente la rima del estribillo. Al compararlo con el zéjel, identifica la redondilla como mudanza característica y advierte variación en la extensión del estribillo.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 93, 145, 212, 274, 446 y 494; apartado final «Villancico»',
		 'Reconstruye su evolución desde la cantiga medieval y documenta una gran variedad histórica. Presenta como modelo preferente del siglo XVI el estribillo de tres versos, la mudanza en redondilla y el enlace, vuelta y represa; junto a abba registra abab y la forma asonantada abcb. Recoge estribillos de dos a siete versos, mudanzas excepcionales de seis, ampliación o supresión del enlace y la vuelta, repeticiones parciales o totales y, como modalidad moderna general, una cuarteta octosilábica seguida por un estribillo en cuarteta hexasílaba.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 211-212',
		 'Define una forma fija con cabeza inicial de dos, tres o cuatro versos y uno o más pies. Cada pie se divide en dos mudanzas simétricas y una vuelta de tres o cuatro versos: el primero enlaza con la rima final de la mudanza y los restantes, o al menos el último, con la cabeza. Señala la estabilidad de la redondilla o cuarteta de la mudanza, la variación de cabeza y vuelta, la repetición del estribillo y el predominio de octosílabos y hexasílabos.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 's. v. «villancico» y «vuelta»',
		 'Ofrece la misma estructura canónica de cabeza de dos a cuatro versos, dos mudanzas simétricas y vuelta de tres o cuatro. Precisa la relación de rimas del enlace y de la vuelta con mudanza y cabeza, la repetición del estribillo cuando hay varias estrofas, la estabilidad de la redondilla o cuarteta central y la variabilidad del comienzo y el final.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartado «Estrofas con estribillo»',
		 'Subraya que villancico, canción trovadoresca, zéjel y letrilla pueden coincidir en sus elementos y requerir tema, tono y época para distinguirse. Resume el villancico en la secuencia cabeza, estrofa y repetición total o parcial de la cabeza, pero advierte que ese molde general es demasiado amplio: la clasificación métrica debe atender a la forma de la estrofa y excluir, por ejemplo, la mudanza monorrima propia del zéjel.',
		 'alta', 'revisada');

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 5 then
		raise exception 'El Villancico debe tener cinco afirmaciones de fuente, no %', v_n;
	end if;

	select count(*) into v_n
	from public.esquemas_rima
	where arquitectura_id in (v_inicial, v_posterior) and slug = 'abcb';
	if v_n <> 2 then
		raise exception 'Cada arquitectura del Villancico debe admitir abcb';
	end if;

	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
	where g.arquitectura_id in (v_inicial, v_posterior)
		and g.dimension = 'rima' and g.activo and o.slug = 'abcb' and o.activo;
	if v_n <> 3 then
		raise exception 'Las tres preguntas de mudanza deben ofrecer abcb, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
