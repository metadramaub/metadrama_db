-- El cuarteto: definición, denominaciones y las seis fuentes.
--
-- Novena forma de la revisión. No tenía **ninguna** afirmación ni ninguna denominación, y sus
-- dos esquemas de rima ya quedaron descritos al revisar el soneto, que los reutiliza.
--
-- 1 · **La definición llevaba «serventesio» en prosa.** Ese nombre no es de la forma sino de
--     una de sus dos disposiciones —la cruzada—, y `denominaciones_metricas` admite colgar de
--     un esquema de rima, como ya se hizo con «Cuarteta» en la redondilla. Con él entran los
--     otros dos que documenta el Diccionario: «cuarteto de rima cruzada» y «faleucio».
--
-- 2 · **La arquitectura decía «Cuatro endecasílabos consonantes»**, que es la definición menos
--     una palabra. Arquitectura única, nada que distinguir: se queda vacía.
--
-- Lo que las fuentes aclaran, y que la definición no decía:
--
-- · **Cuarteto y redondilla son la misma estrofa, separada por el arte del verso.** Lo dice
--   Caparrós 2014 sin rodeos: cuatro versos con dos clases de rima; si son de arte menor es
--   redondilla y si son de arte mayor, cuarteto. La definición pasa a decirlo, porque explica
--   de una vez por qué el catálogo tiene dos formas que comparten disposición.
--
-- · **La preferencia de disposición no es universal.** El catálogo marca `ABBA` como
--   preferente, que es lo que corresponde al corpus áureo —es la del soneto—. Navarro Tomás,
--   mirando la poesía del siglo XX, dice que el tipo más frecuente es el cruzado `ABAB`. No se
--   cambia nada: se registra, porque explica por qué otras fuentes ordenan al revés.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_abab uuid;
	v_dicc uuid;
	v_cap14 uuid;
	v_mb uuid;
	v_quilis uuid;
	v_navarro uuid;
	v_jauralde uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'cuarteto';
	select arquitectura_id into v_arq from public.arquitecturas_forma where forma_id = v_forma;
	select esquema_rima_id into v_abab from public.esquemas_rima
	where arquitectura_id = v_arq and notacion = 'ABAB';

	select fuente_id into v_dicc from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_cap14 from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo not like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';
	select fuente_id into v_quilis from public.fuentes_metricas where autoria like '%Quilis%';
	select fuente_id into v_navarro from public.fuentes_metricas where autoria like '%Navarro Tomás%';
	select fuente_id into v_jauralde from public.fuentes_metricas where autoria like '%Jauralde%';

	if v_forma is null or v_arq is null or v_abab is null then
		raise exception 'Falta el cuarteto, su arquitectura o su esquema cruzado';
	end if;
	if num_nonnulls(v_dicc, v_cap14, v_mb, v_quilis, v_navarro, v_jauralde) <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de cuatro versos de arte mayor con rima consonante repartida en dos clases, abrazada o cruzada. Es la misma estrofa que la redondilla, de la que solo la separa el arte del verso.'
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = null
	where arquitectura_id = v_arq;

	-- «Serventesio» nombra la disposición cruzada, no la forma.
	insert into public.denominaciones_metricas
		(esquema_rima_id, nombre, slug_normalizado, preferente)
	values
		(v_abab, 'Serventesio', 'serventesio', false),
		(v_abab, 'Cuarteto de rima cruzada', 'cuarteto_de_rima_cruzada', false),
		(v_abab, 'Faleucio', 'faleucio', false)
	on conflict do nothing;

	-- Las fuentes.
	delete from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma or arquitectura_id = v_arq;

	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, localizador, resumen, confianza)
	values
		-- Lo que separa al cuarteto de la redondilla, dicho sin rodeos.
		(v_cap14, v_forma, 'p. 188',
			'Trata cuarteto y redondilla como la misma estrofa de cuatro versos con dos clases de rima consonante, separadas solo por el arte del verso: «si los versos son de arte mayor, se llama cuarteto». En nota advierte además que entre los tratadistas del Siglo de Oro «redondilla» designaba en primer lugar la quintilla, y también estrofas de cuatro a ocho versos de arte menor y coplas de pie quebrado.',
			'alta'),

		-- Que el nombre cubre las dos disposiciones.
		(v_dicc, v_forma, 'Entrada «cuarteto», p. 96',
			'Define el cuarteto incluyendo las dos disposiciones bajo un mismo nombre: riman el primero con el tercero y el segundo con el cuarto, **o** el primero con el cuarto y el segundo con el tercero.',
			'alta'),

		-- Y cómo se llama la cruzada.
		(v_dicc, v_forma, 'Entrada «serventesio», p. 385',
			'Reserva «serventesio» para la disposición cruzada del cuarteto de arte mayor, y recoge «cuarteto de rima cruzada» y «faleucio» como otros nombres suyos.',
			'alta'),

		-- La misma relación, desde otra fuente.
		(v_quilis, v_forma, 'p. 94',
			'Da ABBA como la rima del cuarteto y trata el serventesio como variante suya, que se diferencia únicamente en la distribución de la rima.',
			'alta'),

		-- Que la disposición preferente no es la misma en todas las épocas.
		(v_navarro, v_forma, '§ 463',
			'Observa que en la poesía del siglo XX el tipo más frecuente es el de endecasílabos con rimas cruzadas, ABAB, y que la variedad abrazada aparece menos. En el corpus áureo la relación es la inversa, porque la abrazada es la del soneto.',
			'alta'),

		-- El nombre, desde la definición más escueta.
		(v_jauralde, v_forma, '«Estrofas de cuatro versos»',
			'Define el serventesio como sucesión de cuatro versos endecasílabos con rima cruzada, y precisa que al cuarteto endecasilábico cruzado se lo suele denominar así.',
			'alta'),

		-- Y dónde aparece en la bibliografía sobre la que se data a Lope.
		(v_mb, v_forma, 'Cap. V',
			'No lo definen como forma independiente: el cuarteto aparece en su descripción de los sueltos, como uno de los cierres posibles de un pasaje.',
			'media');
	get diagnostics v_n = row_count;

	raise notice 'Cuarteto · definición, 3 denominaciones y % afirmaciones sobre seis fuentes', v_n;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
