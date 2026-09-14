-- El terceto de Jauralde deja de citar una errata, y la septilla enlazada su epígrafe ajeno
--
-- Las dos últimas del cubo material. **Con ellas el cubo queda a cero.**
--
-- ══ `b3fb7d0b`  Terceto · Jauralde Pou 2020
--
-- La ficha atribuía a Jauralde «en ejemplos sueltos —así, en comedias de Lope—». Ni el libro dice
-- eso ni lo decía nuestro volcado: **abierto el epub, que es el original de esta fuente y no una
-- conversión**, lo que la edición de Cátedra imprime es «después de aparecer en ejemplos sueltos
-- —**así, ejemplo,** en comedias de Lope— volvió a ensayarse por poetas modernistas, que
-- recuperaron definitivamente la estrofa». Falta un «por» en el libro impreso.
--
-- De modo que había tres versiones —la del libro, la del volcado y la nuestra— y la nuestra era la
-- única que no existía en ninguna parte. Se parafrasea, y **no por desconfiar del volcado, que era
-- fiel, sino porque entrecomillar una errata de imprenta no dice nada del terceto**: el lector que
-- la vea entre comillas creerá que el descuido es del autor, y no lo es.
--
-- La primera mitad de la ficha, la cita larga del tercetillo monorrimo, se comprobó palabra por
-- palabra contra el epub y es exacta. No se toca.
--
-- **Queda anotado y sin tocar** que esa cita larga termina en «a partir del modernismo» cuando la
-- frase del libro sigue («, ahora ya también con verso de arte mayor…»), sin marca de corte. Es
-- convención rota, de las leves, y cambiarla es cambiar un texto que David aprobó tal cual.
--
-- **Y queda escrito aquí lo que hasta hoy decían al revés las instrucciones de la auditoría**: el
-- epub de Jauralde se abre y se lee. Además conserva la jerarquía de encabezados que el volcado
-- pierde —el `.txt` convierte las versalitas en «E STROFAS DE OCHO VERSOS» y aplana los niveles—,
-- y eso es lo que permitió confirmar que la copla manriqueña cuelga del `h6` «Formas mixtas» del
-- capítulo de las estrofas de ocho versos y no del `h3` «Formas mixtas en septetos», que es otro
-- sitio del libro.
--
-- ══ `11b899c3`  Septilla enlazada · Domínguez Caparrós 2014
--
-- La cuarta y última ficha de Caparrós que citaba «Índice de estrofas», epígrafe de Navarro Tomás
-- que no existe en este libro. **No la encontró la auditoría sino la guarda** de la migración
-- anterior, que iba a comprobar que la cláusula desaparecía del catálogo: la pasada A la había dado
-- por conforme y no entró en ninguna tanda.
--
-- Su prosa es exacta y no se toca ni una palabra. El apartado 10.2.6, pp. 199-200, da el septeto
-- endecasílabo de Ridruejo, la septilla `ababccb` de Rubén Darío y el septeto lira de fray Luis, y
-- ninguna variante en que la rima pase de una estrofa a la siguiente.
--
-- David aprobó los dos el 17 de septiembre de 2026.

begin;

do $$
declare
	v_terceto constant uuid := 'b3fb7d0b-952d-48d0-93da-84c755b6aa28';
	v_septilla constant uuid := '11b899c3-20f2-4c70-8853-f679b53a3b7b';
	v_terceto_res constant text :=
			'Es quien lo sitúa en el corpus de este catálogo: **«el tercetillo monorrimo es frecuente en '
			'composiciones medievales de base octosilábica o hexasilábica (como el zéjel, el villancico, '
			'normal como estribillo, con uno de sus versos quebrado, etc.), raro en los Siglos de Oro, cuando '
			'solo se utiliza para diálogos teatrales (por Lope de Vega y otros autores), y nuevamente variado '
			'y frecuente a partir del modernismo»**. Del terceto autónomo añade que, tras la poesía medieval '
			'tardía y los cancioneros, aparece en ejemplos sueltos, y cita entre ellos comedias de Lope, '
			'antes de que los modernistas recuperen la estrofa.';
	v_septilla_res constant text :=
			'No la registra. Al tratar las estrofas de siete versos no contempla que la rima pase de una a la '
			'siguiente.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_terceto
		and resumen like '%así, en comedias de Lope%'
		and localizador = 'Apartado «Estrofas de tres versos»';
	if v_cuantas <> 1 then
		raise exception 'La afirmación del terceto no está hoy como espero; no la toco.';
	end if;

	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_septilla and localizador = 'Índice de estrofas' and resumen = v_septilla_res;
	if v_cuantas <> 1 then
		raise exception 'La afirmación de la septilla enlazada no está hoy como espero; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_terceto_res
	where afirmacion_id = v_terceto;

	-- Aquí solo se mueve el localizador: el resumen se reescribe con su propio valor para que la
	-- comprobación de abajo pueda exigir que **no haya cambiado**.
	update public.afirmaciones_fuentes_metricas
	set localizador = 'pp. 199-200'
	where afirmacion_id = v_septilla;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que el terceto quedó exactamente con el texto que David aprobó, y que conserva íntegra la
	-- cita larga que no se tocaba.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_terceto
		and resumen = v_terceto_res
		and resumen like '%el tercetillo monorrimo es frecuente en composiciones medievales%'
		and localizador = 'Apartado «Estrofas de tres versos»';
	if v_cuantas <> 1 then
		raise exception 'El terceto no ha quedado con el texto aprobado por David.';
	end if;

	-- Que la septilla cambió de localizador y **no** de prosa.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where afirmacion_id = v_septilla and localizador = 'pp. 199-200' and resumen = v_septilla_res;
	if v_cuantas <> 1 then
		raise exception 'La septilla enlazada no ha quedado como se pretendía.';
	end if;

	-- Y con esto se acaba «Índice de estrofas» en las fichas de Caparrós: era la cuarta y última.
	-- La única que puede seguir citándolo es la de Navarro, que es de quien es el epígrafe.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.localizador like '%Índice de estrofas%' and f.autoria <> 'Tomás Navarro Tomás';
	if v_cuantas <> 0 then
		raise exception 'Todavía hay % fichas ajenas a Navarro citando su «Índice de estrofas».', v_cuantas;
	end if;

	-- Y que nadie del catálogo entero sigue atribuyendo a Jauralde la lectura que no existe.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where resumen like '%así, en comedias de Lope%';
	if v_cuantas <> 0 then
		raise exception 'Siguen % afirmaciones con la cita que no existe en ninguna edición.', v_cuantas;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
