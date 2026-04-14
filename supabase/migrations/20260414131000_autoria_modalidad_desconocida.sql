begin;

insert into public.vocabularios (
	categoria,
	termino,
	termino_padre_id,
	nivel,
	orden,
	activo,
	created_at,
	updated_at
)
values
	('modalidad_atribucion', 'desconocida', null, 1, 40, true, now(), now())
on conflict (categoria, termino)
do update set
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = true,
	updated_at = now();

commit;
