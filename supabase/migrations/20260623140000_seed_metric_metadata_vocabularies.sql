insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	etiqueta,
	definicion,
	nivel,
	orden,
	activo,
	created_at,
	updated_at
)
values
	('c5b9a139-a184-471a-b7a7-aa65ed377e85', 'tipo_rima', 'asonante', 'Asonante', null, 1, 10, true, now(), now()),
	('e0eec235-4a89-4a3c-9cb7-350ac883f7e1', 'tipo_rima', 'consonante', 'Consonante', null, 1, 20, true, now(), now()),
	('cec40a07-9f34-46db-aefd-66a2f3a71601', 'tipo_rima', 'sin_rima', 'Sin rima', null, 1, 30, true, now(), now()),
	('9f4e4f21-e575-4af9-b759-2f41b5584a6c', 'tipo_rima', 'mixta', 'Mixta', null, 1, 40, true, now(), now()),
	('2afc20fe-4441-465b-a228-c7d7c93caa9d', 'naturaleza_estrofica', 'tirada_continua', 'Tirada continua', null, 1, 10, true, now(), now()),
	('c0d172a1-29c3-4a0e-a732-b5dad49d850d', 'naturaleza_estrofica', 'estrofa_cerrada', 'Estrofa cerrada', null, 1, 20, true, now(), now()),
	('c1bb401e-3b55-4338-a5ef-d724c05cd375', 'naturaleza_estrofica', 'forma_fija', 'Forma fija', null, 1, 30, true, now(), now()),
	('b2bd0958-c494-4178-84de-6127b0ade0a9', 'naturaleza_estrofica', 'forma_compuesta', 'Forma compuesta', null, 1, 40, true, now(), now()),
	('e29bc913-74e0-4cd9-bdeb-be6328e4b4ec', 'naturaleza_estrofica', 'forma_irregular', 'Forma irregular', null, 1, 50, true, now(), now())
on conflict (categoria, termino)
do update set
	etiqueta = excluded.etiqueta,
	definicion = excluded.definicion,
	nivel = excluded.nivel,
	orden = excluded.orden,
	activo = excluded.activo,
	updated_at = now();
