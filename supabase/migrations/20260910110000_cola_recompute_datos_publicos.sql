begin;

-- El plan se calcula en la base para que la cola del navegador parta de la
-- misma definición que el mantenimiento SQL: obras publicadas y autores con
-- unidades métricas. No recalcula datos.
create or replace function public.plan_recompute_datos_publicos()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_publicado_id uuid;
	v_obras jsonb;
	v_autores jsonb;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden planificar el recálculo público'
			using errcode = '42501';
	end if;

	select termino_id
	into v_publicado_id
	from public.vocabularios
	where categoria = 'estado'
		and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		raise exception 'No existe estado=publicado en vocabularios';
	end if;

	select coalesce(
		jsonb_agg(
			jsonb_build_object('id', obra.obra_id, 'titulo', obra.titulo)
			order by lower(obra.titulo), obra.obra_id
		),
		'[]'::jsonb
	)
	into v_obras
	from public.obras obra
	where obra.estado = v_publicado_id;

	select coalesce(
		jsonb_agg(
			jsonb_build_object('id', autor.autor_id, 'nombre', autor.nombre_completo)
			order by lower(autor.nombre_completo), autor.autor_id
		),
		'[]'::jsonb
	)
	into v_autores
	from (
		select distinct a.autor_id, a.nombre_completo
		from public.perfil_metrico_unidades() unidad
		join public.autores a on a.autor_id = unidad.autor_id
		where unidad.autor_id is not null
	) autor;

	return jsonb_build_object('obras', v_obras, 'autores', v_autores);
end;
$$;

-- La limpieza se ejecuta como una transacción pequeña al terminar la cola.
create or replace function public.finalizar_recompute_datos_publicos()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
	v_eliminados integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden finalizar el recálculo público'
			using errcode = '42501';
	end if;

	delete from public.autores_resumen resumen
	where not exists (
		select 1
		from public.perfil_metrico_unidades() unidad
		where unidad.autor_id = resumen.autor_id
	);
	get diagnostics v_eliminados = row_count;

	return v_eliminados;
end;
$$;

grant execute on function public.plan_recompute_datos_publicos() to authenticated;
grant execute on function public.finalizar_recompute_datos_publicos() to authenticated;

-- recompute_all sigue disponible para mantenimiento SQL y migraciones, pero
-- no puede ser invocada desde el rol web autenticado.
revoke execute on function public.recompute_all() from public, anon, authenticated;
grant execute on function public.recompute_all() to service_role;

commit;
