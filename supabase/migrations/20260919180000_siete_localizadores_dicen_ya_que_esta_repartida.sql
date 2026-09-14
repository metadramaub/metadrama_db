-- Siete localizadores dicen ya que la afirmación está repartida
--
-- La pasada C declaró **veinte de las cincuenta y siete repartidas**: lo que la ficha resume no está
-- en un sitio sino en dos o más. Once quedaron cubiertas al darles página. Estas siete cambian
-- porque el localizador **decía un solo lugar donde hay varios**, o nombraba un apartado que no
-- acota nada.
--
--   45c3cae7  Zéjel · Navarro. Tres §§ de tres períodos, con sus páginas.
--   4715840b  Décima · Caparrós. La espinela se parte por el corte de página: la 205 termina en
--             «Tras el cuarto verso debe haber una pausa» y la 206 abre con «de sentido».
--   a2d4af6f  Versificación irregular · Caparrós. **El único caso en que la C y el catálogo se
--             contradecían**: nosotros decíamos «pp. 45-46 y 159» y la C, «46 y 49». Comprobado en
--             el PDF, las dos tienen razón y faltaba una: la p. 49 trae la enumeración que la ficha
--             recoge —«como clases de versificación irregular o amétrica […] cabe mencionar la
--             tónica, la fluctuante, la cuantitativa y la libre»— y el localizador la omitía. Van
--             las tres.
--   a3ce6b87  Redondilla · *Diccionario*. Reparto interno al artículo: la definición en el sentido
--             1 y la amplitud del término en el Siglo de Oro en el 3, ya en la página siguiente.
--   387f50dd  Endecasílabo suelto · Jauralde. «Apartados sobre la rima y el verso libre» no era un
--             localizador: no nombra ningún epígrafe del libro. Son dos, y de capítulos distintos.
--   a5faa793  Quintilla · Jauralde. Al epígrafe general hay que añadir los dos subepígrafes por
--             medida, que son rótulo y ejemplo sin prosa.
--   b2e4dfe5  Sextilla · Jauralde. El dato de Ricardo Gil no está con las sextillas sino en
--             «Sextetos mixtos», otro epígrafe y otro fichero del epub.

begin;

do $$
declare
	v_cambios constant text[][] := array[
		array['45c3cae7', '§§ 14, 92 y 211', '§§ 14, pp. 50-51; 92, pp. 168-169; y 211, pp. 286-287'],
		array['4715840b', 'p. 205', 'pp. 205-206'],
		array['a2d4af6f', 'pp. 45-46 y 159', 'pp. 45-46, 49 y 159'],
		array['a3ce6b87', 'Entrada «redondilla», p. 300', 'Entrada «redondilla», sentidos 1 y 3, pp. 300-301'],
		array['387f50dd', 'Apartados sobre la rima y el verso libre', 'Apartados «El verso libre», del capítulo de los versos, y «Estrofas», del de las estrofas'],
		array['a5faa793', '«Estrofas» → «Quintillas»', 'Apartados «Quintillas», «Quintilla hexasilábica» y «Quintilla heptasilábica»'],
		array['b2e4dfe5', 'Apartados «Estrofas de seis versos» y «Sextillas»', 'Apartados «Estrofas de seis versos», «Sextillas» y «Sextetos mixtos»']
	];
	v_fila text[];
	v_tocadas text[] := '{}';
	v_cuantas integer;
	v_puestos integer := 0;
	v_prosa_antes text;
	v_prosa_despues text;
	v_antes bigint;
	v_despues bigint;
begin
	foreach v_fila slice 1 in array v_cambios loop
		v_tocadas := v_tocadas || v_fila[1];
	end loop;

	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_antes
	from public.afirmaciones_fuentes_metricas where left(afirmacion_id::text, 8) = any(v_tocadas);

	select revision into v_antes from public.catalogo_metrico_estado where id;

	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[2];
		if v_cuantas <> 1 then
			raise exception 'La afirmación % no tiene hoy el localizador «%»; no la toco.',
				v_fila[1], v_fila[2];
		end if;

		update public.afirmaciones_fuentes_metricas
		set localizador = v_fila[3] where left(afirmacion_id::text, 8) = v_fila[1];
	end loop;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	foreach v_fila slice 1 in array v_cambios loop
		select count(*) into v_cuantas from public.afirmaciones_fuentes_metricas
		where left(afirmacion_id::text, 8) = v_fila[1] and localizador = v_fila[3];
		v_puestos := v_puestos + v_cuantas;
	end loop;
	if v_puestos <> array_length(v_cambios, 1) then
		raise exception 'Solo % de % localizadores quedaron con el valor nuevo.',
			v_puestos, array_length(v_cambios, 1);
	end if;

	-- Y que no se ha tocado una palabra de prosa: esto movía localizadores.
	select string_agg(resumen, '|' order by afirmacion_id) into v_prosa_despues
	from public.afirmaciones_fuentes_metricas where left(afirmacion_id::text, 8) = any(v_tocadas);
	if v_prosa_despues is distinct from v_prosa_antes then
		raise exception 'Ha cambiado la prosa de alguna afirmación, y esta migración no la tocaba.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
