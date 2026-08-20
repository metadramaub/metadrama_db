-- El endecasílabo suelto distingue el blanco del suelto
--
-- Revisión de su prosa. Salió afinado de la revisión de la silva —su rima, sus rasgos y la
-- frontera entre los dos están bien— y lo que quedaba es esto.
--
-- 1. **Jauralde distingue dos cosas que la ficha igualaba.** «La desaparición **sistemática** de
--    la rima, que llama **verso blanco**, de la **esporádica**, que llama **verso suelto**.» El
--    catálogo tiene justo ese matiz declarado, como los dos valores de densidad —`ninguna`
--    definitoria y `esporadica` admitida—, pero en «También llamada» los tres nombres salían al
--    mismo nivel como si dieran igual, y la distinción vivía escondida en la nota de un valor. Va
--    a la definición, que es donde se lee.
--
--    De paso, esa nota atribuía —«Jauralde llama verso blanco a…»—, y una nota da el dato: quién
--    lo dice está en las fuentes.
--
-- 2. **La descripción de la arquitectura hablaba como el gestor**, igual que la de la copla real:
--    «los pareados intercalados, el dístico final y el encadenamiento interior **los observa el
--    editor**». En su lugar dice lo que las fuentes destacan y la ficha callaba — para qué se usó
--    esta serie y qué exige.
--
-- 3. **El dístico final era `admitida` y las fuentes lo dan por corriente.** Morley y Bruerton,
--    que son quienes miden el corpus dramático, observan que «cada pasaje acaba **generalmente**
--    en un pareado», y la propia definición dice «suele cerrarse con un dístico». Pasa a
--    `habitual`.
--
-- 4. **Faltaba el final acentual.** El vocabulario legado tiene `endecasilabo_suelto_de_esdrujulos`
--    y esta forma no declaraba el rasgo, de modo que ese término no tendría dónde migrar. Es la
--    mitad del desajuste anotado al revisar la octava real —allí el soneto lo declara sin término
--    legado que lo respalde—; este lado se cierra ya, y la pregunta global sigue abierta.
--
-- Acompaña a esta migración un arreglo de la tarjeta: un rasgo de un solo valor se etiqueta con el
-- nombre del rasgo y no con el del valor, de modo que la ficha imprimía «Dístico final: Dístico
-- final» y «Encadenamiento interior: Encadenamiento interior».

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_rasgo_final uuid;
	v_valor_esdrujulo uuid;
	v_rasgo_distico uuid;
	v_rasgo_densidad uuid;
	v_valor_ninguna uuid;
	v_actual text;
	v_n integer;

	c_definicion constant text :=
		'Serie abierta de endecasílabos sin rima regular, en la que los versos sueltos predominan '
		|| 'sobre los rimados. Admite pareados intercalados de manera ocasional y suele cerrarse '
		|| 'con un dístico; una modalidad encadena la rima final de cada verso con el interior del '
		|| 'siguiente. Cuando la rima desaparece por completo se le llama verso blanco, y verso '
		|| 'suelto cuando alguna asoma sin llegar a organizar la serie. Nació del intento '
		|| 'renacentista de acercar el verso romance al latino, que prescinde de la rima.';

	c_descripcion constant text :=
		'Serie abierta de endecasílabos en la que predominan los versos sueltos. Se empleó sobre '
		|| 'todo en epístolas, sátiras y traducciones, donde buscar la rima habría forzado el '
		|| 'texto, y se recomendó para el asunto heroico. Al renunciar a la rima exige más trabajo '
		|| 'del verso, porque cualquier prosaísmo se nota enseguida.';

	c_nota_ninguna constant text :=
		'Cuando la rima desaparece del todo, la serie se llama verso blanco.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecasilabo_suelto';
	if v_forma is null then
		raise exception 'No existe el endecasílabo suelto.';
	end if;

	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'endecasilabica' and activo;
	if v_arq is null then
		raise exception 'El endecasílabo suelto no tiene su arquitectura activa.';
	end if;

	-- ------------------------------------------------------------------- 1. La distinción
	select definicion into v_actual from public.formas_metricas where forma_id = v_forma;
	if v_actual not like '%que prescinde de la rima.' and v_actual is distinct from c_definicion then
		raise exception 'La definición no es la esperada. Acaba: %', right(v_actual, 60);
	end if;
	update public.formas_metricas set definicion = c_definicion where forma_id = v_forma;

	select rasgo_id into v_rasgo_densidad from public.rasgos_metricos where slug = 'densidad_de_rima';
	select valor_id into v_valor_ninguna
	from public.rasgo_valores where rasgo_id = v_rasgo_densidad and slug = 'ninguna';

	select nota into v_actual from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo_densidad and valor_id = v_valor_ninguna;

	if not found then
		raise exception 'El endecasílabo suelto no declara la densidad «ninguna».';
	end if;
	if v_actual not like 'Jauralde llama verso blanco%' and v_actual is distinct from c_nota_ninguna
	then
		raise exception 'La nota de la densidad «ninguna» no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitectura_rasgos set nota = c_nota_ninguna
	where arquitectura_id = v_arq and rasgo_id = v_rasgo_densidad and valor_id = v_valor_ninguna;

	-- ------------------------------------------------------------- 2. La descripción
	select descripcion into v_actual from public.arquitecturas_forma where arquitectura_id = v_arq;
	if v_actual not like '%los observa el editor.' and v_actual is distinct from c_descripcion then
		raise exception 'La descripción de la arquitectura no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitecturas_forma set descripcion = c_descripcion where arquitectura_id = v_arq;

	-- ------------------------------------------------------------- 3. El dístico final
	select rasgo_id into v_rasgo_distico from public.rasgos_metricos where slug = 'distico_final';

	select modalidad into v_actual from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo_distico;

	if not found then
		raise exception 'El endecasílabo suelto no declara el dístico final.';
	end if;
	if v_actual is distinct from 'admitida' and v_actual is distinct from 'habitual' then
		raise exception 'La modalidad del dístico final no es la esperada. Dice: %', v_actual;
	end if;
	update public.arquitectura_rasgos set modalidad = 'habitual'
	where arquitectura_id = v_arq and rasgo_id = v_rasgo_distico;

	-- ------------------------------------------------------------- 4. El final esdrújulo
	select rasgo_id into v_rasgo_final from public.rasgos_metricos where slug = 'final_acentual';
	select valor_id into v_valor_esdrujulo
	from public.rasgo_valores where rasgo_id = v_rasgo_final and slug = 'esdrujulo';

	if v_rasgo_final is null or v_valor_esdrujulo is null then
		raise exception 'No existe el rasgo «final_acentual» con valor «esdrujulo».';
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values (
		v_arq, v_rasgo_final, v_valor_esdrujulo, 'admitida',
		'Terminación esdrújula sostenida en los finales de verso.'
	)
	on conflict (arquitectura_id, rasgo_id, modalidad, valor_id) do update set nota = excluded.nota;

	-- Son ya seis las arquitecturas que lo declaran, y el término legado tiene adónde ir.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where a.activo and ar.rasgo_id = v_rasgo_final and ar.valor_id = v_valor_esdrujulo;
	if v_n <> 6 then
		raise exception 'Declaran el final esdrújulo % arquitecturas, no las seis esperadas.', v_n;
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('endecasilabo_suelto') -> 'arquitecturaRasgos'
		) r
		where r ->> 'rasgo_id' = v_rasgo_final::text
	) then
		raise exception 'La ficha no trae el final acentual del endecasílabo suelto.';
	end if;
	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('endecasilabo_suelto') -> 'arquitecturaRasgos'
		) r
		where r ->> 'rasgo_id' = v_rasgo_distico::text and r ->> 'modalidad' = 'habitual'
	) then
		raise exception 'La ficha no declara el dístico final como habitual.';
	end if;
end $$;

commit;
