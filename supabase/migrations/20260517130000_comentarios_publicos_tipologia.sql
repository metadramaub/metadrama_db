-- Nuevas tipologias de comentarios internos y publicacion controlada en ficha publica.

insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	orden,
	activo,
	definicion
)
values
	(
		'9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f005',
		'tipo_comentario',
		'nota_propia',
		50,
		true,
		'Nota interna del editor para revisar mas adelante'
	),
	(
		'9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f006',
		'tipo_comentario',
		'observacion_publica',
		60,
		true,
		'Observacion o aclaracion editorial publicable en la ficha publica'
	)
on conflict (categoria, termino)
do update
set
	activo = true,
	orden = excluded.orden,
	definicion = excluded.definicion,
	updated_at = now();

alter table public.comentarios_internos
	add column if not exists visible_publico boolean not null default false,
	add column if not exists publicado_por uuid,
	add column if not exists publicado_at timestamptz;

do $$
begin
	if not exists (
		select 1
		from pg_constraint
		where conname = 'comentarios_internos_publicado_por_fkey'
	) then
		alter table public.comentarios_internos
			add constraint comentarios_internos_publicado_por_fkey
			foreign key (publicado_por)
			references public.editores (user_id);
	end if;
end $$;

create index if not exists idx_comentarios_obra_visible_publico
	on public.comentarios_internos (obra_id, visible_publico);

create index if not exists idx_comentarios_tipo_visible_publico
	on public.comentarios_internos (tipo_comentario_id, visible_publico);

create or replace function public.get_obra_comentarios_publicos(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language sql
security definer
set search_path = public
as $$
	select coalesce(
		jsonb_agg(
			jsonb_build_object(
				'comentario_id', ci.comentario_id,
				'comentario', ci.comentario,
				'created_at', ci.created_at,
				'seccion', ci.seccion,
				'secuencia_id', ci.secuencia_id,
				'jornada_id', ci.jornada_id,
				'cuadro_id', ci.cuadro_id,
				'nombre_editor', e.nombre_completo
			)
			order by ci.created_at, ci.comentario_id
		),
		'[]'::jsonb
	)
	from public.obras o
	join public.vocabularios estado
		on estado.termino_id = o.estado
		and estado.categoria = 'estado'
		and lower(estado.termino) = 'publicado'
	join public.comentarios_internos ci
		on ci.obra_id = o.obra_id
	join public.vocabularios tipo
		on tipo.termino_id = ci.tipo_comentario_id
		and tipo.categoria = 'tipo_comentario'
		and tipo.termino = 'observacion_publica'
	left join public.editores e
		on e.user_id = ci.user_id
	where o.obra_id = p_obra_id
		and (p_include_hidden or coalesce(o.visible_publico, false))
		and ci.visible_publico = true;
$$;

grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to anon;
grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to authenticated;
grant execute on function public.get_obra_comentarios_publicos(uuid, boolean) to service_role;
