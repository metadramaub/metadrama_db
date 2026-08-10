-- Toda arquitectura dice su densidad de rima, o deja calcularla.
--
-- Al separar los dos ejes quedaron declaradas las cuatro arquitecturas donde vivía el problema
-- —tres silvas y el endecasílabo suelto—, y la regla era: se declara donde la norma deja el
-- reparto abierto, y se calcula donde el esquema dice qué posiciones quedan sueltas.
--
-- Al comprobar quién quedaba fuera aparecieron trece arquitecturas sin densidad, y **la regla
-- estaba incompleta**. Son dos grupos:
--
--   **Seis no tienen ningún esquema de rima** —la copla real, las dos novenas y las tres
--   sextinas— porque su rima viene de sus **secciones**, que reutilizan otras formas: la copla
--   real son dos quintillas y la novena una quintilla y una redondilla. Ahí la densidad también
--   se calcula, solo que siguiendo la reutilización en vez del esquema propio.
--
--   **Siete tienen esquema abierto y ninguno concreto**, y esas sí eran huecos: la estancia de
--   rima variable de la canción, la copla de pie quebrado, el sexteto alejandrino y el
--   dodecasílabo, y la sextilla heptasílaba, hexasílaba y de pie quebrado.
--
-- LAS SIETE RIMAN TODOS SUS VERSOS. Son estrofas cerradas de rima consonante en las que lo
-- abierto es **el orden**, no si riman: la sextilla «admite distintas distribuciones» y la copla
-- de pie quebrado declara «rima consonante, sin una disposición fija», pero en ninguna queda un
-- verso suelto. Se declara `total` como definitoria, que es lo que las separa de la familia de la
-- silva sin necesidad de mirar sus pareados.
--
-- Con eso el eje queda completo: **cualquier pasaje del catálogo se puede situar en él**, que era
-- el objetivo. Una guarda lo sostiene desde ahora.

begin;

insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
select a.arquitectura_id, r.rasgo_id, rv.valor_id, 'definitoria',
	'Estrofa cerrada de rima consonante: lo que la norma deja abierto es el orden de las rimas, no si los versos riman.'
from public.arquitecturas_forma a
join public.rasgos_metricos r on r.slug = 'densidad_de_rima'
join public.rasgo_valores rv on rv.rasgo_id = r.rasgo_id and rv.slug = 'total'
where a.activo
	-- Ningún esquema concreto…
	and not exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = a.arquitectura_id and er.tipo_secuencia <> 'abierta'
	)
	-- …pero sí alguno abierto: si no tuviera ninguno, su rima vendría de sus secciones.
	and exists (
		select 1 from public.esquemas_rima er
		where er.arquitectura_id = a.arquitectura_id and er.tipo_secuencia = 'abierta'
	)
	and not exists (
		select 1 from public.arquitectura_rasgos ar
		where ar.arquitectura_id = a.arquitectura_id and ar.rasgo_id = r.rasgo_id
	);

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- El invariante: toda arquitectura activa dice su densidad o deja calcularla, sea por su
	-- propio esquema o por las secciones que reutilizan otra forma.
	select count(*), string_agg(f.slug || '·' || a.slug, ', ') into v_n, v_mal
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where a.activo
		and not exists (
			select 1 from public.arquitectura_rasgos ar
			join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
			where ar.arquitectura_id = a.arquitectura_id and r.slug = 'densidad_de_rima'
		)
		and not exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = a.arquitectura_id and er.tipo_secuencia <> 'abierta'
		)
		and not exists (
			select 1 from public.estructuras_secciones s
			where s.arquitectura_id = a.arquitectura_id
		);
	if v_n <> 0 then
		raise exception '% arquitecturas no dicen su densidad ni dejan calcularla: %', v_n, v_mal;
	end if;

	-- Y las siete nuevas no pueden haber tocado a las de la silva, que son las que sostienen la
	-- frontera: siguen siendo cuatro las que declaran algo distinto de `total`.
	select count(distinct ar.arquitectura_id) into v_n
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	where r.slug = 'densidad_de_rima' and rv.slug <> 'total';
	if v_n <> 4 then
		raise exception '% arquitecturas declaran densidad parcial en vez de 4', v_n;
	end if;

	-- Ninguna pregunta nueva: las siete tienen un solo valor y por tanto se derivan.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	where r.slug = 'densidad_de_rima';
	if v_n <> 3 then
		raise exception 'Hay % preguntas de densidad en vez de 3', v_n;
	end if;

	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 411 then
		raise exception 'Las opciones son % en vez de 411', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
