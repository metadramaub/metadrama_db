insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	termino_padre_id,
	nivel,
	orden,
	activo,
	created_at,
	updated_at
)
values (
	'9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f103',
	'composicion_autoria',
	'desconocida',
	null,
	1,
	30,
	true,
	now(),
	now()
)
on conflict (termino_id) do update
set categoria = excluded.categoria,
	termino = excluded.termino,
	termino_padre_id = excluded.termino_padre_id,
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = true,
	updated_at = now();
