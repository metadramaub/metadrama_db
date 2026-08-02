begin;

-- La arquitectura octosilábica del terceto encadenado nació como una
-- configuración provisional y por eso quedó fuera del demarcador. Después se
-- formalizaron su esquema métrico, sus posiciones y enlaces de rima y sus
-- secciones, pero aquel indicador provisional no se actualizó.
update public.arquitecturas_forma arquitectura
set demarcable = true,
	updated_at = now()
from public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = 'terceto_encadenado'
	and arquitectura.slug = 'octosilabico'
	and arquitectura.activo
	and not arquitectura.demarcable;

do $$
declare
	v_arquitecturas integer;
begin
	select count(*) into v_arquitecturas
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'terceto_encadenado'
		and arquitectura.slug = 'octosilabico'
		and arquitectura.activo
		and arquitectura.demarcable;

	if v_arquitecturas <> 1 then
		raise exception
			'Se esperaba una única arquitectura octosilábica demarcable del terceto encadenado y hay %',
			v_arquitecturas;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 58,
	revision = revision + 1,
	actualizado_en = now();

commit;
