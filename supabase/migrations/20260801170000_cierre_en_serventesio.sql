begin;

-- El terceto encadenado cierra con un serventesio, y ahora puede decirlo.
--
-- Su esquema se llama «Encadenamiento consonante con cierre en serventesio» desde el
-- principio, pero la estructura lo modelaba como una cadena de tercetos más **una sección de
-- un solo verso**: un terceto con un verso suelto detrás, no un serventesio.
--
-- Con el cuarteto en el catálogo ya se puede decir lo que es. La cola pasa a ser una sección
-- de cuatro versos que reutiliza la estrofa de cuatro versos de su propio arte:
--
--   endecasilábico  ->  cuarteto · endecasilabica, disposición cruzada: el serventesio
--   octosilábico    ->  redondilla · octosilabica, disposición cruzada: la cuarteta
--
-- La extensión no cambia: una cadena de n tercetos más un verso y una cadena de n-1 tercetos
-- más un serventesio son el mismo número de versos. Lo que cambia es que el modelo dice qué
-- es esa cola en vez de contarla.

do $$
declare
	v_arq record;
	v_cierre uuid;
	v_referencia uuid;
	v_cuarteto uuid;
	v_redondilla uuid;
begin
	select arquitectura.arquitectura_id into v_cuarteto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'cuarteto' and arquitectura.slug = 'endecasilabica';

	select arquitectura.arquitectura_id into v_redondilla
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and arquitectura.slug = 'octosilabica';

	for v_arq in
		select arquitectura.arquitectura_id, arquitectura.slug
		from public.arquitecturas_forma arquitectura
		join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
		where forma.slug = 'terceto_encadenado'
	loop
		v_referencia := case
			when v_arq.slug = 'octosilabico' then v_redondilla
			else v_cuarteto
		end;

		select seccion_id into v_cierre
		from public.estructuras_secciones
		where arquitectura_id = v_arq.arquitectura_id and tipo_seccion = 'cierre';

		if v_cierre is null then
			continue;
		end if;

		update public.estructuras_secciones
		set slug = 'serventesio',
			tipo_seccion = 'serventesio',
			nombre = case
				when v_arq.slug = 'octosilabico' then 'Cuarteta final'
				else 'Serventesio final'
			end,
			versos_min = 4,
			versos_max = 4,
			arquitectura_referenciada_id = v_referencia,
			nota = 'La cadena se cierra con una estrofa de cuatro versos cruzada, cuyas dos primeras clases vienen del último terceto.'
		where seccion_id = v_cierre;
	end loop;
end;
$$;

-- La relación con el cuarteto queda declarada: no es composición ni derivación, es el
-- contraste de dos formas que se tocan en el cierre.
insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
select origen.forma_id, destino.forma_id, 'relacionada_con',
	'La serie encadenada cierra con una estrofa cruzada de cuatro versos: un serventesio en la endecasilábica, una cuarteta en la octosilábica.',
	'revisada'
from public.formas_metricas origen, public.formas_metricas destino
where origen.slug = 'terceto_encadenado'
	and destino.slug = 'cuarteto'
	and not exists (
		select 1 from public.forma_relaciones existente
		where existente.forma_origen_id = origen.forma_id
			and existente.forma_destino_id = destino.forma_id
			and existente.tipo_relacion = 'relacionada_con'
	);

do $$
declare
	v_secciones integer;
	v_regla record;
	v_arq uuid;
begin
	select count(*) into v_secciones
	from public.estructuras_secciones seccion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = seccion.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado'
		and seccion.slug = 'serventesio'
		and seccion.versos_min = 4
		and seccion.arquitectura_referenciada_id is not null;
	if v_secciones <> 2 then
		raise exception 'Se esperaban dos cierres en estrofa cruzada y hay %', v_secciones;
	end if;

	-- La regla de longitud debe seguir dando «múltiplos de tres más uno».
	select arquitectura.arquitectura_id into v_arq
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado' and arquitectura.slug = 'endecasilabico_consonante';

	select * into v_regla from public.regla_longitud_arquitectura_metrica(v_arq) limit 1;

	if v_regla.modulo_versos <> 3 or v_regla.residuo_versos <> 1 then
		raise exception 'La regla del encadenado debe ser 3n+1 y es %n+%',
			v_regla.modulo_versos, v_regla.residuo_versos;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 55,
	revision = revision + 1,
	actualizado_en = now();

commit;
