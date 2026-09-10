begin;

-- La ficha pública es una instantánea precomputada. Si se asigna otro editor,
-- el nombre y el ORCID que contiene dejan de ser actuales hasta republicarla.
create or replace function public.mark_obra_resumen_dirty_by_editor_asignado()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.editor_asignado is distinct from old.editor_asignado then
		update public.obras_resumen
		set metrica_sucia = true
		where obra_id = new.obra_id;
	end if;

	return new;
end;
$$;

drop trigger if exists trg_mark_resumen_dirty_editor_asignado on public.obras;
create trigger trg_mark_resumen_dirty_editor_asignado
	after update of editor_asignado on public.obras
	for each row execute function public.mark_obra_resumen_dirty_by_editor_asignado();

-- El nombre se conserva también en obras.autor_ficha_publico; el ORCID se
-- incorpora directamente al JSON precomputado. Ambos cambios invalidan las
-- fichas de las obras asignadas a ese editor, sin publicarlas automáticamente.
create or replace function public.sync_editor_identity_in_public_summaries()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.nombre_completo is not distinct from old.nombre_completo
		and new.orcid is not distinct from old.orcid then
		return new;
	end if;

	if new.nombre_completo is distinct from old.nombre_completo then
		update public.obras
		set autor_ficha_publico = new.nombre_completo
		where editor_asignado = new.user_id
			and autor_ficha_publico is distinct from new.nombre_completo;
	end if;

	update public.obras_resumen resumen
	set metrica_sucia = true
	from public.obras obra
	where resumen.obra_id = obra.obra_id
		and obra.editor_asignado = new.user_id;

	return new;
end;
$$;

drop trigger if exists trg_sync_editor_identity_in_public_summaries on public.editores;
create trigger trg_sync_editor_identity_in_public_summaries
	after update of nombre_completo, orcid on public.editores
	for each row execute function public.sync_editor_identity_in_public_summaries();

commit;
