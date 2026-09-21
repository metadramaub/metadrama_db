-- Jauralde dice «concisas», y la definición del pareado decía «tajantes»
--
-- La definición enumera desde el 20 de agosto de 2026 para qué sirve el pareado suelto, y cada
-- elemento de esa lista tiene detrás una fuente: los estribillos los dicen Navarro Tomás, el
-- Diccionario y Jauralde; los refranes y las máximas, Quilis; los motes y divisas, Navarro Tomás.
-- El último no: Jauralde escribe que en la comedia «resulta muy funcional para intervenciones breves
-- y **concisas**», y la definición lo convirtió en «breves y tajantes». No es el mismo juicio —lo
-- conciso es economía y lo tajante es contundencia—, y el segundo no está en el libro.
--
-- La auditoría de septiembre comprobó que cada afirmación de «Lo que dicen las fuentes» dijera lo que
-- dice su libro. Las **definiciones** no entraban en aquel barrido, y por ahí llegó esto hasta hoy.

begin;

do $cambio$
declare
	v_forma uuid;
	v_actual text;
	v_nueva text;
begin
	select forma_id, definicion into v_forma, v_actual
	from public.formas_metricas where slug = 'pareado';

	if v_forma is null then
		raise exception 'No existe la forma del pareado.';
	end if;

	v_nueva := replace(v_actual, 'intervenciones breves y tajantes', 'intervenciones breves y concisas');

	if v_nueva = v_actual and v_actual not like '%intervenciones breves y concisas%' then
		raise exception 'La definición del pareado no dice lo que esta migración viene a corregir.';
	end if;

	update public.formas_metricas
	set definicion = v_nueva, updated_at = now()
	where forma_id = v_forma and definicion <> v_nueva;
end
$cambio$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

do $guarda$
declare
	v_n integer;
begin
	-- Ni una sola «tajante» queda en la prosa del catálogo, que era donde estaba la única.
	select count(*) into v_n
	from (
		select definicion as texto from public.formas_metricas
		union all select descripcion from public.arquitecturas_forma
		union all select resumen from public.afirmaciones_fuentes_metricas
	) prosa
	where texto ilike '%tajant%';

	if v_n > 0 then
		raise exception '% textos del catálogo siguen diciendo «tajante».', v_n;
	end if;

	select count(*) into v_n from public.formas_metricas
	where slug = 'pareado' and definicion like '%intervenciones breves y concisas%';

	if v_n <> 1 then
		raise exception 'La definición del pareado no recoge lo que dice Jauralde.';
	end if;
end
$guarda$;

commit;
