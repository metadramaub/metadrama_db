-- El verso aislado pasa de dos fuentes a cinco
--
-- Tres lagunas de la fase 4 en el mismo tramo sin forma, y las tres de las que no se ven leyendo la
-- ficha: **una fuente que calla no deja hueco**, y solo mirando forma por forma se descubre que
-- tres de las seis trataban el verso aislado de frente y no se les había preguntado.
--
--   1969  Quilis, § 5.0, p. 87 — **abre con él el capítulo entero de la estrofa**, para negarle
--         entidad. Comprobado en el PDF: hoja 44, pie «87».
--   2014  Domínguez Caparrós, pp. 36 y 184 — le da nota bibliográfica propia y una respuesta
--         contraria a la de Quilis. Comprobado: hojas 33 y 181.
--   2020  Jauralde, «Estrofas o poemas de un solo verso» — **epígrafe propio**, comprobado en el
--         epub como `h5` entre «Poliestrofismo» y «Estrofas de pareados». El volcado aplana los
--         niveles y ahí no se distingue de un rótulo del cuerpo.
--
-- ══ Lo que enseñan puestas juntas, y por qué ninguna lo dice
--
-- Las cuatro voces que quedan en la ficha **no responden lo mismo** a la duda que la propia
-- definición del catálogo plantea. Quilis: «un verso aislado no es realmente nada, ni siquiera un
-- verso». Caparrós y Jauralde: sí lo es, y por la misma razón —implica una serie, «en el recuerdo de
-- un patrón» el uno, «in absentia» el otro—. El *Diccionario* deja que «siempre podrá discutirse».
--
-- **Ninguna de las afirmaciones dice eso**, porque comparar fuentes no es trabajo de una fuente: la
-- sección lo enseña al ponerlas seguidas, que es para lo que existe. Queda anotado como el segundo
-- caso del catálogo —tras el nombre de italiana en la octava aguda— que pediría un párrafo de
-- cabecera que resumiera la disparidad, si alguna vez se decide que haga falta.
--
-- ══ Y el mote
--
-- El 16 de septiembre salió de la definición del verso aislado, con el argumento de que el trabajo
-- de modelo lo hace la definición o lo hace una forma, y de que su sitio eran las fuentes. Con esto
-- queda documentado dos veces ahí: el *Diccionario* ya decía que es «el caso más apreciable», y
-- Jauralde lo pone al frente de su lista de motes, emblemas, refranes y sentencias.
--
-- Textos aprobados por David el 18 de septiembre de 2026.

begin;

do $$
declare
	v_forma constant uuid := (select forma_id from public.formas_metricas where nombre = 'Verso aislado');
	v_quilis constant uuid := (select fuente_id from public.fuentes_metricas where anio = 1969);
	v_capar constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2014);
	v_jaur constant uuid := (select fuente_id from public.fuentes_metricas where anio = 2020);
	v_loc_1969 constant text := '§ 5.0, p. 87';
	v_loc_2014 constant text := 'pp. 36 y 184';
	v_loc_2020 constant text := 'Apartado «Estrofas o poemas de un solo verso»';
	v_res_1969 constant text :=
		'Abre con él el capítulo de la estrofa, para negarle entidad: «un verso aislado no es realmente '
		'nada, ni siquiera un verso: es una sentencia o un enunciado de cualquier tipo. Para que un '
		'verso pueda ser considerado como tal, tiene que estar con otro u otros versos, en función de '
		'una unidad superior a ellos mismos que llamamos estrofa».';
	v_res_2014 constant text :=
		'Lo trata como problema declarado, con nota bibliográfica propia que remite a D. Devoto, y le '
		'da respuesta: «parece imprescindible, para la existencia del verso, el que se inserte en una '
		'serie. Habría que decir entonces que, en el caso del verso aislado, este **se integra en el '
		'recuerdo de un patrón e implica, por tanto, una serie**». Recoge además, en nota, que «el '
		'verso único es para Navarro Tomás "como un embrión de estrofa"», y que Jauralde condiciona el '
		'verso a la aparición de un elemento reiterado, de modo que la preceptiva clásica reservaba '
		'«para el verso solitario, pues no lo era, el nombre de mote, lema, sentencia, etc.».';
	v_res_2020 constant text :=
		'Le da epígrafe propio. Plantea la objeción —«si definimos la estrofa como agrupación de '
		'versos, no podría existir la estrofa de un solo verso, como no podría denominarse verso a uno '
		'solo, si es que no se ha extraído de un conjunto»— y la resuelve: «el verso único puede '
		'funcionar como estrofa y como poema, en cada caso, porque se relaciona *in absentia* con '
		'versos semejantes». Sitúa su procedencia: «la mayoría de las veces, con todo, el verso único '
		'pertenece al género prepoético de los motes, emblemas, refranes, sentencias, pie de glosa, '
		'estribillo, etc.». Y distingue el verso suelto que ocupa el lugar de una estrofa dentro de un '
		'poema, «muy frecuente en poesía contemporánea», del poema de un solo verso, del que da '
		'repertorio por medidas, del bisílabo al endecasílabo y más allá.';
	v_cuantas integer;
	v_antes bigint;
	v_despues bigint;
