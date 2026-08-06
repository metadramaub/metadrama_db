-- El romance: quitar lo que se decía dos veces y rehacer sus fuentes.
--
-- Tres correcciones, y de las tres sale una norma que valdrá para las 32 formas restantes.
--
-- 1 · **Lo mismo dicho dos veces.** La ficha imprimía seguidas estas dos frases:
--
--       descripción del esquema · «Ciclo de dos versos: el impar queda suelto y el par
--                                  mantiene la misma clase de asonancia durante toda la serie.»
--       nota del enlace         · «La misma asonancia de los versos pares se conserva al
--                                  repetir el ciclo.»
--
--     No hay matiz entre ellas: son la misma afirmación. El reparto correcto es que la
--     descripción diga la **forma del ciclo** y el enlace diga **qué se conserva al repetirlo**,
--     que es justo lo que distingue `[-a]…` de `[aA]…`. Y la frase del enlace no hace falta
--     escribirla: `describirEnlace` la deriva del dato —«El verso 2 conserva su rima en cada
--     repetición»— y así no puede desviarse de él. Se vacían las cuatro notas y se recorta la
--     descripción. Las notas de la redondilla doble, el terceto encadenado y el zéjel se
--     quedan: esas dicen algo que la derivación no alcanza.
--
-- 2 · **Las fuentes no añadían nada.** Las tres afirmaciones anteriores parafraseaban la
--     definición en vez de completarla. Una fuente entra cuando dice algo que la definición
--     no lleva; si repite, sobra. Se rehacen las seis afirmaciones desde el texto de los
--     volúmenes, y cada una responde a «¿qué sé después de leerla que no supiera antes?».
--
-- 3 · **Se usaban dos fuentes de seis.** Las otras cuatro sí hablan del romance, y cada una
--     desde un sitio distinto: Navarro Tomás por el origen del verso, Caparrós 2014 por su
--     regularización, Quilis por su cronología y Jauralde por su encaje entre las series y
--     por las medidas que el catálogo no recoge. Ahora están las seis.
--
-- Los localizadores dejan de decir «s. v.», que es abreviatura de especialista, y dicen la
-- entrada o la página en castellano llano. Página donde el volumen la conserva —Caparrós 2014
-- y el Diccionario la traen íntegra, Quilis por pliegos de dos—; epígrafe numerado en Navarro
-- Tomás, que solo conserva 37 números en todo el libro; y título de sección en Jauralde, que
-- viene de un epub sin paginar. Comprobado con `scripts/lib/localizar.mjs`.

begin;

