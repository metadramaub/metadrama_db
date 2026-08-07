-- La descripción pública de una arquitectura describe la forma métrica.
--
-- La revisión anterior explicó en `arquitecturas_forma.descripcion` la prioridad residual
-- con la que el proyecto clasifica la copla de pie quebrado frente a formas más específicas.
-- Esa decisión pertenece al motor de clasificación y a su documentación, no a la definición
-- métrica que lee el catálogo público. Se conserva el contenido positivo —extensión, metro
-- dominante, medidas de los quebrados y variabilidad posicional— y se retira toda referencia
-- a cómo el sistema registra o demarca la forma.

begin;

do $$
declare
	v_arquitectura uuid;
	v_descripcion text := 'Unidades de cinco a doce versos con predominio del octosílabo y pies quebrados tetrasílabos o pentasílabos en posiciones variables.';
begin
	select arquitectura.arquitectura_id into v_arquitectura
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma using (forma_id)
	where forma.slug = 'copla_de_pie_quebrado'
		and arquitectura.slug = 'octosilabica_con_quebrados';

	if v_arquitectura is null then
		raise exception 'No se encontró la arquitectura de la copla de pie quebrado';
	end if;

	update public.arquitecturas_forma
	set descripcion = v_descripcion,
		estado_revision = 'revisada'
	where arquitectura_id = v_arquitectura;

	if not exists (
		select 1
		from public.arquitecturas_forma
		where arquitectura_id = v_arquitectura
			and descripcion = v_descripcion
			and descripcion !~* '(catálogo|proyecto|editor|demarcador|registra)'
	) then
		raise exception 'La descripción no quedó limitada a la definición métrica';
	end if;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
