-- La décima explica sus nombres y su pausa
--
-- Sus cuatro notas de sección son **invisibles** —ni la fila «Partes» ni las bandas imprimen la
-- nota de una sección— y las cuatro decían la notación que la rejilla ya dibuja. Se van.
--
-- Lo que se queda se afina. La definición dejaba de repetir la notación impresa debajo; la
-- descripción del esquema pasa a decir lo único que la figura dibuja de manera engañosa —que el
-- quinto verso rima con la primera redondilla aunque la banda lo ponga en el enlace—; y la
-- descripción de la espinela explica por fin de dónde salen sus dos nombres, incluido el
-- «redondilla de diez versos» que hoy aparece en la lista sin que nada lo justifique.
--
-- Las guardas exigen el valor viejo **o** el nuevo, de modo que la migración puede repetirse.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La definición
--
-- La pausa se menciona como lo que además distingue de la copla real, no como lo único: la
-- copla real tampoco tiene este esquema de rima.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_actual text;
	v_viejo constant text :=
		'Estrofa de diez versos octosílabos con rima consonante formada por dos redondillas abrazadas y dos versos de enlace entre ellas, que repiten la rima última de la primera y anuncian la primera de la segunda: abba, ac, cddc. Tras el cuarto verso se abre una pausa de sentido, y es esa pausa la que la separa de la copla real, que también son diez octosílabos pero se articula en 5 + 5.';
	v_nuevo constant text :=
		'Estrofa de diez versos octosílabos: dos redondillas abrazadas y, entre ellas, dos versos que cierran la rima de la primera y abren la de la segunda. Tras el cuarto verso se abre una pausa de sentido, que sirve además para distinguirla de la copla real, también de diez octosílabos pero articulada en cinco y cinco.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'decima' and activo;

	if v_forma is null then
		raise exception 'No existe la forma activa «decima».';
	end if;

	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La definición de la décima no es la esperada. Dice: %', v_actual;
	end if;

	update public.formas_metricas set definicion = v_nuevo where forma_id = v_forma;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Las dos descripciones de arquitectura
