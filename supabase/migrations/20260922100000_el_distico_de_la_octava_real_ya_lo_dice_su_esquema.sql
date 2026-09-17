-- El dístico final de la octava real ya lo dice su esquema
--
-- La octava real declaraba el rasgo «Dístico final» con modalidad habitual, y es la **única forma
-- del catálogo que lo hace teniendo esquema escrito**. Acaban en pareado y no lo declaran el
-- sexteto (ABABCC), el sexteto-lira (aabbcc, ababcc, abbacc), la octava-lira (abcabcdd, ababccdd),
-- la décima-lira (ababcdcdee), el septeto-lira (ababbcc), el terceto y la quintilla. Era una
-- excepción sin criterio detrás.
--
-- **No añade nada**: su único esquema con notación es `ABABABCC`, que ya lleva el pareado escrito.
-- Y las variantes que motivaron la declaración ya están modeladas donde corresponde: la misma
-- arquitectura tiene un segundo esquema, `distribucion-variable`, abierto y de modalidad
-- `excepcional`. Eso es exactamente lo que dice Jauralde —«recibió variaciones de todo tipo…
-- conservando casi siempre de manera fija el pareado final»— dicho en el eje de la rima, que es su
-- sitio. *Por ese «casi siempre» no se convierte en restricción del esquema: una restricción
-- afirmaría más de lo que la fuente sostiene.*
--
-- Y era además una promesa que podía quedarse falsa: bajo el esquema abierto un editor puede
-- escribir una disposición sin pareado final, y el rasgo seguiría prometiéndolo.
--
-- **El rasgo no se retira del catálogo.** Sigue donde sí es una observación: en el endecasílabo
-- suelto, cuyo único esquema no tiene notación —la rima está abierta— y donde que un pasaje termine
-- en dos versos rimados es un hallazgo, no algo deducible. Sus cinco anotaciones no se tocan.
--
-- El criterio que queda vigilado: **el dístico final solo se declara donde ningún esquema lo
-- muestre**. Lo comprueba la guarda, para todo el catálogo y no solo para esta forma.

begin;

delete from public.arquitectura_rasgos ar
using public.rasgos_metricos rm, public.arquitecturas_forma a, public.formas_metricas f
where ar.rasgo_id = rm.rasgo_id
	and a.arquitectura_id = ar.arquitectura_id
	and f.forma_id = a.forma_id
	and rm.slug = 'distico_final'
	and f.slug = 'octava_real';

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

do $guarda$
declare
	v_sobran text;
	v_endecasilabo int;
begin
	-- 1. Nadie declara el dístico teniendo un esquema que lo muestre.
	select string_agg(format('%s/%s', f.slug, a.slug), ', ')
	into v_sobran
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final'
		and exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = ar.arquitectura_id and er.notacion is not null
		);

	if v_sobran is not null then
		raise exception 'Estas arquitecturas declaran el dístico final y su esquema ya lo muestra: %', v_sobran;
	end if;

	-- 2. Donde sí es observación, sigue estando: el endecasílabo suelto no tiene esquema con
	--    notación, así que el dístico no se deduce de ninguna parte y hay que preguntarlo.
	select count(*) into v_endecasilabo
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where rm.slug = 'distico_final' and f.slug = 'endecasilabo_suelto';

	if v_endecasilabo <> 1 then
		raise exception 'El endecasílabo suelto debería seguir declarando el dístico final, y declara %.', v_endecasilabo;
	end if;

	-- 3. Las anotaciones que ya existen siguen ahí: el valor del catálogo no se ha tocado.
	if (
		select count(*) from public.anotacion_elecciones e
		join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
		join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
		where rm.slug = 'distico_final'
	) <> 5 then
		raise exception 'Han cambiado las anotaciones del dístico final, y esta migración no debía tocarlas.';
	end if;
end
$guarda$;

commit;
