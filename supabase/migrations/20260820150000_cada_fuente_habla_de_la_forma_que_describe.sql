-- Cada fuente habla de la forma que describe
--
-- Dos asuntos que van juntos porque el segundo destapó el primero: la revisión de la prosa de la
-- **copla real**, y la corrección de un reparto de fuentes que yo hice mal hace tres migraciones.
--
-- ## El reparto de fuentes
--
-- Al retirar la copla de pie quebrado moví sus cinco afirmaciones al rasgo `pie_quebrado`, para
-- que se leyeran en las cuatro formas que lo declaran. En la sextilla colaba; en las otras tres,
-- no: la ficha de la copla real acabó mostrando «Presenta como realización más conocida **la
-- sextilla**…» y «**La copla de Jorge Manrique** combina octosílabos y tetrasílabos… 8a 8b 4c»,
-- dos notas de fuente que hablan de otra estrofa. Una misma afirmación no puede servir a cuatro
-- formas: **cada fuente dice lo que dice de cada una**, y eso ya estaba escrito.
--
-- Contrastadas las cuatro formas contra sus seis fuentes, el movimiento se deshace casi entero:
--
--   * **La copla real y la novena no necesitaban nada.** Sus propias afirmaciones ya hablan del
--     quiebro: el *Diccionario* dice de la copla real que admite «algún verso quebrado
--     tetrasílabo» y Jauralde que «con el tiempo llegó a quebrar alguno de sus versos»; de la
--     novena lo dicen sus cuatro fuentes, cada una a su manera. No se tocan.
--   * **La sextilla tampoco**, salvo cuatro precisiones que sí eran suyas y que se integran en
--     las afirmaciones que ya tenía: el rango de cinco a doce versos de Morley y Bruerton —que
--     esa migración le había recortado y aquí se le devuelve—, la variante de Quilis con los
--     quebrados en segundo y quinto verso, la medida del quiebro según Navarro y la compensación
--     del pentasílabo según Caparrós.
--   * **La redondilla sí tenía un hueco**, y era el único: ninguna de sus nueve afirmaciones
--     mencionaba el quiebro, ni siquiera la fuente que justificó declararle el rasgo. Se le añade
--     su Navarro.
--
-- Y el rasgo se queda sin bibliografía propia, que es lo correcto.
--
-- ## La copla real
--
-- Su definición dejaba al lector ante ocho disposiciones por mitad —sesenta y cuatro
-- combinaciones— cuando las fuentes dicen que en la práctica son muy pocas. Ahora lo dice.
--
-- **Esa frase tapa por ahora un problema del modelo, y conviene que conste.** Las dos quintillas
-- reutilizan la arquitectura de la quintilla, así que traen sus esquemas **con la frecuencia que
-- tienen como quintilla suelta**. Por eso `aabba` sale «admitida» en la segunda mitad, donde
-- Morley y Bruerton dicen que en Lope es **siempre** esa, y `abaab` sale «admitida» donde Navarro
-- dice que llegó a valer por la estrofa entera. `modalidad` vive en `esquemas_rima`, que pertenece
-- a una sola arquitectura, y no hay modalidad por *(sección, esquema)*. Afecta a las dieciocho
-- reutilizaciones del catálogo. Decisión del IP: **decirlo en prosa ahora y arreglar el modelo
-- después**; queda anotado en cuestiones.
--
-- Lo demás es prosa que sobraba o hablaba como la herramienta: la descripción de la arquitectura
-- repetía la definición, la nota del rasgo explicaba lo que hace el editor, la descripción del
-- esquema métrico repetía por tercera vez lo de los quebrados y las dos notas de parte decían lo
-- que la ficha ya deriva. Y se añade el contraste con la novena, que es su vecina más cercana
-- desde que las dos declaran el quiebro.

begin;

