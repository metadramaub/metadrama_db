-- La canción enseña por dentro la estancia
--
-- Quince de sus veintinueve textos no se podían leer: trece notas de posición métrica que el
-- SQL público ni siquiera envía, la descripción del esquema métrico de la estancia regular y la
-- nota de su posición séptima. Y lo que decían era justo lo que hacía falta para entender las
-- tres bandas que la ficha dibuja —fronte, eslabón, sirima— sin explicar nunca qué son.
--
-- Así que la estructura sube a donde se lee: la descripción de la arquitectura la cuenta en
-- corrido, y la estancia regular declara por fin sus partes —fronte con sus dos pies, eslabón y
-- sirima—, que hasta hoy solo existían como rótulo de un dibujo. El eslabón recupera además su
-- otro nombre, «chiave».
--
-- El esquema de rima **sigue colgando de la estancia entera y debe seguir así**: la clase `c`
-- enlaza el último verso de la fronte con el eslabón, de modo que partirlo rompería la
-- disposición. Las secciones nuevas describen el interior, no lo trocean.
--
-- La definición dejaba fuera una de las tres arquitecturas al decir «consonantes», y decía dos
-- veces lo que la ficha imprime como grado de determinación. Ahora dice qué es una estancia.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición de la forma
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Composición formada por un mínimo de tres estancias de igual estructura, que combinan heptasílabos y endecasílabos consonantes, y que suele cerrarse con un fragmento de estancia más breve llamado remate, envío o *commiato*. Todas las estancias repiten la misma distribución de medidas y el mismo esquema de rima, que la primera establece; la estancia admite en cambio muy distintas extensiones y disposiciones.';
	v_nuevo constant text :=
		'Composición en estancias: una estrofa larga de heptasílabos y endecasílabos que el poeta inventa para cada canción y que, fijada por la primera, vuelve idéntica hasta el final. Cierra un fragmento de estancia más breve —el remate, envío o *commiato*— en el que el poeta suele dirigirse a la propia canción. «Canción» a secas designa esta forma italiana, no la medieval del siglo XV.';
begin
	select forma_id into v_forma
	from public.formas_metricas
	where slug = 'cancion_petrarquista' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «cancion_petrarquista».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la canción no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Las tres descripciones de arquitectura
