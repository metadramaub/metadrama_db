-- Se acaba el «pp. 205 y ss.» de Caparrós, y dos afirmaciones dicen ya que están repartidas
--
-- Quedaban cuatro afirmaciones de esta fuente cuya página nueva **no coincidía entre las dos
-- pasadas**, así que no se tocaron en la migración anterior. Se resolvieron con la **pasada C, la
-- localización ciega**, que el plan describía desde el principio y que nunca se había ejecutado:
-- recibe el texto de la afirmación **sin localizador** y busca por su cuenta dónde lo dice el
-- libro. Después se comprobó cada hoja en el PDF, leyendo el número impreso al pie.
--
-- El resultado importa más allá de estas cuatro: **la pasada B discrepó en tres y se equivocó en
-- las tres.** A y C coincidieron, y el PDF les dio la razón.
--
--   b22cf39e  Octava aguda  pp. 205 y ss. → pp. 200 y 203
--             B decía 203-204. El recuento de las estrofas de ocho versos abre el epígrafe
--             10.2.7 en la p. 200 (hoja 197) y la cláusula de la octavilla está en la p. 203
--             (hoja 200): la afirmación está repartida y el localizador tiene que decirlo.
--   afe1da83  Septilla      pp. 205 y ss. → pp. 201-202
--             B decía 199-200, el epígrafe del septeto. El esquema `abbacca`, la atribución de
--             «copla mixta» a Navarro Tomás y el anuncio del *Planto de la Reina Margarida* están
--             en la p. 201 (hoja 198); la copla del ejemplo cae ya en la 202 por el corte de
--             página.
--   ff6f74f9  Soneto        p. 218        → pp. 218 y 221
--             B decía que la p. 218 era todavía la sextina y que el soneto empezaba en la 219. No:
--             en la hoja 215 se lee el pie «218», el final de la sextina **y** el epígrafe
--             «• Soneto» con su definición. La condición de unidad temática está tres páginas
--             después, en la p. 221 (hoja 218).
--   a721abb6  Cuarteto      p. 188        → **no se toca**
--             B decía que la definición estaba en la p. 187. No: en la hoja 185, con el pie «188»,
--             están las dos cosas que la afirmación recoge, el «si los versos son de arte mayor,
--             se llama cuarteto» del cuerpo y la nota 174 sobre el Siglo de Oro.
--
-- Con esto **no queda ninguna afirmación de Caparrós 2014 citando «pp. 205 y ss.»**, el
-- localizador que se copió una vez y se arrastró a cinco fichas.
--
-- **Lo que esta migración no arregla, y hay que arreglar.** Al abrir la p. 200 se ve que nuestra
-- afirmación de la octava aguda entrecomilla el recuento como «la copla de arte menor, la copla
-- castellana, la octava real, la octava y la octavilla agudas», y el libro escribe «la copla de
-- arte **mayor**, la copla de arte menor, la copla castellana, la octava real, la octava y la
-- octavilla agudas». Falta el primer término de una enumeración citada entre comillas. Es una cita
-- inexacta y **se corrige aparte, porque toca el texto y lo aprueba David**.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['b22cf39e-bda9-4377-9c81-85735cec0662', 'pp. 205 y ss.', 'pp. 200 y 203'],
		array['afe1da83-8247-4a7e-a989-2e4fe4d85bac', 'pp. 205 y ss.', 'pp. 201-202'],
		array['ff6f74f9-e0ee-40f0-ac2d-30c7077af652', 'p. 218', 'pp. 218 y 221']
	];
	v_fila text[];
	v_ids uuid[] := '{}';
	v_cuantas integer;
	v_puestos integer := 0;
	v_resumen_antes text;
	v_resumen_despues text;
	v_antes bigint;
	v_despues bigint;
begin
	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- `unnest` aplana un array de dos dimensiones hasta los escalares, así que las filas se
	-- recorren con `foreach … slice 1` y los identificadores se juntan aparte.
	foreach v_fila slice 1 in array v_cambios loop
		v_ids := v_ids || (v_fila[1])::uuid;
	end loop;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_antes
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		where a.afirmacion_id = (v_fila[1])::uuid
			and a.localizador = v_fila[2]
			and f.anio = 2014;
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				left(v_fila[1], 8), v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3]
		where afirmacion_id = (v_fila[1])::uuid;
	end loop;

	-- ------------------------------------------------------------------ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas
		from public.afirmaciones_fuentes_metricas
		where afirmacion_id = (v_fila[1])::uuid and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Ya no debe quedar ninguna con el localizador copiado. Es la comprobación que da sentido a
	-- las dos migraciones juntas: la familia entera, no una ficha suelta.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2014 and a.localizador = 'pp. 205 y ss.';
	if v_cuantas <> 0 then
		raise exception 'Todavía quedan % afirmaciones de 2014 con «pp. 205 y ss.».', v_cuantas;
	end if;

	-- Y que no se ha tocado ninguna afirmación de esta fuente fuera de las tres declaradas. Importa
	-- por el cuarteto: que una pasada dijera que su página no era la suya no bastó para moverlo, y
	-- dejarlo quieto es tan decisión como cambiarlo.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 2014 and a.updated_at > now() - interval '1 minute'
		and not (a.afirmacion_id = any(v_ids));
	if v_cuantas <> 0 then
		raise exception 'Se han tocado % afirmaciones de 2014 que no estaban declaradas.', v_cuantas;
	end if;

	select string_agg(resumen, '|' order by afirmacion_id) into v_resumen_despues
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = any(v_ids);
	if v_resumen_despues is distinct from v_resumen_antes then
		raise exception 'Ha cambiado el texto de alguna afirmación, y esta migración solo movía localizadores.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
