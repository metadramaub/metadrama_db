begin;

alter table public.vocabularios
	drop constraint if exists vocabularios_naturaleza_estrofica_check;

update public.vocabularios as antigua
set
	termino = 'tirada_abierta',
	etiqueta = coalesce(nullif(antigua.etiqueta, ''), 'Tirada abierta'),
	updated_at = now()
where antigua.categoria = 'naturaleza_estrofica'
	and antigua.termino = 'tirada_continua'
	and not exists (
		select 1
		from public.vocabularios as existente
		where existente.categoria = 'naturaleza_estrofica'
			and existente.termino = 'tirada_abierta'
	);

insert into public.vocabularios (
	categoria,
	termino,
	etiqueta,
	nivel,
	orden,
	activo
)
values
	('naturaleza_estrofica', 'tirada_abierta', 'Tirada abierta', 1, 10, true),
	('naturaleza_estrofica', 'estrofa_cerrada', 'Estrofa cerrada', 1, 20, true),
	('naturaleza_estrofica', 'forma_fija', 'Forma fija', 1, 30, true),
	('naturaleza_estrofica', 'forma_compuesta', 'Forma compuesta', 1, 40, true),
	('naturaleza_estrofica', 'forma_irregular', 'Forma irregular', 1, 50, true)
on conflict (categoria, termino) do update
set
	etiqueta = excluded.etiqueta,
	nivel = coalesce(public.vocabularios.nivel, excluded.nivel),
	orden = coalesce(public.vocabularios.orden, excluded.orden),
	activo = true,
	updated_at = now();

alter table public.vocabularios
	add column if not exists naturaleza_estrofica_id uuid;

update public.vocabularios as estrofa
set
	naturaleza_estrofica_id = naturaleza.termino_id,
	updated_at = now()
from public.vocabularios as naturaleza
where estrofa.categoria = 'estrofa_tipo'
	and naturaleza.categoria = 'naturaleza_estrofica'
	and naturaleza.termino = case estrofa.naturaleza_estrofica
		when 'tirada_continua' then 'tirada_abierta'
		else estrofa.naturaleza_estrofica
	end
	and estrofa.naturaleza_estrofica is not null
	and estrofa.naturaleza_estrofica_id is distinct from naturaleza.termino_id;

alter table public.vocabularios
	drop constraint if exists vocabularios_naturaleza_estrofica_id_fkey;

alter table public.vocabularios
	add constraint vocabularios_naturaleza_estrofica_id_fkey
		foreign key (naturaleza_estrofica_id)
		references public.vocabularios (termino_id)
		on update cascade
		on delete restrict;

update public.vocabularios as estrofa
set
	naturaleza_estrofica_id = nueva.termino_id,
	updated_at = now()
from public.vocabularios as antigua
join public.vocabularios as nueva
	on nueva.categoria = 'naturaleza_estrofica'
	and nueva.termino = 'tirada_abierta'
where estrofa.naturaleza_estrofica_id = antigua.termino_id
	and antigua.categoria = 'naturaleza_estrofica'
	and antigua.termino = 'tirada_continua';

create or replace function public.ensure_vocabulario_naturaleza_estrofica_id_category()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	if new.naturaleza_estrofica_id is null then
		return new;
	end if;

	if new.categoria <> 'estrofa_tipo' then
		raise exception 'naturaleza_estrofica_id solo se puede usar en vocabularios.categoria=estrofa_tipo';
	end if;

	if not exists (
		select 1
		from public.vocabularios v
		where v.termino_id = new.naturaleza_estrofica_id
			and v.categoria = 'naturaleza_estrofica'
	) then
		raise exception 'naturaleza_estrofica_id debe apuntar a vocabularios.categoria=naturaleza_estrofica';
	end if;

	return new;
end;
$$;

drop trigger if exists trigger_ensure_vocabulario_naturaleza_estrofica_id_category
	on public.vocabularios;

create trigger trigger_ensure_vocabulario_naturaleza_estrofica_id_category
before insert or update of naturaleza_estrofica_id on public.vocabularios
for each row
execute function public.ensure_vocabulario_naturaleza_estrofica_id_category();

delete from public.vocabularios as antigua
where antigua.categoria = 'naturaleza_estrofica'
	and antigua.termino = 'tirada_continua'
	and not exists (
		select 1
		from public.vocabularios as estrofa
		where estrofa.naturaleza_estrofica_id = antigua.termino_id
	);

alter table public.vocabularios
	drop column if exists naturaleza_estrofica;

commit;
