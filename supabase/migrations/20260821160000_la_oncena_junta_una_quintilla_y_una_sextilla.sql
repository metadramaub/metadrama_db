-- La oncena junta una quintilla y una sextilla
--
-- Quinta de las seis. Es la estrofa de once versos, y es el hueco que el pendiente había visto
-- bien. Como la novena, reparte sus versos en dos miembros de distinta extensión y se modela igual
-- que ella: cada miembro reutiliza la arquitectura de la forma que lo realiza, y las combinaciones
-- documentadas quedan en las fuentes, porque la estrofa no fija ninguna.
--
-- Navarro § 67: «**Oncena, 5-6**: la primera semiestrofa es de ordinario una quintilla `abaab`;
-- los seis octosílabos de la segunda parte se combinan de manera variable; en la mayor parte de los
-- casos forman otra quintilla con un verso adicional. La estrofa consta generalmente de cuatro
-- rimas». Y el *Diccionario* lo dice como norma negativa: «**no hay una forma fija de estrofa de
-- once versos**. Se da en la poesía del siglo XV, normalmente subdividida en dos semiestrofas —una
-- de cinco y otra de seis versos—».
--
-- **El quiebro no es aquí una licencia sino lo corriente.** Navarro § 68: «la estrofa de once con
-- quebrados **fue más corriente que la de octosílabos plenos**», con el *Claro escuro* de Juan de
-- Mena como modelo —`abaab:cdecde`, con los quebrados en el octavo y el onceno— repetido por
-- Álvarez Gato, Gómez Manrique y Tapia. Por eso el rasgo va como habitual y no como admitido.
--
-- **Y llega al Siglo de Oro.** Jauralde: «se encuentra durante todo el periodo medieval y **llega
-- hasta Cervantes** (Canción de Arsindo, en *La Galatea*, III)».

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_quintilla uuid;
	v_quintilla_arq uuid;
	v_sextilla uuid;
	v_sextilla_arq uuid;
	v_novena uuid;
	v_metrico uuid;
	v_espanola uuid := 'bf56b9c7-1261-41db-8a0c-d82529f88dd3';
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1';
	v_octosilabo uuid := '82bd7a89-675e-41a9-9324-538589731000';
	v_tetrasilabo uuid := 'b7d3c277-feaf-4f2f-905a-cfddc45773c4';
	v_rasgo_quebrado uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_dc16 uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59';
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff';
	v_n integer;
	v_fila text[];

	c_definicion constant text :=
		'Estrofa de once versos octosílabos repartidos en dos miembros de distinta extensión: una '
		|| 'quintilla y una sextilla, en ese orden o en el inverso. La quintilla es de ordinario '
		|| '`abaab`; los seis versos del otro miembro se combinan de manera variable y en la mayor '
		|| 'parte de los casos forman otra quintilla con un verso añadido. La estrofa lleva '
		|| 'generalmente cuatro clases de rima consonante, y se documentan también de dos, de tres '
		|| 'y de cinco —estas últimas cuando el miembro de seis se organiza en tercetos '
		|| 'correlativos—. **No tiene una disposición fija**: lo que la define es el reparto en '
		|| 'cinco y seis. Con verso quebrado fue más corriente que en octosílabos plenos. Se '
		|| 'practicó desde el siglo XV, sin llegar a la popularidad de las estrofas de ocho, diez y '
		|| 'doce versos, y alcanza el Siglo de Oro: Cervantes la emplea en la canción de Arsindo, '
		|| 'en *La Galatea*.';