begin
	if v_forma is null or v_quilis is null or v_capar is null or v_jaur is null then
		raise exception 'No encuentro el verso aislado o alguna de las tres fuentes.';
	end if;

	-- Que es el tramo sin forma que creo, y no otra cosa con el mismo nombre.
	select count(*) into v_cuantas
	from public.formas_metricas
	where forma_id = v_forma and tipo_registro = 'sin_forma' and nivel_estructural = 'verso';
	if v_cuantas <> 1 then
		raise exception 'El verso aislado no es el tramo sin forma que espero.';
	end if;

	-- Que hoy habla con dos voces, Navarro y el Diccionario, y con ninguna de estas tres.
	select count(distinct fuente_id) into v_cuantas
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_cuantas <> 2 then
		raise exception 'El verso aislado habla con % fuentes y esperaba dos.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and fuente_id in (v_quilis, v_capar, v_jaur);
	if v_cuantas <> 0 then
		raise exception 'Alguna de las tres fuentes tiene ya afirmación aquí.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		(v_quilis, v_forma, v_loc_1969, v_res_1969, 'alta'),
		(v_capar, v_forma, v_loc_2014, v_res_2014, 'alta'),
		(v_jaur, v_forma, v_loc_2020, v_res_2020, 'alta');

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que las tres quedaron exactamente con el texto que David aprobó.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		and ((fuente_id = v_quilis and localizador = v_loc_1969 and resumen = v_res_1969)
			or (fuente_id = v_capar and localizador = v_loc_2014 and resumen = v_res_2014)
			or (fuente_id = v_jaur and localizador = v_loc_2020 and resumen = v_res_2020));
	if v_cuantas <> 3 then
		raise exception 'Las tres afirmaciones no han quedado con el texto aprobado: cuadran %.', v_cuantas;
	end if;

	-- Que la ficha habla ya con cinco voces. **Cinco y no seis**: Morley y Bruerton no trata el verso
	-- aislado porque su repertorio es de formas que Lope usa, y ese silencio entrará con la tanda de
	-- los veinte de la fase 4, no aquí.
	select count(distinct fuente_id) into v_cuantas
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_cuantas <> 5 then
		raise exception 'El verso aislado habla con % fuentes y esperaba cinco.', v_cuantas;
	end if;
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	where a.forma_id = v_forma and f.anio = 1968;
	if v_cuantas <> 0 then
		raise exception 'Morley y Bruerton tiene ya afirmación aquí; esta migración daba por hecho que no.';
	end if;

	-- Que el mote queda documentado en las fuentes por partida doble, que es adonde se le mandó al
	-- sacarlo de la definición el 16 de septiembre.
	select count(*) into v_cuantas
	from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma and resumen like '%mote%';
	if v_cuantas < 2 then
		raise exception 'El mote solo aparece en % afirmaciones del verso aislado.', v_cuantas;
	end if;

	-- Y que la definición sigue sin él, que es la otra mitad de aquel reparto.
	select count(*) into v_cuantas
	from public.formas_metricas where forma_id = v_forma and definicion not like '%mote%';
	if v_cuantas <> 1 then
		raise exception 'El mote ha vuelto a la definición del verso aislado.';
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;
