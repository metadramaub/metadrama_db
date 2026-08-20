-- Morley y Bruerton no registran la novena
--
-- Al revisar la novena se anotó como cuestión que le faltaba la afirmación de Morley y Bruerton y
-- que su texto no estaba entre los `.txt` de la bibliografía. **Sí estaba**: es
-- `definiciones_Morley&Bruerton.md`, en `.md` y no en `.txt`, que es por lo que las búsquedas no
-- lo encontraban.
--
-- Leído, la respuesta es la que se sospechaba y merece constar, como consta en el sexteto y en la
-- copla de arte mayor: **su repertorio de metros españoles no tiene ninguna estrofa de nueve
-- versos**. Define la redondilla, la quintilla, la copla real, la décima, el romance, la
-- seguidilla y el pareado, y reúne aparte, bajo «coplas», «las estrofas cortas que no se incluyen
-- en definiciones más específicas» — que es donde una novena caería.
--
-- De paso se contrastaron con el texto las seis afirmaciones suyas de más peso —quintilla,
-- décima, seguidilla, lira, soneto y terceto—: **las seis son fieles**, y no se toca ninguna.

begin;

do $$
declare
	v_forma uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_n integer;

	c_mb constant text :=
		'Su repertorio de metros españoles no incluye ninguna estrofa de nueve versos: define la '
		|| 'redondilla, la quintilla, la copla real, la décima, el romance, la seguidilla y el '
		|| 'pareado, y reúne aparte, bajo «coplas», las estrofas cortas que no se incluyen en '
		|| 'definiciones más específicas, que es donde la novena caería.';
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'novena';
	if v_forma is null then
		raise exception 'No existe la novena.';
	end if;

	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_forma and fuente_id = v_mb
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		values (
			v_mb, v_forma,
			'Capítulo «Definición de las Formas Métricas», epígrafes «Coplas» y «Metros Españoles»',
			c_mb, 'alta'
		);
	else
		update public.afirmaciones_fuentes_metricas set resumen = c_mb
		where forma_id = v_forma and fuente_id = v_mb;
	end if;

	-- La novena queda con las seis, una por monografía, como las formas mejor documentadas.
	select count(distinct fuente_id) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La novena cita % fuentes distintas, no las seis.', v_n;
	end if;

	if not exists (
		select 1 from jsonb_array_elements(
			public.get_forma_metrica_publica('novena') -> 'afirmaciones'
		) a
		where a ->> 'fuente_id' = v_mb::text
	) then
		raise exception 'La ficha de la novena no trae la afirmación de Morley y Bruerton.';
	end if;
end $$;

commit;
