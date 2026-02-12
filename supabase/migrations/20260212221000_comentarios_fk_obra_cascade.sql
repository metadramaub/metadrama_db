-- Garantiza borrado en cascada de comentarios internos al eliminar obras.
-- Evita bloqueos por constraints legacy sin ON DELETE CASCADE.

alter table public.comentarios_internos
	drop constraint if exists fk_obra;

alter table public.comentarios_internos
	drop constraint if exists comentarios_internos_obra_id_fkey;

alter table public.comentarios_internos
	add constraint comentarios_internos_obra_id_fkey
	foreign key (obra_id)
	references public.obras (obra_id)
	on delete cascade;