begin
	select forma_id into v_quintilla from public.formas_metricas where slug = 'quintilla';
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';
	select forma_id into v_novena from public.formas_metricas where slug = 'novena';
	select arquitectura_id into v_quintilla_arq from public.arquitecturas_forma
	where forma_id = v_quintilla and slug = 'octosilabica_consonante';
	select arquitectura_id into v_sextilla_arq from public.arquitecturas_forma
	where forma_id = v_sextilla and slug = 'octosilabica';
	select rasgo_id into v_rasgo_quebrado from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_quintilla_arq is null or v_sextilla_arq is null or v_novena is null
		or v_rasgo_quebrado is null
	then
		raise exception 'Falta la quintilla octosilábica, la sextilla octosilábica o la novena.';
	end if;

	if exists (select 1 from public.formas_metricas where slug = 'oncena') then
		select forma_id into v_forma from public.formas_metricas where slug = 'oncena';
	else
		insert into public.formas_metricas
			(slug, nombre, definicion, nivel_estructural, tipo_registro, activo)
		values ('oncena', 'Oncena', c_definicion, 'estrofa', 'forma', true)
		returning forma_id into v_forma;
	end if;

	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	insert into public.formas_tradiciones (forma_id, tradicion_id)
	values (v_forma, v_espanola) on conflict do nothing;

	-- ------------------------------------------------- Las dos arquitecturas, por orden
	foreach v_fila slice 1 in array array[
		array['quintilla_sextilla', 'Quintilla + sextilla', 'habitual', '1',
			'Cinco y seis, que es el orden corriente. La quintilla abre, de ordinario en `abaab`, y '
			|| 'los seis versos que siguen se combinan de manera variable: lo más frecuente es que '
			|| 'formen otra quintilla con un verso añadido.'],
		array['sextilla_quintilla', 'Sextilla + quintilla', 'admitida', '2',
			'El orden inverso, seis y cinco, menos frecuente. Se documenta con dos rimas y con '
			|| 'cuatro, y con los quiebros en el tercer y el sexto verso.']
	] loop
		select arquitectura_id into v_arq from public.arquitecturas_forma
		where forma_id = v_forma and slug = v_fila[1];

		if v_arq is null then
			insert into public.arquitecturas_forma (
				forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
				tipo_rima_id, activo, orden, unidad_versos_min, unidad_versos_max
			)
			values (v_forma, v_fila[1], v_fila[2], v_fila[5], v_fila[1] = 'quintilla_sextilla',
				true, v_fila[3], v_consonante, true, v_fila[4]::integer, 11, 11)
			returning arquitectura_id into v_arq;
		else
			update public.arquitecturas_forma set descripcion = v_fila[5]
			where arquitectura_id = v_arq;
		end if;

		-- La medida, con su quebrado
		select esquema_metrico_id into v_metrico from public.esquemas_metricos
		where arquitectura_id = v_arq and slug = '8-repetido';
		if v_metrico is null then
			insert into public.esquemas_metricos
				(arquitectura_id, tipo_secuencia, slug, medida_uniforme)
			values (v_arq, 'ciclo', '8-repetido', false)
			returning esquema_metrico_id into v_metrico;

			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, alternativa)
			values (v_metrico, 1, v_octosilabo, 1);

			insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden, rol)
			values (v_metrico, v_octosilabo, 1, 'dominante'), (v_metrico, v_tetrasilabo, 2, 'quebrado');
		end if;

		-- Los dos miembros, cada uno reutilizando la forma que lo realiza
		insert into public.estructuras_secciones (
			arquitectura_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id
		)
		select v_arq, 'quintilla', 'quintilla', 'Quintilla',
			case when v_fila[1] = 'quintilla_sextilla' then 1 else 2 end,
			1, 1, 5, 5, v_quintilla_arq
		where not exists (
			select 1 from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = 'quintilla'
		);

		insert into public.estructuras_secciones (
			arquitectura_id, tipo_seccion, slug, nombre, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id,
			nota
		)
		select v_arq, 'sextilla', 'sextilla', 'Sextilla',
			case when v_fila[1] = 'quintilla_sextilla' then 2 else 1 end,
			1, 1, 6, 6, v_sextilla_arq,
			'Es el miembro que más varía. Lo corriente es que sus seis versos formen una quintilla '
			|| 'con uno añadido; cuando se organizan en tercetos correlativos, la estrofa llega a '
			|| 'cinco clases de rima.'
		where not exists (
			select 1 from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = 'sextilla'
		);

		-- El quiebro, que aquí es lo corriente
		insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
		select v_arq, v_rasgo_quebrado, 'habitual',
			case when v_fila[1] = 'quintilla_sextilla'
				then 'La estrofa de once con quebrados fue más corriente que la de octosílabos '
					|| 'plenos. En el modelo que fijó la forma caen en el octavo verso y en el '
					|| 'undécimo, los que cierran cada terceto del miembro de seis.'
				else 'Con este orden los quiebros se documentan en el tercer verso y en el sexto.'
			end
		where not exists (
			select 1 from public.arquitectura_rasgos
			where arquitectura_id = v_arq and rasgo_id = v_rasgo_quebrado
		);
	end loop;

	-- -------------------------------------------------------------------- El nombre
	insert into public.denominaciones_metricas
		(forma_id, nombre, slug_normalizado, preferente, fuente_id)
	select v_forma, 'Undécima', 'undecima', false, v_dc16
	where not exists (
		select 1 from public.denominaciones_metricas
		where forma_id = v_forma and slug_normalizado = 'undecima'
	);

	-- ------------------------------------------------------------------- Las fuentes
	foreach v_fila slice 1 in array array[
		array[v_navarro::text, '§§ 67 y 68',
			'La define bajo «copla mixta»: «oncena, 5-6: la primera semiestrofa es de ordinario una '
			|| 'quintilla `abaab`; los seis octosílabos de la segunda parte se combinan de manera '
			|| 'variable; en la mayor parte de los casos forman otra quintilla con un verso '
			|| 'adicional». Da cuatro rimas como lo general y `abaab:cdccdd` como variedad frecuente, '
			|| 'en el *Sermón trabado* de Íñigo de Mendoza; registra también de dos, tres y cinco '
			|| '—las cinco cuando el miembro de seis se organiza en tercetos correlativos— y la '
			|| 'disposición inversa 6-5, con dos rimas en Juan de Mena (`ababba:babba`) y con cuatro '
			|| 'en Álvarez Gato (`abaaab:cdccd`). En su capítulo del pie quebrado añade lo decisivo: '
			|| '«la estrofa de once con quebrados fue más corriente que la de octosílabos plenos», '
			|| 'con el *Claro escuro* de Juan de Mena como modelo —`abaab:cdecde`, quebrados en el '
			|| 'octavo y el onceno—, repetido por Álvarez Gato, Gómez Manrique y Tapia. Precisa que '
			|| 'no llegó a igualar la popularidad de las estrofas de ocho, diez y doce versos, y que '
			|| 'su cultivo no prosperó hasta después de mediados del siglo XV.'],
		array[v_dc16::text, 's. v. «undécima» y «oncena»',
			'La registra como «undécima», con «oncena» como otro término, y la define por lo que no '
			|| 'tiene: «no hay una forma fija de estrofa de once versos. Se da en la poesía del siglo '
			|| 'XV, normalmente subdividida en dos semiestrofas —una de cinco y otra de seis '
			|| 'versos—». Añade que es más difícil encontrarla como estancia de la canción italiana, '
			|| 'y ejemplifica con Garci Sánchez de Badajoz.'],
		array[v_jauralde::text, 'Apartado «Oncena»',
			'Explica su formación: «la copla empezó por estructurarse como quintilla más sextilla '
			|| '(5-6), pero casi siempre necesitó de las cuatro rimas, como mínimo, para conjuntar '
			|| 'sus versos», y describe la realización con quiebros —quintilla `abaab` más sextilla '
			|| 'de pie quebrado `cdecde`— en Francisco de Costana, Tapia y Garci Sánchez de Badajoz, '
			|| 'donde «los versos quebrados se encargan del descenso climático del poema». La fecha '
			|| 'con precisión para este catálogo: «se encuentra durante todo el periodo medieval y '
			|| 'llega hasta Cervantes (Canción de Arsindo, en *La Galatea*, III)».'],
		array[v_dc14::text, 'Índice de estrofas',
			'No le dedica epígrafe. Su recorrido de las combinaciones estróficas no incluye la de '
			|| 'once versos, que sí registra en el *Diccionario* bajo «undécima».'],
		array[v_quilis::text, '§§ 5.4.8 y siguientes',
			'No registra las estrofas de once versos. Su recorrido pasa de las de diez a las de doce '
			|| 'sin epígrafe intermedio.'],
		array[v_mb::text, 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas»',
			'No la registran. Su repertorio no tiene ninguna estrofa de once versos, y lo que no '
			|| 'encaja lo reúnen bajo «coplas», las estrofas cortas que no se incluyen en '
			|| 'definiciones más específicas.']
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
	select v_forma, v_quintilla, 'compuesta_por',
		'La quintilla es el miembro menor de la oncena y el que menos varía: va de ordinario en '
		|| '`abaab`, abriendo la estrofa en el orden corriente y cerrándola en el inverso.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_quintilla
	);

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_sextilla, 'compuesta_por',
		'Los seis versos del miembro mayor se combinan de manera variable, y es donde la oncena '
		|| 'admite más soluciones: una quintilla con un verso añadido, lo más frecuente, o dos '
		|| 'tercetos correlativos, que llevan la estrofa a cinco rimas.'
	where not exists (
		select 1 from public.forma_relaciones
		where forma_origen_id = v_forma and forma_destino_id = v_sextilla
	);

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota)
	select v_forma, v_novena, 'contrasta_con',
		'Las dos reparten octosílabos consonantes en dos miembros de distinta extensión, y se '
		|| 'separan por cuáles: la novena junta una redondilla con una quintilla, y la oncena una '
		|| 'quintilla con una sextilla. Las dos admiten los dos órdenes y las dos admiten quiebro, '
		|| 'que en la oncena es además lo corriente.'
	where not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_forma and forma_destino_id = v_novena)
			or (forma_origen_id = v_novena and forma_destino_id = v_forma)
	);

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where forma_id = v_forma and activo;
	if v_n <> 2 then
		raise exception 'La oncena tiene % arquitecturas, no las dos.', v_n;
	end if;

	-- Los cuatro miembros suman once versos en cada arquitectura y reutilizan su forma.
	select count(*) into v_n
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.arquitectura_referenciada_id is not null;
	if v_n <> 4 then
		raise exception 'Solo % de los cuatro miembros reutilizan la forma que los realiza.', v_n;
	end if;

	if exists (
		select 1 from public.arquitecturas_forma a
		where a.forma_id = v_forma
			and (select coalesce(sum(s.versos_min), 0) from public.estructuras_secciones s
				where s.arquitectura_id = a.arquitectura_id) <> 11
	) then
		raise exception 'Alguna arquitectura de la oncena no suma once versos.';
	end if;

	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La oncena cita % fuentes, no las seis.', v_n;
	end if;

	if public.get_forma_metrica_publica('oncena') -> 'formas' = '[]'::jsonb then
		raise exception 'La ficha de la oncena no responde.';
	end if;
end $$;

commit;