do $$
declare
	v_copla uuid;
	v_novena uuid;
	v_sextilla uuid;
	v_redondilla uuid;
	v_arq uuid;
	v_rasgo uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be';
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42';
	v_dc14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb';
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Estrofa de diez octosílabos organizada en dos quintillas separadas por una pausa '
		|| 'estructural. Cada quintilla lleva sus propias rimas consonantes, sin ninguna común a '
		|| 'las dos, y ambas pueden repetir o no el mismo esquema; esa independencia es lo que la '
		|| 'separa de la décima espinela. Admite que uno o dos versos aparezcan quebrados. La '
		|| 'libertad de combinar las disposiciones es más teórica que real: en el teatro de Lope '
		|| 'la segunda quintilla es siempre `aabba` y la primera casi siempre `ababa`, y antes, en '
		|| 'el siglo XV, la combinación `abaab:cdccd` llegó a valer por la estrofa entera.';

	c_arquitectura constant text :=
		'Diez octosílabos. El quiebro, cuando lo hay, cae en uno o dos versos y suele ser '
		|| 'tetrasílabo; si tiene cinco sílabas, se compensa con el octosílabo anterior.';

	c_nota_rasgo constant text :=
		'El quiebro cae sobre todo en la segunda mitad de la estrofa, y la tradición no fija en '
		|| 'qué verso.';

	c_nota_novena constant text :=
		'Las dos reparten octosílabos consonantes en dos miembros con rimas independientes, y se '
		|| 'separan por cómo los reparten: la copla real junta dos quintillas, cinco y cinco, y la '
		|| 'novena una redondilla con una quintilla, cuatro y cinco o cinco y cuatro. Las dos '
		|| 'admiten que algún verso se quiebre.';

	c_mb_sextilla constant text :=
		'No definen la sextilla como forma independiente en su repertorio de Lope de Vega. Reúnen '
		|| 'bajo «coplas» las estrofas breves que no encajan en definiciones más específicas, y '
		|| 'describen aparte las coplas de pie quebrado como octosílabos combinados con su '
		|| 'quebrado de cuatro o cinco sílabas, en estrofas de cinco a doce versos.';

	c_quilis_sextilla constant text :=
		'Define la sextilla como estrofa de versos de arte menor «con varias combinaciones de '
		|| 'rima: aabaab, abcabc, ababab, **etc.**». La enumeración queda expresamente abierta. '
		|| 'Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge '
		|| 'Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son '
		|| 'tetrasílabos, y documenta también una variante con los quebrados en segundo y quinto '
		|| 'lugar. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando '
		|| 'como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez '
		|| 'Caparrós escribe un guion.';

	c_navarro_sextilla constant text :=
		'Documenta la sextilla alterna ababab desde el repertorio juglaresco y la sextilla '
		|| 'simétrica de tres rimas aab:ccb, junto a la variante de dos abb:abb. Señala que, fuera '
		|| 'de su papel en las coplas de pie quebrado, la sextilla de octosílabos plenos se usó '
		|| 'escasamente, y que aparece a veces en formas libres y asimétricas con algún quebrado. '
		|| 'Establece cuatro sílabas como medida general del quebrado del octosílabo, con el '
		|| 'pentasílabo como forma alternativa y complementaria, y las de tres y cinco como menos '
		|| 'corrientes. En el siglo XIX registra la sextilla del Martín Fierro, abbccb, con el '
		|| 'primer verso suelto y sin eludir del todo la asonancia, y la sextilla aguda aaé:bbé.';

	c_dc14_sextilla constant text :=
		'Llama sextilla a toda estrofa de seis versos de arte menor con rima consonante. La '
		|| 'ejemplifica con las sextillas octosílabas del *Martín Fierro*, de José Hernández, cuyo '
		|| 'esquema escribe `- a a b b a`: el primer verso queda sin rima. El poema de Manuel '
		|| 'Machado que cita en heptasílabos rima `aababa`. Describe la copla de Jorge Manrique '
		|| 'como copla de pie quebrado de esquema 8a 8b 4c 8a 8b 4c, y explica que cuando el '
		|| 'quebrado tiene cinco sílabas métricas la medida se resuelve por sinafía o compensación '
		|| 'con el octosílabo anterior. Recoge que se ha considerado también estrofa de doce versos '
		|| 'cuando el sentido enlaza dos sextillas, aunque las rimas son siempre distintas en cada '
		|| 'una.';

	c_navarro_redondilla constant text :=
		'En nota al epígrafe de la copla de pie quebrado documenta la redondilla quebrada de los '
		|| 'cancioneros del siglo XV: la cruzada abab en serie de siete unidades en los *Loores a '
		|| 'la Virgen* de Fernán Pérez de Guzmán, y la abrazada abba entre las coplas sueltas de '
		|| 'Álvarez Gato.';
