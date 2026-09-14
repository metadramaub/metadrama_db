-- Morley y Bruerton se citan ya con página, y son veinte entradas
--
-- Dos cosas que salieron de la pasada C sobre el cubo de confirmación, y que David aprobó por
-- separado del resto de la tanda porque no tocan una palabra de prosa.
--
-- ══ La página, que sí se podía dar
--
-- **Hay dos copias del capítulo V en el repositorio y no son iguales.** La de
-- `bibliografía/txt/definiciones_Morley&Bruerton.md`, que es a la que mandaban las instrucciones de
-- los verificadores, va sin paginar; la de `bibliografía/definiciones_Morley&Bruerton.md` es la
-- misma **con las marcas `[p. 38]` a `[p. 41]`**. Lo descubrió un verificador de la pasada C al
-- buscar por su cuenta, y con ello pudo dar página donde el catálogo solo daba epígrafe.
--
-- De las 45 afirmaciones de esta fuente, **34 no citaban página**, y lo hacían con seis fórmulas
-- distintas conviviendo: «Cap. V, "Soneto"», «Capítulo "Definición de las Formas Métricas"»,
-- «Entrada "Sestina"», «Definición "Seguidilla"»… Las 34 pasan al estilo que ya usaban las otras
-- once:
--
--   · una entrada          `Cap. V, «Quintilla», p. 38`
--   · un silencio          `Cap. V, pp. 38-41`
--   · silencio con locus   `Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39`
--
-- El rótulo se cita **como lo imprime la copia** y no como lo escribíamos: «Tercetos (Terza rima)»
-- con mayúscula, que es lo que hay en el original.
--
-- ══ Las veinte entradas
--
-- Los cuatro silencios de Morley y Bruerton que entraron con la fase 4 dicen que su repertorio «lo
-- componen **veintiuna** entradas». **Son veinte**, y el error es de quien las escribió: se contaron
-- de un vistazo sobre un listado en pantalla en vez de contarlas. `grep -c '^### '` da 20 en las dos
-- copias. Lo encontró también la pasada C, al recorrer el capítulo entero para justificar una
-- ausencia.
--
-- Dos de esas veinte se llaman igual, «Pareados» —una en la p. 39, octosílaba, y otra en la 41,
-- endecasílaba—, que es la ambigüedad que ya se resolvió el 17 de septiembre en la ficha del
-- pareado.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['96a4a4bd', 'Capítulo «Definición de las Formas Métricas», epígrafes «Canción (Canzone)» y «Canción sin rima»', 'Cap. V, epígrafes «Canción (Canzone)», p. 40, y «Canción sin rima», p. 41'],
		array['bbd5db7e', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41'],
		array['e34d7ba1', 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»', 'Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39'],
		array['2b540a21', 'Capítulo «Definición de las Formas Métricas», epígrafe «Copla real»', 'Cap. V, «Copla real», p. 38'],
		array['3d753230', 'Capítulo «Definición de las Formas Métricas», epígrafes «Liras» y «Canción (Canzone)»', 'Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40'],
		array['3ac1b32a', 'Cap. V, «Décima (espinela)»', 'Cap. V, «Décima (espinela)», p. 38'],
		array['bf669381', 'Cap. V, «Décima (espinela)»', 'Cap. V, «Décima (espinela)», p. 38'],
		array['c19107a1', 'Capítulo «Definición de las Formas Métricas», epígrafes «Liras» y «Canción (Canzone)»', 'Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40'],
		array['0f1a65eb', 'Capítulo «Definición de las Formas Métricas», epígrafe «Sueltos»', 'Cap. V, «Sueltos», p. 40'],
		array['76b5b6b9', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41'],
		array['19a5eb39', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41'],
		array['9c4dd052', 'Cap. V, «Liras»', 'Cap. V, «Liras», p. 40'],
		array['a5f90ba6', 'Capítulo «Definición de las Formas Métricas», epígrafes «Liras» y «Canción (Canzone)»', 'Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40'],
		array['e6434e41', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41'],
		array['7f974dcf', 'Cap. V, «Octavas (reales)»', 'Cap. V, «Octavas (reales)», p. 39'],
		array['497253a9', 'Capítulo «Definición de las Formas Métricas», epígrafes «Liras» y «Canción (Canzone)»', 'Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40'],
		array['5b191115', 'Cap. V, «Quintilla»', 'Cap. V, «Quintilla», p. 38'],
		array['409dee24', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41'],
		array['2cb2f293', 'Cap. V, «Romance»', 'Cap. V, «Romance», p. 39'],
		array['40c2c354', 'Definición «Seguidilla»', 'Cap. V, «Seguidilla», p. 39'],
		array['2aa77cd4', 'Capítulo «Definición de las Formas Métricas», epígrafe «Liras»', 'Cap. V, «Liras», p. 40'],
		array['4b2baf4c', 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»', 'Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39'],
		array['a71991db', 'Capítulo «Definición de las Formas Métricas», epígrafe «Soneto»', 'Cap. V, «Soneto», p. 40'],
		array['943624e5', 'Capítulo «Definición de las Formas Métricas», epígrafe «Liras»', 'Cap. V, «Liras», p. 40'],
		array['36050590', 'Capítulo «Definición de las Formas Métricas», epígrafes «Coplas» y «Coplas de pie quebrado»', 'Cap. V, epígrafes «Coplas» y «Coplas de pie quebrado», p. 39'],
		array['8dc1b345', 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas de pie quebrado»', 'Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39'],
		array['5fd8bf43', 'Capítulo «Definición de las Formas Métricas», epígrafe «Sestina»', 'Cap. V, pp. 38-41, y epígrafe «Sestina», p. 41'],
		array['f749bd50', 'Entrada «Sestina»', 'Cap. V, «Sestina», p. 41'],
		array['0432c49f', 'Cap. V, «Silva»', 'Cap. V, «Silva», p. 39'],
		array['a5822734', 'Cap. V, «Soneto»', 'Cap. V, «Soneto», p. 40'],
		array['e0c28298', 'Cap. V, «Tercetos (sin encadenar)»', 'Cap. V, «Tercetos (sin encadenar)», p. 40'],
		array['80001779', 'Cap. V, «Tercetos (terza rima)»', 'Cap. V, «Tercetos (Terza rima)», p. 40'],
		array['4ea9f5e6', 'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas»', 'Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39'],
		array['aef2b12f', 'Capítulo «Definición de las Formas Métricas»', 'Cap. V, pp. 38-41']
	];
	v_fila text[];
	v_cuantas integer;
	v_puestos integer := 0;
	v_prosa_antes text;
	v_prosa_despues text;
	-- `unnest` sobre un array de dos dimensiones aplana a escalares y `x[1]` falla: se recorre
	-- con `foreach … slice 1`, que es lo que devuelve filas.
	v_tocadas text[] := '{}';
	v_antes bigint;
	v_despues bigint;
begin
	foreach v_fila slice 1 in array v_cambios loop
		v_tocadas := v_tocadas || v_fila[1];
	end loop;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ------------------------------------------------------------------ Las veinte entradas
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where resumen like '%veintiuna entradas%';
	if v_cuantas <> 4 then
		raise exception 'Esperaba 4 afirmaciones diciendo «veintiuna entradas» y encuentro %.', v_cuantas;
	end if;

	update public.afirmaciones_fuentes_metricas
	set resumen = replace(resumen, 'veintiuna entradas', 'veinte entradas')
	where resumen like '%veintiuna entradas%';

	-- ------------------------------------------------------------------ Los localizadores
	--
	-- La prosa no se toca: se guarda antes y se compara al final.
	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_antes
	from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = any(v_tocadas);

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[2];
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				v_fila[1], v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3]
		where left(afirmacion_id::text, 8) = v_fila[1];
	end loop;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Que no queda ninguna afirmación de esta fuente sin página.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1968 and a.localizador !~ 'pp?\. [0-9]';
	if v_cuantas <> 0 then
		raise exception 'Quedan % afirmaciones de Morley y Bruerton sin página.', v_cuantas;
	end if;

	-- Que todas empiezan igual, que es lo que significa unificar.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1968 and a.localizador not like 'Cap. V,%';
	if v_cuantas <> 0 then
		raise exception 'Quedan % localizadores de Morley y Bruerton fuera del estilo.', v_cuantas;
	end if;

	-- Que ninguna página inventada: las del capítulo son la 38, la 39, la 40 y la 41.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1968
		and exists (
			select 1 from regexp_matches(a.localizador, 'p\. ([0-9]+)', 'g') as m(x)
			where m.x[1] not in ('38', '39', '40', '41')
		);
	if v_cuantas <> 0 then
		raise exception '% localizadores citan una página que no es del capítulo V.', v_cuantas;
	end if;

	-- Y que ninguno sigue diciendo «veintiuna».
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas where resumen like '%veintiuna%';
	if v_cuantas <> 0 then
		raise exception 'Siguen % afirmaciones diciendo «veintiuna».', v_cuantas;
	end if;

	-- La prosa de los treinta y cuatro no ha cambiado: esto movía localizadores.
	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_despues
	from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = any(v_tocadas);
	if v_prosa_despues is distinct from v_prosa_antes then
		raise exception 'Ha cambiado la prosa de alguna de las que solo movían localizador.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