do $$
declare
	v_forma uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_hepta uuid;
	v_notas integer;
	v_borradas integer;
	v_escritas integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	select arquitectura_id into v_hepta from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'heptasilabica';

	if v_forma is null or v_hepta is null then
		raise exception 'Falta el romance o su arquitectura heptasilábica';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- 1 · Que cada frase diga una cosa.
	update public.esquema_rima_enlaces en
	set nota = null
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	where en.esquema_rima_id = er.esquema_rima_id
		and a.forma_id = v_forma
		and en.nota is not null;
	get diagnostics v_notas = row_count;

	update public.esquemas_rima er
	set descripcion = 'Ciclo de dos versos: el impar queda suelto y el par lleva la asonancia.'
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id and a.forma_id = v_forma;

	-- 2 y 3 · Las fuentes, rehechas: una afirmación por cosa que la fuente añade.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma
		or arquitectura_id in (
			select arquitectura_id from public.arquitecturas_forma where forma_id = v_forma
		);
	get diagnostics v_borradas = row_count;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	values
		-- Lo que el Diccionario añade a una definición que por lo demás es la misma.
		(v_dicc, v_forma, null, 'Entrada «romance», p. 363',
			'Añade dos rasgos que la definición no recoge: el romance puede estar dividido por el sentido en grupos de cuatro versos, y admite estribillos o canciones intercalados, sean octosílabos o de otra medida.',
			'alta'),

		-- Por qué la medida es aquí una arquitectura: cada una tiene nombre propio.
		(v_dicc, v_forma, null, 'Entradas «romancillo» (p. 370), «endecha» (p. 148) y «romance heroico» (p. 368)',
			'Cuando el romance se compone en versos distintos del octosílabo recibe denominaciones específicas: romancillo el de versos de menos de ocho sílabas —lo que cubre por igual el hexasílabo y el heptasílabo— y romance heroico el endecasílabo.',
			'alta'),

		-- El nombre que la tradición da al heptasílabo, y por qué no es una identidad métrica.
		(v_dicc, null, v_hepta, 'Entrada «endecha», p. 148',
			'«Endecha» nombra el asunto antes que la forma. Es un poema de tema luctuoso que suele componerse en romancillo heptasílabo, pero admite versos de cinco o de seis sílabas y pareados de doce, y hay endechas en redondillas o en versos sueltos. Por eso figura aquí como denominación y no como identidad de la arquitectura.',
			'alta'),

		-- De dónde sale el octosílabo: el verso largo primitivo, partido.
		(v_navarro, v_forma, null, '§ 25, «Pie de romance»',
			'El verso de los romances primitivos —el pie de romance que nombró Nebrija— era de medida variable, y no la simple suma de dos octosílabos regulares. El octosílabo del romance es el resultado de partir y regularizar aquel verso largo, no su punto de partida.',
			'alta'),

		-- Cuándo deja de fluctuar y entra en la poesía culta.
		(v_cap14, v_forma, null, 'p. 223',
			'El verso largo de los romances viejos, fluctuante sobre la base de dos hemistiquios octosílabos, se regulariza en el siglo XVI y el romance se incorpora entonces como forma muy usada también en la poesía culta.',
			'alta'),

		-- Por qué pesa tanto en este corpus.
		(v_quilis, v_forma, null, 'pp. 150-151',
			'Sitúa en el Barroco el punto culminante del desarrollo del romance, tanto en el de tipo popular como en el culto. Es la razón de que sea la forma más frecuente del corpus.',
			'alta'),

		-- Dónde encaja en la clasificación, y qué medidas quedan fuera del catálogo.
		(v_jauralde, v_forma, null, '«Series» → «El romance y el romancillo»',
			'Lo clasifica entre las series y no entre las estrofas, y extiende el nombre de romancillo a los pentasílabos y tetrasílabos además del heptasílabo y el hexasílabo. Sitúa el romance heroico en la segunda mitad del siglo XVII, con ejemplos sueltos anteriores, de modo que en el teatro áureo es una realización tardía y rara.',
			'alta'),

		-- Los nombres tal como los maneja la bibliografía sobre la que se data a Lope.
		(v_mb, v_forma, null, 'Cap. V, «Romance»',
			'Nombra las variedades por su medida: romancillo o endechas en seis y siete sílabas, romance heroico o romance real en once.',
			'alta');
	get diagnostics v_escritas = row_count;

	raise notice 'Romance · notas de enlace vaciadas: % · afirmaciones retiradas: % · escritas: % (seis fuentes)',
		v_notas, v_borradas, v_escritas;
end $$;

comment on column public.esquema_rima_enlaces.nota is
	'Solo cuando la frase derivada del enlace se queda corta. La ficha imprime `nota` si existe y, si no, la deriva de las posiciones y el desplazamiento —«El verso 2 conserva su rima en cada repetición»—. Escribir a mano lo que ya se deriva duplica la frase con la descripción del esquema y se desvía del dato en cuanto uno de los dos cambia.';

comment on column public.esquemas_rima.descripcion is
	'La forma del esquema, no lo que ocurre al repetirlo: eso lo dice `esquema_rima_enlaces`, o su ausencia. Es la diferencia entre `[-a]…` y `[aA]…`, que se escriben igual y no se comportan igual.';

comment on column public.afirmaciones_fuentes_metricas.resumen is
	'Lo que la fuente **añade** a la definición, no una paráfrasis suya. Si al leerla no se sabe nada que no dijera ya la definición, la afirmación sobra. Se aspira a que las seis fuentes digan algo de cada forma; la que no tenga nada propio que decir, se calla.';

comment on column public.afirmaciones_fuentes_metricas.localizador is
	'En castellano llano, sin abreviaturas de especialista. Página donde el volumen la conserva, epígrafe numerado en Navarro Tomás, título de sección en Jauralde —que viene de un epub sin paginar— y nombre de la entrada en el Diccionario, que es alfabético. `scripts/lib/localizar.mjs` da la página de un pasaje sobre los volcados de `docs/dominio-metrico/bibliografía/txt/`.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