--
-- Las tres estaban dibujadas casi enteras: las cifras, el reparto 7/11, el régimen, la notación
-- y el «la primera declara» que la ficha imprime como grado de determinación. Se quedan con lo
-- que solo ellas pueden decir: la estructura interna de la estancia regular, de dónde sale la
-- horquilla 5–20 y por qué existe una canción sin rima.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;

	for fila in
		select *
		from (values
			(
				'regular_13_versos',
				'Estancias de trece versos con distribución métrica y esquema consonante fijos, abCabC:cdeeDfF. Es la realización más frecuente en el corpus dramático.',
				'Es la realización más frecuente: la estancia que Garcilaso tomó de Petrarca para su segunda égloga. Su fronte son dos pies de tres versos, y el heptasílabo séptimo rima con el último verso de la fronte pero abre ya la sirima —de ahí que se llame eslabón o *chiave*—.'
			),
			(
				'estancias_consonantes_variables',
				'Tres o más estancias de cinco a veinte versos. La primera declara su distribución de heptasílabos y endecasílabos y su esquema consonante, y las demás los repiten.',
				'El caso general: la estancia se inventa para cada canción y no hay dos iguales. Se admite desde cinco versos, que es el mínimo que arroja el recuento sobre el teatro; los tratados que describen la canción culta no bajan de nueve.'
			),
			(
				'sin_rima_con_pareado_final',
				'Estancias de heptasílabos y endecasílabos cuyo cuerpo queda sin rima y que cierran con un pareado consonante.',
				'No la recogen los tratados de métrica, que describen la canción como forma siempre rimada: se identificó contando las estrofas sin rima del teatro del Siglo de Oro.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» de la canción.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de cancion/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La afirmación de Morley y Bruerton dice de dónde sale la canción sin rima
--
-- Es la única de las seis fuentes que la describe, y lo hace remitiendo a un estudio propio
-- sobre las estrofas sin rima. Ese localizador es justamente lo que explica por qué las otras
-- cinco callan: la forma se identificó contando, no leyendo tratados.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'Describen la canción como versos de siete y once sílabas agrupados en estrofas de cinco a veinte versos, con un tipo de rima fijo e idéntico en cada estrofa de un mismo pasaje, y advierten que rara vez se encuentra un pasaje de rima mezclada. Llaman regular al tipo más corriente en Lope de Vega, de trece versos, abCabC:cdeeDfF, y señalan que rara vez la canción es toda de endecasílabos. Registran aparte la canción sin rima: versos de siete y once sílabas en estrofas sin rima, excepto un pareado final.';
	v_nuevo constant text :=
		'Describen la canción como versos de siete y once sílabas agrupados en estrofas de cinco a veinte versos, con un tipo de rima fijo e idéntico en cada estrofa de un mismo pasaje, y advierten que rara vez se encuentra un pasaje de rima mezclada. Llaman regular al tipo más corriente en Lope de Vega, de trece versos, abCabC:cdeeDfF, y señalan que rara vez la canción es toda de endecasílabos. Registran aparte la canción sin rima —versos de siete y once sílabas en estrofas sin rima, excepto un pareado final—, y remiten para ella a un estudio propio sobre las estrofas sin rima en las comedias de Lope, publicado en Coimbra en 1934.';
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;

	if v_id is null then
		raise exception 'No existe la afirmación de Morley y Bruerton sobre la canción.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación de Morley y Bruerton no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · Las trece notas de posición métrica
--
-- Siete son el rótulo de la banda que la rejilla dibuja debajo —«Sirima.» seis veces y el
-- eslabón—; las otras seis dicen que la fronte son dos pies, que `abCabC` dibuja como dos
-- tríadas idénticas y que la descripción de la arquitectura cuenta ahora en prosa. Y ninguna
-- de las trece llegaba al navegador: la función pública no envía esta columna.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Primer pie de la fronte.',
		'Segundo pie de la fronte.',
		'Eslabón o chiave; inicia sintácticamente la sirima.',
		'Sirima.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;

	select count(*) into v_ajenas
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and p.nota is not null
		and not (p.nota = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La canción tiene % notas de posición métrica distintas de las esperadas.', v_ajenas;
	end if;

	update public.esquema_metrico_posiciones p
	set nota = null
	from public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = p.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and p.nota is not null;

	select count(*) into v_restantes
	from public.esquema_metrico_posiciones p
	join public.esquemas_metricos em using (esquema_metrico_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and p.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de posición métrica en la canción.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · Las tres descripciones de esquema métrico
--
-- La de la estancia regular sube a la descripción de su arquitectura. Las otras dos cuentan
-- cómo se rellena el formulario —«se registra»— y su contenido lo imprime la fila «Medida».
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Dos pies de tres versos forman la fronte; el heptasílabo séptimo actúa como eslabón y abre la sirima.',
		'Cada posición de la primera estancia se registra como heptasílaba o endecasílaba; la distribución se repite en las demás estancias.',
		'Cada posición de la estancia se registra como heptasílaba o endecasílaba.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;

	select count(*) into v_ajenas
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma
		and em.descripcion is not null
		and not (em.descripcion = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La canción tiene % descripciones de esquema métrico distintas de las esperadas.', v_ajenas;
	end if;

	update public.esquemas_metricos em
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = em.arquitectura_id
		and a.forma_id = v_forma
		and em.descripcion is not null;

	select count(*) into v_restantes
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	where a.forma_id = v_forma and em.descripcion is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % descripciones de esquema métrico en la canción.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · Lo que la fila «Rima» decía tres veces
--
-- El grado de determinación ya dice «Fijado por la primera unidad · las siguientes repiten el
-- patrón», y debajo venían seguidas la descripción de la restricción y la del esquema diciendo
-- lo mismo. La restricción estructurada `identidad_entre_repeticiones` **se conserva**: sin
-- descripción propia, la ficha imprime su redacción por tipo, «La disposición, sea cual sea,
-- vuelve idéntica en cada repetición».
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_actual text;
	v_esperada constant text :=
		'El esquema concreto es libre dentro de la estancia, pero debe repetirse idénticamente en todas las estancias de la canción.';
	v_restriccion constant text :=
		'El esquema concreto es libre, pero vuelve idéntico en todas las estancias de la canción.';
	v_ajenas integer;
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'cancion_petrarquista'
		and a.slug = 'estancias_consonantes_variables'
		and er.slug = 'consonante-repetido';

	if v_esquema is null then
		raise exception 'No existe el esquema «consonante-repetido» de la canción.';
	end if;

	select descripcion into v_actual from public.esquemas_rima where esquema_rima_id = v_esquema;
	if v_actual is not null and v_actual is distinct from v_esperada then
		raise exception 'La descripción del esquema «consonante-repetido» no es la esperada. Dice: %', v_actual;
	end if;
	update public.esquemas_rima set descripcion = null where esquema_rima_id = v_esquema;

	select count(*) into v_ajenas
	from public.esquema_rima_restricciones
	where esquema_rima_id = v_esquema
		and tipo = 'identidad_entre_repeticiones'
		and descripcion is not null
		and descripcion is distinct from v_restriccion;

	if v_ajenas > 0 then
		raise exception 'La restricción de identidad de la canción no tiene la descripción esperada.';
	end if;

	update public.esquema_rima_restricciones
	set descripcion = null
	where esquema_rima_id = v_esquema and tipo = 'identidad_entre_repeticiones';

	-- La restricción no se borra: sin ella la ficha se quedaría sin decir la norma.
	if not exists (
		select 1 from public.esquema_rima_restricciones
		where esquema_rima_id = v_esquema and tipo = 'identidad_entre_repeticiones'
	) then
		raise exception 'La restricción `identidad_entre_repeticiones` ha desaparecido.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 7 · La nota de la sección «Estancia» y la del rasgo «Densidad de rima»
--
-- La primera es `primera_realizacion_define_patron = true` escrito a mano, y la ficha deriva de
-- ese dato tres rótulos en la misma tarjeta. La segunda repetía esa misma identidad y aclaraba
-- de paso qué significa «variables» en el nombre de la arquitectura, que es lo que dice ahora
-- su descripción. Las notas del remate y del final acentual **no se tocan**.
-- ---------------------------------------------------------------------------
do $$
declare
	v_seccion uuid;
	v_actual text;
	v_esperada constant text :=
		'La primera estancia declara la extensión, las medidas por posición y el esquema de rima; las demás los repiten exactamente.';
begin
	select s.seccion_id into v_seccion
	from public.estructuras_secciones s
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'cancion_petrarquista'
		and a.slug = 'estancias_consonantes_variables'
		and s.slug = 'estancia';

	if v_seccion is null then
		raise exception 'No existe la sección «estancia» de estancias_consonantes_variables.';
	end if;

	select nota into v_actual from public.estructuras_secciones where seccion_id = v_seccion;
	if v_actual is not null and v_actual is distinct from v_esperada then
		raise exception 'La nota de la sección «estancia» no es la esperada. Dice: %', v_actual;
	end if;
	update public.estructuras_secciones set nota = null where seccion_id = v_seccion;
end $$;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_esperada constant text :=
		'La distribución elegida se repite en todas las estancias; la variación afecta al patrón, no a la presencia de rima.';
	v_rasgo uuid;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'cancion_petrarquista' and a.slug = 'estancias_consonantes_variables';

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'densidad_de_rima';
	if v_rasgo is null then
		raise exception 'No existe el rasgo «densidad_de_rima».';
	end if;

	select nota into v_actual
	from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;

	if not found then
		raise exception 'La canción variable no declara el rasgo de densidad de rima.';
	end if;

	if v_actual is not null and v_actual is distinct from v_esperada then
		raise exception 'La nota de densidad de rima no es la esperada. Dice: %', v_actual;
	end if;

	update public.arquitectura_rasgos
	set nota = null
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;
end $$;

-- ---------------------------------------------------------------------------
-- 8 · La estancia regular declara sus partes
--
-- Fronte, eslabón y sirima existían solo como rótulo de las bandas que dibuja la rejilla, leído
-- de `esquema_rima_posiciones.seccion`; los dos pies, solo en seis notas que nadie veía. Ahora
-- son secciones, se leen en la fila «Partes» y el eslabón puede llevar su otro nombre.
--
-- Cuelgan de la estancia y **no llevan esquema de rima propio**: la clase `c` enlaza el último
-- verso de la fronte con el eslabón, así que la disposición es de la estancia entera. Como la
-- rejilla solo toma el esqueleto de las secciones raíz, el dibujo no cambia.
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_estancia uuid;
	v_fronte uuid;
	v_eslabon uuid;
	fila record;
	v_versos integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'cancion_petrarquista' and a.slug = 'regular_13_versos' and a.activo;

	if v_arq is null then
		raise exception 'No existe la arquitectura activa cancion/regular_13_versos.';
	end if;

	select seccion_id into v_estancia
	from public.estructuras_secciones
	where arquitectura_id = v_arq and slug = 'estancia';

	if v_estancia is null then
		raise exception 'No existe la sección «estancia» de regular_13_versos.';
	end if;

	-- Las tres partes de la estancia. `orden` las coloca en el mismo orden en que se leen.
	for fila in
		select *
		from (values
			('fronte',  'Fronte',  'fronte',  1, 6),
			('eslabon', 'Eslabón', 'eslabon', 2, 1),
			('sirima',  'Sirima',  'sirima',  3, 6)
		) as t(slug, nombre, tipo, orden, versos)
	loop
		insert into public.estructuras_secciones (
			arquitectura_id, seccion_padre_id, slug, nombre, tipo_seccion, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max
		)
		select v_arq, v_estancia, fila.slug, fila.nombre, fila.tipo, fila.orden, 1, 1, fila.versos, fila.versos
		where not exists (
			select 1 from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = fila.slug
		);
	end loop;

	select seccion_id into v_fronte
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'fronte';

	-- Los dos pies, dentro de la fronte.
	for fila in
		select *
		from (values
			('primer_pie',  'Primer pie',  1),
			('segundo_pie', 'Segundo pie', 2)
		) as t(slug, nombre, orden)
	loop
		insert into public.estructuras_secciones (
			arquitectura_id, seccion_padre_id, slug, nombre, tipo_seccion, orden,
			repeticiones_min, repeticiones_max, versos_min, versos_max
		)
		select v_arq, v_fronte, fila.slug, fila.nombre, 'pie', fila.orden, 1, 1, 3, 3
		where not exists (
			select 1 from public.estructuras_secciones
			where arquitectura_id = v_arq and slug = fila.slug
		);
	end loop;

	-- «Chiave» es el otro nombre del eslabón, y ahora tiene dónde vivir.
	select seccion_id into v_eslabon
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'eslabon';

	insert into public.denominaciones_metricas (seccion_id, nombre, slug_normalizado, idioma)
	select v_eslabon, 'Chiave', 'chiave', 'it'
	where not exists (
		select 1 from public.denominaciones_metricas
		where seccion_id = v_eslabon and slug_normalizado = 'chiave'
	);

	-- Las partes tienen que sumar exactamente la estancia, y los pies, exactamente la fronte.
	select coalesce(sum(versos_min), 0) into v_versos
	from public.estructuras_secciones
	where arquitectura_id = v_arq and seccion_padre_id = v_estancia;
	if v_versos <> 13 then
		raise exception 'Las partes de la estancia regular suman % versos, no 13.', v_versos;
	end if;

	select coalesce(sum(versos_min), 0) into v_versos
	from public.estructuras_secciones
	where arquitectura_id = v_arq and seccion_padre_id = v_fronte;
	if v_versos <> 6 then
		raise exception 'Los pies de la fronte suman % versos, no 6.', v_versos;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 9 · Con qué se relaciona la canción
--
-- No tenía ninguna relación registrada, y son las dos que un anotador necesita: la estancia se
-- distingue de la lira por su extensión, y de la silva por repetir un patrón.
-- ---------------------------------------------------------------------------
do $$
declare
	v_cancion uuid;
	fila record;
begin
	select forma_id into v_cancion
	from public.formas_metricas where slug = 'cancion_petrarquista' and activo;

	for fila in
		select *
		from (values
			(
				'lira',
				'La estancia va normalmente por encima de los ocho versos, y eso es lo que la separa de la lira; cuando la estrofa es corta y simétrica y prescinde de la ordenación de la estancia, se habla de canción alirada.'
			),
			(
				'silva',
				'Las dos combinan heptasílabos y endecasílabos sin medida fija por posición. La canción repite en cada estancia el patrón que fijó la primera; la silva no repite ninguno.'
			)
		) as t(destino, nota)
	loop
		insert into public.forma_relaciones (
			forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision
		)
		select
			v_cancion,
			(select forma_id from public.formas_metricas where slug = fila.destino and activo),
			'contrasta_con',
			fila.nota,
			'aprobada'
		where not exists (
			select 1 from public.forma_relaciones
			where forma_origen_id = v_cancion
				and forma_destino_id = (select forma_id from public.formas_metricas where slug = fila.destino)
				and tipo_relacion = 'contrasta_con'
		);

		update public.forma_relaciones
		set nota = fila.nota
		where forma_origen_id = v_cancion
			and forma_destino_id = (select forma_id from public.formas_metricas where slug = fila.destino)
			and tipo_relacion = 'contrasta_con';
	end loop;

	if (select count(*) from public.forma_relaciones where forma_origen_id = v_cancion) <> 2 then
		raise exception 'La canción no tiene sus dos relaciones.';
	end if;
end $$;

commit;
