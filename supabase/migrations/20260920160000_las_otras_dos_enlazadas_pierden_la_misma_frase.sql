-- Las otras dos enlazadas pierden también la frase que hablaba por Navarro Tomás
--
-- Al migrar el cubo de observación se retiró de `c5992665` —redondilla enlazada— la frase «Es la
-- única fuente que la describe»: es cierta, porque las otras cinco fuentes callan, pero es una
-- afirmación sobre el corpus entero dicha dentro de una sola fuente, y la sección ya lo enseña sola.
--
-- **La guarda que comprobó que había salido de ahí la encontró idéntica en dos fichas más**:
-- `eccebfab`, septilla enlazada, y `412ad16e`, sextilla enlazada. Las tres son de Navarro Tomás, las
-- tres son las estrofas enlazadas del § 131, y las tres abrían igual. Es la misma familia de
-- copiar-pegar que dio el `AB-DE-CF`, esta vez con tres hermanas.
--
-- Las dos estaban **fuera del cubo de observación** —en el de material, y dadas por corregidas—, de
-- modo que ninguna de las tres pasadas iba a volver a mirarlas. Una búsqueda más ancha
-- —«única fuente», «sola fuente», «ninguna otra fuente»— confirma que no hay una cuarta.
--
-- Solo se corta la frase; no se toca nada más, ni el localizador.
--
-- Aprobado por David el 20 de septiembre de 2026.

begin;

do $$
declare
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	create temporary table cambios_enlazadas (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_enlazadas (id8, antes, despues)
	values
		('412ad16e', 'Es la única fuente que la describe, y la describe verso a verso: «el primer octosílabo de cada estrofa recoge la rima final de la estrofa anterior; el segundo es un pie quebrado con otra rima que se repite en el tercer verso; los versos cuarto y quinto forman entre sí un pareado; el sexto se une a la consonancia del segundo y tercero», y la composición «empieza con una redondilla de la cual arranca la rima inicial de la primera sextilla». La resume así: «se trata de la quintilla con quebrado inicial de Castillejo a la cual se antepone un octosílabo rimado con el último verso de la estrofa precedente». **La documenta en el teatro**: «se encuentra la sextilla enlazada en la mayor parte de los pasos y entremeses comprendidos en la *Turiana*, de Timoneda, y en la epístola cuarta de la *Propalladia*, de Torres Naharro. Es asimismo la estrofa en que aparecen compuestas la farsa del Sacramento, la del Pueblo gentil y la de Moselina y el auto de *La muerte de Abel*». Y en su recorrido del período lo generaliza: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».', 'La describe verso a verso: «el primer octosílabo de cada estrofa recoge la rima final de la estrofa anterior; el segundo es un pie quebrado con otra rima que se repite en el tercer verso; los versos cuarto y quinto forman entre sí un pareado; el sexto se une a la consonancia del segundo y tercero», y la composición «empieza con una redondilla de la cual arranca la rima inicial de la primera sextilla». La resume así: «se trata de la quintilla con quebrado inicial de Castillejo a la cual se antepone un octosílabo rimado con el último verso de la estrofa precedente». **La documenta en el teatro**: «se encuentra la sextilla enlazada en la mayor parte de los pasos y entremeses comprendidos en la *Turiana*, de Timoneda, y en la epístola cuarta de la *Propalladia*, de Torres Naharro. Es asimismo la estrofa en que aparecen compuestas la farsa del Sacramento, la del Pueblo gentil y la de Moselina y el auto de *La muerte de Abel*». Y en su recorrido del período lo generaliza: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».'),
		('eccebfab', 'Es la única fuente que la describe. La presenta como la hermana de la sextilla enlazada: «con análoga técnica, la septilla enlazada rima su primer verso con el último de la estrofa anterior, y hace que el segundo, quebrado, sea consonante del siguiente, el cual por su parte forma una quintilla regular con los cuatro restantes», y la composición «principia con una quintilla que sirve de punto de partida al primer enlace»: `abaab-bccdccd-defeef`. Precisa la diferencia entre las dos: «la base de la estrofa está constituida en este caso por la quintilla, en lugar de la redondilla que sirve de fondo a la sextilla de su misma especie. **Los dos versos de enlace son análogos en una y otra**». **La documenta en el teatro**: «figura la septilla enlazada en varias de las poesías llamadas capítulos y lamentaciones de amor en la *Propalladia* de Torres Naharro y en los entremeses de Sebastián de Horozco». Y en su recorrido del período: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».', 'La presenta como la hermana de la sextilla enlazada: «con análoga técnica, la septilla enlazada rima su primer verso con el último de la estrofa anterior, y hace que el segundo, quebrado, sea consonante del siguiente, el cual por su parte forma una quintilla regular con los cuatro restantes», y la composición «principia con una quintilla que sirve de punto de partida al primer enlace»: `abaab-bccdccd-defeef`. Precisa la diferencia entre las dos: «la base de la estrofa está constituida en este caso por la quintilla, en lugar de la redondilla que sirve de fondo a la sextilla de su misma especie. **Los dos versos de enlace son análogos en una y otra**». **La documenta en el teatro**: «figura la septilla enlazada en varias de las poesías llamadas capítulos y lamentaciones de amor en la *Propalladia* de Torres Naharro y en los entremeses de Sebastián de Horozco». Y en su recorrido del período: «el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos».');

	-- Que las dos tienen hoy, palabra por palabra, el texto de antes.
	select count(*) into v_n
	from cambios_enlazadas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;
	if v_n <> 2 then
		raise exception 'Solo % de 2 afirmaciones tienen el texto que esta migración espera; no toco ninguna.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas a
	set resumen = c.despues
	from cambios_enlazadas c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.antes;

	-- ════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las dos quedaron con el texto nuevo, releído de la tabla.
	select count(*) into v_n
	from cambios_enlazadas c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.resumen = c.despues;
	if v_n <> 2 then
		raise exception 'Solo % de 2 quedaron con el texto nuevo.', v_n;
	end if;

	-- Y que la frase no queda en ninguna ficha del catálogo, dicha de ninguna de sus formas.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where resumen ~* '(única|sola) fuente' or resumen ~* 'la única que la describe';
	if v_n <> 0 then
		raise exception '% fichas siguen diciendo que su fuente es la única.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
