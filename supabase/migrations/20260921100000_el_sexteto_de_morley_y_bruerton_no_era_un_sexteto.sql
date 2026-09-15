-- El sexteto de Morley y Bruerton no era un sexteto, y quince localizadores ganan su sitio
--
-- La pasada C recorrió las veinticuatro afirmaciones del núcleo de la lectura dirigida que aún no la
-- habían tenido. Devuelve un defecto de texto y quince localizadores.
--
-- ══ El defecto, y lo vio David
--
-- La ficha del **Sexteto** decía que M&B llaman así a los seis versos que siguen a los dos cuartetos
-- del soneto —lo cual es cierto— y a continuación copiaba sus cuatro disposiciones de rima:
-- CDCDCD, CDECDE, CDEDCE, CDCEDE.
--
-- **Esos esquemas no son de esta forma.** Son los del sexteto del soneto, que en este catálogo son
-- dos tercetos, y **ya están donde deben**, en la ficha del soneto de esta misma fuente, con su
-- «advierten que hay otras» y la remisión al estudio de Dorothy C. Clarke. Aquí estaban duplicados en
-- la forma equivocada, y el daño no era solo de lectura: la comprobación mecánica nº 2 cosecha
-- esquemas ficha por ficha, de modo que se estaban contando contra una estrofa que no los tiene.
--
-- Sale también «No figura entre las estrofas del repertorio dramático»: **ese repertorio no existe en
-- el documento**. El capítulo V es un catálogo de definiciones, sin inventario por período, y ni
-- «repertorio» ni «dramátic-» aparecen en él. Lo sustituye lo que sí se puede comprobar.
--
-- Y entra una frase final porque **el silencio es del nombre, no de la medida**: M&B sí registran
-- estrofas de seis versos, llamadas «Liras» y «Sestina». Es lo mismo que ya hace la ficha de la
-- sextilla de esta fuente.
--
-- ══ Los quince localizadores
--
-- Doce ganan página o § y tres solo uniforman el estilo. Los que corrigen de verdad son cuatro:
--
--   `cf2dcb07`  la canción petrarquista del *Diccionario* se apoya también en la entrada «canción
--               alirada», que el localizador no declaraba.
--   `49b4e370`  la décima de Jauralde está repartida en **cinco** epígrafes: el de las estrofas de diez
--               versos y uno por cada medida documentada.
--   `b55ae482`  y `da0d0e2d`, las enlazadas del *Diccionario*, citan «terceto enlazado» en su texto y
--               no lo tenían en el localizador.
--
-- Aprobado por David el 20 de septiembre de 2026.
begin;

do $$
declare
	v_n integer;
	v_antes bigint;
	v_despues bigint;
	v_antes_txt constant text :=
		'En su repertorio de las formas métricas de Lope de Vega, «sexteto» nombra únicamente los seis versos que siguen a los dos cuartetos del soneto, cuyas rimas describen como variables: CDCDCD, CDECDE, CDEDCE, CDCEDE y otras. No figura entre las estrofas del repertorio dramático.';
	v_despues_txt constant text :=
		'**«Sexteto»** no nombra en su repertorio una estrofa de seis versos: nombra los seis versos que siguen a los dos cuartetos del soneto, y es dentro del epígrafe «Soneto» donde describen sus rimas. No hay epígrafe «Sexteto» entre los veinte del capítulo, aunque sí registran estrofas de seis versos bajo otros nombres —«Liras» y «Sestina»—.';
begin
	-- ── El sexteto
	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'a71991db' and resumen = v_antes_txt;
	if v_n <> 1 then
		raise exception 'La ficha del sexteto no tiene hoy el texto que esta migración espera.';
	end if;

	-- ── Los localizadores
	create temporary table cambios_loc24 (
		id8 text not null,
		antes text not null,
		despues text not null
	) on commit drop;

	insert into cambios_loc24 (id8, antes, despues)
	values
		('0df80a1a', 'p. 91', '§ 5.4.1.1, p. 91'),
		('22157a22', '§§ 5.4.7 y 5.4.8', '§§ 5.4.7 y 5.4.8, pp. 106-109'),
		('35a26a3d', '«Estrofas de cuatro versos»', 'Apartado «Estrofas de cuatro versos»'),
		('3d5e92bb', 'p. 138', '§ 8.3.5, p. 138'),
		('49b4e370', 'Apartado «Estrofas de diez versos»', 'Apartado «Estrofas de diez versos» y sus epígrafes «Décimas hexasilábicas», «Décimas heptasilábicas», «Décimas pentasilábicas» y «Décimas endecasilábicas»'),
		('514e4cdd', 's. v. «novena»', 'Entrada «novena», p. 240'),
		('7834edd3', '§ 185', '§ 185, pp. 268-269'),
		('7ac4bf24', 's. v. «endecha real», p. 150', 'Entrada «endecha real», p. 150'),
		('9ca15634', 'p. 184', '§ 10.2.1, p. 184'),
		('b55ae482', 'Entradas «séptima», «copla encadenada» y «sexteto enlazado»', 'Entradas «séptima», p. 382, «sexteto enlazado», p. 388, «terceto enlazado», p. 428, y «copla encadenada», p. 90'),
		('bdac1b06', 's. v. «villancico» y «vuelta»', 'Entrada «villancico», pp. 495-496, y «vuelta»'),
		('cf2dcb07', 'Entradas «canción a la italiana» y «estancia»', 'Entradas «canción a la italiana», pp. 61-63, «canción alirada», pp. 60-61, y «estancia», pp. 163-164'),
		('d8f31c19', '§§ 67 y 68', '§§ 67 y 68, pp. 132-134'),
		('da0d0e2d', 'Entradas «sextilla», «copla encadenada» y «sexteto enlazado»', 'Entradas «sextilla» y sus variedades, pp. 389-390, «sexteto enlazado», p. 388, «terceto enlazado», p. 428, y «copla encadenada», p. 90'),
		('fb1e1cda', '«Estrofas de tres versos»', 'Apartado «Estrofas de tres versos»');

	select count(*) into v_n
	from cambios_loc24 c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;
	if v_n <> 15 then
		raise exception 'Solo % de 15 localizadores son hoy los que esta migración espera.', v_n;
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_despues_txt
	where left(afirmacion_id::text, 8) = 'a71991db';

	update public.afirmaciones_fuentes_metricas a
	set localizador = c.despues
	from cambios_loc24 c
	where left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.antes;

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = 'a71991db' and resumen = v_despues_txt;
	if v_n <> 1 then
		raise exception 'El sexteto no quedó con el texto nuevo.';
	end if;

	-- Que los cuatro esquemas del sexteto del soneto quedan en una sola ficha de esta fuente,
	-- la del soneto, y no en la del sexteto.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where f.anio = 1968 and a.resumen like '%CDEDCE%';
	if v_n <> 1 then
		raise exception '% fichas de Morley y Bruerton llevan los esquemas del sexteto del soneto, y solo debe llevarlos la del soneto.', v_n;
	end if;

	select count(*) into v_n
	from cambios_loc24 c
	join public.afirmaciones_fuentes_metricas a
		on left(a.afirmacion_id::text, 8) = c.id8 and a.localizador = c.despues;
	if v_n <> 15 then
		raise exception 'Solo % de 15 localizadores quedaron con el valor nuevo.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
