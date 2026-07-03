begin;

alter table public.vocabularios
	drop constraint if exists vocabularios_tipo_rima_check;

update public.vocabularios as antigua
set
	termino = 'otras',
	etiqueta = 'Otras',
	orden = coalesce(antigua.orden, 30),
	updated_at = now()
where antigua.categoria = 'tipo_rima'
	and antigua.termino = 'mixta'
	and not exists (
		select 1
		from public.vocabularios as existente
		where existente.categoria = 'tipo_rima'
			and existente.termino = 'otras'
	);

insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	etiqueta,
	nivel,
	orden,
	activo
)
values
	('c5b9a139-a184-471a-b7a7-aa65ed377e85', 'tipo_rima', 'asonante', 'Asonante', 1, 10, true),
	('e0eec235-4a89-4a3c-9cb7-350ac883f7e1', 'tipo_rima', 'consonante', 'Consonante', 1, 20, true),
	('9f4e4f21-e575-4af9-b759-2f41b5584a6c', 'tipo_rima', 'otras', 'Otras', 1, 30, true)
on conflict (categoria, termino) do update
set
	etiqueta = excluded.etiqueta,
	nivel = coalesce(public.vocabularios.nivel, excluded.nivel),
	orden = coalesce(public.vocabularios.orden, excluded.orden),
	activo = true,
	updated_at = now();

alter table public.vocabularios
	add column if not exists tipo_rima_id uuid;

update public.vocabularios as estrofa
set
	tipo_rima_id = rima.termino_id,
	updated_at = now()
from public.vocabularios as rima
where estrofa.categoria = 'estrofa_tipo'
	and rima.categoria = 'tipo_rima'
	and rima.termino = case estrofa.tipo_rima
		when 'mixta' then 'otras'
		else estrofa.tipo_rima
	end
	and estrofa.tipo_rima in ('asonante', 'consonante', 'mixta', 'otras')
	and estrofa.tipo_rima_id is distinct from rima.termino_id;

update public.vocabularios as estrofa
set
	tipo_rima_id = null,
	updated_at = now()
where estrofa.categoria = 'estrofa_tipo'
	and estrofa.tipo_rima = 'sin_rima'
	and estrofa.tipo_rima_id is not null;

alter table public.vocabularios
	drop constraint if exists vocabularios_tipo_rima_id_fkey;

alter table public.vocabularios
	add constraint vocabularios_tipo_rima_id_fkey
		foreign key (tipo_rima_id)
		references public.vocabularios (termino_id)
		on update cascade
		on delete restrict;

create or replace function public.ensure_vocabulario_tipo_rima_id_category()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.tipo_rima_id is null then
		return new;
	end if;

	if new.categoria <> 'estrofa_tipo' then
		raise exception 'tipo_rima_id solo se puede usar en vocabularios.categoria=estrofa_tipo';
	end if;

	if not exists (
		select 1
		from public.vocabularios v
		where v.termino_id = new.tipo_rima_id
			and v.categoria = 'tipo_rima'
	) then
		raise exception 'tipo_rima_id debe apuntar a vocabularios.categoria=tipo_rima';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_ensure_vocabulario_tipo_rima_id_category
	on public.vocabularios;

create trigger trigger_ensure_vocabulario_tipo_rima_id_category
before insert or update of tipo_rima_id on public.vocabularios
for each row
execute function public.ensure_vocabulario_tipo_rima_id_category();

delete from public.vocabularios as antigua
where antigua.categoria = 'tipo_rima'
	and antigua.termino in ('sin_rima', 'mixta')
	and not exists (
		select 1
		from public.vocabularios as estrofa
		where estrofa.tipo_rima_id = antigua.termino_id
	);

alter table public.vocabularios
	drop column if exists tipo_rima;

commit;