--
-- La de la espinela decía «realización canónica», que es «Principal · habitual», y dejaba sin
-- explicar la denominación «Redondilla de diez versos», que el lector ve arriba sin saber de
-- dónde sale. La de la aumentada solo pierde la frase que justifica el modelado.
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	fila record;
	v_actual text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'decima' and activo;

	for fila in
		select *
		from (values
			(
				'espinela',
				'Realización canónica, la que Espinel divulgó y a la que la estrofa debe su otro nombre.',
				'Espinel la consagró, y de ahí el nombre: fue Lope quien pidió que se llamaran espinelas. Él la llamaba solo redondilla de diez versos.'
			),
			(
				'aumentada',
				'Alarga el miembro final de cuatro versos a seis, con una clase de rima nueva; la primera redondilla y los versos de enlace no cambian. Aparece intercalada entre décimas normales, no como forma aparte.',
				'Alarga el miembro final de cuatro versos a seis, con una clase de rima nueva; la primera redondilla y los versos de enlace no cambian. Aparece intercalada entre décimas normales.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select descripcion into v_actual
		from public.arquitecturas_forma
		where forma_id = v_forma and slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la arquitectura activa «%» de la décima.', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La descripción de decima/% no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.arquitecturas_forma
		set descripcion = fila.nuevo
		where forma_id = v_forma and slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · Las cuatro notas de sección, invisibles y dibujadas
-- ---------------------------------------------------------------------------
do $$
declare
	v_forma uuid;
	v_esperadas constant text[] := array[
		'Primer bloque abba, seguido de la pausa característica.',
		'Bloque final cddc.',
		'Arranque abba, seguido de la pausa característica.',
		'Continuación accddeed; no se le atribuye una subdivisión interna no declarada.'
	];
	v_ajenas integer;
	v_restantes integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'decima' and activo;

	select count(*) into v_ajenas
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.nota is not null and not (s.nota = any (v_esperadas));

	if v_ajenas > 0 then
		raise exception 'La décima tiene % notas de sección distintas de las esperadas.', v_ajenas;
	end if;

	update public.estructuras_secciones s
	set nota = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = s.arquitectura_id and a.forma_id = v_forma and s.nota is not null;

	select count(*) into v_restantes
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	where a.forma_id = v_forma and s.nota is not null;

	if v_restantes > 0 then
		raise exception 'Quedan % notas de sección en la décima.', v_restantes;
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4 · La descripción del esquema dice lo que la figura dibuja mal
--
-- Las bandas separan «Primera redondilla» (1-4), «Enlace» (5-6) y «Segunda redondilla» (7-10),
-- pero el esquema es `abba accddc`: el quinto verso rima con la primera redondilla aunque la
-- banda lo ponga en el enlace. Es justo lo que confunde de la espinela.
-- ---------------------------------------------------------------------------
do $$
declare
	v_esquema uuid;
	v_actual text;
	v_viejo constant text :=
		'La pausa estructural se produce tras abba; los versos centrales ac enlazan los dos bloques.';
	v_nuevo constant text :=
		'La pausa cae dentro del enlace: el quinto verso cierra la rima de la primera redondilla y el sexto abre la de la segunda.';
begin
	select er.esquema_rima_id into v_esquema
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'decima' and er.slug = 'abbaaccddc';

	if v_esquema is null then
		raise exception 'No existe el esquema «abbaaccddc» de la décima.';
	end if;

	select descripcion into v_actual from public.esquemas_rima where esquema_rima_id = v_esquema;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La descripción del esquema no es la esperada. Dice: %', v_actual;
	end if;

	update public.esquemas_rima set descripcion = v_nuevo where esquema_rima_id = v_esquema;
end $$;

-- ---------------------------------------------------------------------------
-- 5 · La relación con la redondilla, más precisa
--
-- La décima hereda de la redondilla también su rima: que solo use la abrazada y no la cruzada
-- no la hace menos redondilla. Solo se precisa cuál de las dos.
-- ---------------------------------------------------------------------------
do $$
declare
	v_decima uuid;
	v_redondilla uuid;
	v_actual text;
	v_viejo constant text :=
		'La espinela articula dos redondillas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.';
	v_nuevo constant text :=
		'La espinela articula dos redondillas abrazadas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.';
begin
	select forma_id into v_decima from public.formas_metricas where slug = 'decima' and activo;
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla' and activo;

	select nota into v_actual
	from public.forma_relaciones
	where forma_origen_id = v_decima and forma_destino_id = v_redondilla;

	if not found then
		raise exception 'No existe la relación de la décima con la redondilla.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la relación con la redondilla no es la esperada. Dice: %', v_actual;
	end if;

	update public.forma_relaciones
	set nota = v_nuevo
	where forma_origen_id = v_decima and forma_destino_id = v_redondilla;
end $$;

-- ---------------------------------------------------------------------------
-- 6 · La afirmación de Morley y Bruerton no justifica el catálogo
-- ---------------------------------------------------------------------------
do $$
declare
	v_arq uuid;
	v_id uuid;
	v_actual text;
	v_viejo constant text :=
		'Registran la décima aumentada de doce versos, ABBA: ACCDDEED, y advierten que es demasiado frecuente para considerarla defectuosa: aparece en medio de pasajes de décimas normales. Es la razón de que figure como arquitectura y no como error de anotación.';
	v_nuevo constant text :=
		'Registran la décima aumentada de doce versos, ABBA: ACCDDEED, y advierten que es demasiado frecuente para considerarla defectuosa: aparece en medio de pasajes de décimas normales.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'decima' and a.slug = 'aumentada' and a.activo;

	select afirmacion_id, resumen into v_id, v_actual
	from public.afirmaciones_fuentes_metricas
	where arquitectura_id = v_arq and fuente_id = 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;

	if v_id is null then
		raise exception 'No existe la afirmación de Morley y Bruerton sobre la décima aumentada.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La afirmación no es la esperada. Dice: %', v_actual;
	end if;

	update public.afirmaciones_fuentes_metricas set resumen = v_nuevo where afirmacion_id = v_id;
end $$;

commit;