begin
	select forma_id into v_copla from public.formas_metricas where slug = 'copla_real';
	select forma_id into v_novena from public.formas_metricas where slug = 'novena';
	select forma_id into v_sextilla from public.formas_metricas where slug = 'sextilla';
	select forma_id into v_redondilla from public.formas_metricas where slug = 'redondilla';
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';

	if v_copla is null or v_novena is null or v_sextilla is null
		or v_redondilla is null or v_rasgo is null
	then
		raise exception 'Falta alguna de las cuatro formas o el rasgo del quebrado.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_copla and slug = 'octosilabica_consonante' and activo;
	if v_arq is null then
		raise exception 'La copla real no tiene su arquitectura activa.';
	end if;

	-- ============================================ El reparto de fuentes se deshace
	-- Primero se integran las cuatro precisiones en las afirmaciones de la sextilla, y solo
	-- después se borran las del rasgo: así nada se pierde entre medias.
	update public.afirmaciones_fuentes_metricas set resumen = c_mb_sextilla
	where forma_id = v_sextilla and fuente_id = v_mb;

	update public.afirmaciones_fuentes_metricas set resumen = c_quilis_sextilla
	where forma_id = v_sextilla and fuente_id = v_quilis;

	update public.afirmaciones_fuentes_metricas set resumen = c_navarro_sextilla
	where forma_id = v_sextilla and fuente_id = v_navarro;

	update public.afirmaciones_fuentes_metricas set resumen = c_dc14_sextilla
	where forma_id = v_sextilla and fuente_id = v_dc14;

	-- Las cuatro precisiones están dichas donde tienen que estarlo.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_sextilla
		and (
			(fuente_id = v_mb and resumen like '%de cinco a doce versos.')
			or (fuente_id = v_quilis and resumen like '%en segundo y quinto lugar%')
			or (fuente_id = v_navarro and resumen like '%medida general del quebrado%')
			or (fuente_id = v_dc14 and resumen like '%sinafía o compensación%')
		);
	if v_n <> 4 then
		raise exception 'Solo % de las cuatro precisiones del quiebro han llegado a la sextilla.', v_n;
	end if;

	-- La redondilla gana la suya, que es la fuente por la que declara el rasgo.
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_redondilla and fuente_id = v_navarro and localizador = '§ 68, nota 18'
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		values (v_navarro, v_redondilla, '§ 68, nota 18', c_navarro_redondilla, 'alta');
	else
		update public.afirmaciones_fuentes_metricas set resumen = c_navarro_redondilla
		where forma_id = v_redondilla and fuente_id = v_navarro and localizador = '§ 68, nota 18';
	end if;

	-- Y el rasgo se queda sin bibliografía propia: ninguna fuente habla del quiebro en abstracto.
	delete from public.afirmaciones_fuentes_metricas where rasgo_id = v_rasgo;

	if exists (select 1 from public.afirmaciones_fuentes_metricas where rasgo_id is not null) then
		raise exception 'Quedan afirmaciones colgando de un rasgo.';
	end if;

	-- ================================================= La prosa de la copla real
	select definicion into v_actual from public.formas_metricas where forma_id = v_copla;
	if v_actual not like '%uno o dos versos aparezcan quebrados.'
		and v_actual is distinct from c_definicion
	then
		raise exception 'La definición de la copla real no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_copla;

	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual not like '%Uno o dos pueden ser quebrados.'
		and v_actual is distinct from c_arquitectura
	then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_arquitectura
	where arquitectura_id = v_arq;

	select nota into v_actual from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;
	if v_actual not like '%lo observa el editor%' and v_actual is distinct from c_nota_rasgo then
		raise exception 'La nota del pie quebrado no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitectura_rasgos set nota = c_nota_rasgo
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;

	-- La descripción del esquema métrico decía por tercera vez lo de los quebrados.
	update public.esquemas_metricos set descripcion = null
	where arquitectura_id = v_arq and descripcion is not null;

	-- Y las dos notas de parte decían lo que la ficha deriva del propio reparto.
	update public.estructuras_secciones set nota = null
	where arquitectura_id = v_arq and nota is not null;

	get diagnostics v_n = row_count;
	if v_n <> 2 then
		raise exception 'Se han retirado % notas de parte, no las dos esperadas.', v_n;
	end if;

	-- ================================================= El contraste con la novena
	if not exists (
		select 1 from public.forma_relaciones
		where tipo_relacion = 'contrasta_con'
			and ((forma_origen_id = v_copla and forma_destino_id = v_novena)
				or (forma_origen_id = v_novena and forma_destino_id = v_copla))
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota)
		values (v_copla, v_novena, 'contrasta_con', c_nota_novena);
	else
		update public.forma_relaciones set nota = c_nota_novena
		where tipo_relacion = 'contrasta_con'
			and ((forma_origen_id = v_copla and forma_destino_id = v_novena)
				or (forma_origen_id = v_novena and forma_destino_id = v_copla));
	end if;

	-- ============================================================ Comprobaciones
	-- Ninguna de las cuatro fichas trae ya una nota de fuente que hable de otra estrofa.
	foreach v_actual in array array['copla_real', 'novena', 'redondilla', 'sextilla'] loop
		select count(*) into v_n
		from jsonb_array_elements(public.get_forma_metrica_publica(v_actual) -> 'afirmaciones') a
		where a ? 'rasgo_id' and a ->> 'rasgo_id' is not null;
		if v_n <> 0 then
			raise exception 'La ficha de % sigue trayendo % afirmaciones de rasgo.', v_actual, v_n;
		end if;
	end loop;

	-- Y la redondilla trae la suya, que es nueva.
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('redondilla') -> 'afirmaciones'
		) a
		where a ->> 'localizador' = '§ 68, nota 18'
	) then
		raise exception 'La redondilla no trae su afirmación sobre el quiebro.';
	end if;
end $$;

commit;
