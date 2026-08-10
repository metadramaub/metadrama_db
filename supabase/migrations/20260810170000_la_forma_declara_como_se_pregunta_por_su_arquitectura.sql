-- La forma declara cómo se pregunta por su arquitectura.
--
-- Era el último dato del formulario que seguía escrito en el código. `MetricSequenceEditor`
-- rotulaba esa pregunta con un `case` por slug: «¿Dónde aparece por primera vez el estribillo?»
-- si la forma era el villancico, «¿Cómo se organizan las redondillas?» si era la redondilla,
-- «¿Aparecen versos de pie quebrado?» si era la copla real, y «Arquitectura» en las otras 24.
--
-- Es el mismo hueco que el de los rasgos y por la misma razón: la pregunta existía, no tenía
-- dónde vivir, y acabó en un componente. Tres formas con nombre propio dentro de un `if` es la
-- señal de que falta una columna.
--
-- *El caso de la copla real ni siquiera llegaba a verse: tiene una sola arquitectura, así que el
-- editor nunca plantea esa pregunta. Era código muerto que aparentaba ser una excepción.*
--
-- Las formas que no la declaran se preguntan «Arquitectura», que no es una excepción sino la
-- ausencia de una: cuando la elección no tiene una manera mejor de decirse, se dice así.

begin;

alter table public.formas_metricas add column if not exists pregunta_arquitectura text;

comment on column public.formas_metricas.pregunta_arquitectura is
	'Cómo se le pregunta al editor cuál de las arquitecturas de esta forma tiene el pasaje. Solo hace falta cuando la forma tiene más de una y la elección se explica mejor con sus propias palabras que con «Arquitectura».';

update public.formas_metricas
set pregunta_arquitectura = '¿Dónde aparece por primera vez el estribillo?', updated_at = now()
where slug = 'villancico';

update public.formas_metricas
set pregunta_arquitectura = '¿Cómo se organizan las redondillas?', updated_at = now()
where slug = 'redondilla';

do $$
declare
	v_n integer;
begin
	-- Declararla en una forma de una sola arquitectura no rompe nada, pero no se pregunta nunca:
	-- sería prosa que no llega a leerse.
	select count(*) into v_n
	from public.formas_metricas f
	where f.pregunta_arquitectura is not null
		and (
			select count(*) from public.arquitecturas_forma a
			where a.forma_id = f.forma_id and a.activo
		) < 2;
	if v_n <> 0 then
		raise exception '% formas declaran una pregunta de arquitectura que no se plantea', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
