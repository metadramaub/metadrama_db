begin;

-- El zéjel se formaliza mediante posiciones y un enlace entre la vuelta y el
-- estribillo. La restricción textual redundante se retiró correctamente, pero
-- su esquema conservó por error el tipo «restricciones».
update public.esquemas_rima esquema
set tipo_secuencia = 'secuencia',
	updated_at = now()
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where esquema.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'zejel'
	and arquitectura.slug = 'estribillo_y_coplas_monorrimas'
	and esquema.tipo_secuencia = 'restricciones';

-- Aprobación provisional solicitada para probar el demarcador con el catálogo
-- completo. Los tramos «sin forma» conservan su estado editorial propio.
update public.formas_metricas
set estado_revision = 'aprobada',
	updated_at = now()
where tipo_registro = 'forma'
	and estado_revision <> 'retirada';

do $$
declare
	v_zejel_secuencia integer;
	v_formas_pendientes integer;
begin
	select count(*) into v_zejel_secuencia
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'zejel'
		and arquitectura.slug = 'estribillo_y_coplas_monorrimas'
		and esquema.tipo_secuencia = 'secuencia';

	if v_zejel_secuencia <> 1 then
		raise exception 'Se esperaba un único esquema secuencial para el zéjel y hay %',
			v_zejel_secuencia;
	end if;

	select count(*) into v_formas_pendientes
	from public.formas_metricas
	where tipo_registro = 'forma'
		and estado_revision not in ('aprobada', 'retirada');

	if v_formas_pendientes <> 0 then
		raise exception 'Quedan % formas activas sin aprobar', v_formas_pendientes;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 57,
	revision = revision + 1,
	actualizado_en = now();

commit;
