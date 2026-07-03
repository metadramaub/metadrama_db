-- Seed idempotente de vocabularios base para METADRAMA.
-- Requiere unique(categoria, termino) en public.vocabularios.

insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	termino_padre_id,
	nivel,
	patron_especifico,
	tipo_forma,
	orden,
	activo,
	created_at,
	updated_at
)
values
	-- role_editor
	('df0b4c28-7c01-4229-95f6-3f592335d7fa', 'role_editor', 'editor', null, 1, null, null, 10, true, now(), now()),
	('a1d0369c-1dd0-48d9-aec2-8a4a6f4bf37d', 'role_editor', 'admin', null, 1, null, null, 30, true, now(), now()),
	('74574b9e-6a26-46e3-8eb7-938dd6f083f6', 'role_editor', 'IP', null, 1, null, null, 40, true, now(), now()),

	-- estado
	('7ff66f88-4b89-4fdf-9f8b-1698c58f67dc', 'estado', 'borrador', null, 1, null, null, 10, true, now(), now()),
	('2d6136ac-1458-4b27-bc77-3b3c77a7e04a', 'estado', 'vista_previa', null, 1, null, null, 20, true, now(), now()),
	('0df1a8c1-6c9c-4345-b267-32cd51f1e4f9', 'estado', 'listo_para_publicar', null, 1, null, null, 30, true, now(), now()),
	('2bd57d38-6f8d-4fb2-af39-214dd6b50f29', 'estado', 'publicado', null, 1, null, null, 40, true, now(), now()),

	-- genero
	('e7212f8c-8d4d-4a9f-9e5d-d22959e761f4', 'genero', 'comedia', null, 1, null, null, 10, true, now(), now()),
	('8540f042-cabc-49cf-8f07-af0aa5d0568a', 'genero', 'tragedia', null, 1, null, null, 20, true, now(), now()),
	('d0908775-bbe6-4e8d-996d-c1bc3b0c6455', 'genero', 'auto_sacramental', null, 1, null, null, 30, true, now(), now()),
	('37f97ed5-b47f-499d-bee9-3f66ac7e8d5a', 'genero', 'entremes', null, 1, null, null, 40, true, now(), now()),
	('4b0196fd-a4ad-4c57-8bc2-1190c2b37723', 'genero', 'loa', null, 1, null, null, 50, true, now(), now()),

	-- estrofa_tipo (jerarquia)
	('b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 'estrofa_tipo', 'romance', null, 1, null, 'forma_espanola', 10, true, now(), now()),
	('e4f15fc1-87a1-4d5e-bf55-2aa9536f4f6e', 'estrofa_tipo', 'romance_e-a', 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 2, 'e-a', 'forma_espanola', 11, true, now(), now()),
	('7f96e16d-a005-4d6f-bfd5-c8083fa94ef3', 'estrofa_tipo', 'romance_i-o', 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 2, 'i-o', 'forma_espanola', 12, true, now(), now()),
	('574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad', 'estrofa_tipo', 'redondilla', null, 1, null, 'forma_espanola', 20, true, now(), now()),
	('8f8b9491-d40d-40eb-a2af-a25bc19fb3da', 'estrofa_tipo', 'quintilla', null, 1, null, 'forma_espanola', 30, true, now(), now()),
	('d8382ff9-249f-4d47-a69e-4c3f7410cb39', 'estrofa_tipo', 'decima', null, 1, null, 'forma_espanola', 40, true, now(), now()),
	('769f4a14-4592-4dc7-9b3e-79d568ca4209', 'estrofa_tipo', 'silva', null, 1, null, 'forma_italiana', 50, true, now(), now()),

	-- metro
	('81567f6d-5e8b-419f-b2c0-f9e9ed7f1017', 'metro', 'octosilabo', null, 1, null, null, 10, true, now(), now()),
	('72fbe06d-9f46-4690-9df8-a4d9f0611d0d', 'metro', 'endecasilabo', null, 1, null, null, 20, true, now(), now()),
	('4f2d2610-1e55-40a2-8ad4-e57708d80489', 'metro', 'heptasilabo', null, 1, null, null, 30, true, now(), now()),

	-- personajes
	('07f54dfa-fc74-43e2-84fe-9f71b4e3f603', 'personajes_genero', 'mixto', null, 1, null, null, 10, true, now(), now()),
	('493fd3e5-0ef0-4d17-a2ed-e67c4ef7a710', 'personajes_genero', 'solo_masculino', null, 1, null, null, 20, true, now(), now()),
	('89d0f013-904c-4ab0-b5bd-1d796f89f52f', 'personajes_genero', 'solo_femenino', null, 1, null, null, 30, true, now(), now()),
	('7f34a8b6-c2a8-44a7-bd57-42574b4b63f4', 'personajes_donaire', 'ausente', null, 1, null, null, 10, true, now(), now()),
	('15225823-ad28-4f8a-beec-626f865ca279', 'personajes_donaire', 'solo', null, 1, null, null, 20, true, now(), now()),
	('f3277981-dd41-4e66-a577-c2f7a0d0a249', 'personajes_donaire', 'con_otros', null, 1, null, null, 30, true, now(), now()),
	('ccf63b66-30b3-4e15-8f2c-38a2810d9527', 'personajes_sobrenatural', 'ausente', null, 1, null, null, 10, true, now(), now()),
	('bd6a7f91-c2ff-4738-be94-b0fe6356d565', 'personajes_sobrenatural', 'solo', null, 1, null, null, 20, true, now(), now()),
	('198d7e42-a087-46db-93f9-36a2f74f0f2c', 'personajes_sobrenatural', 'con_otros', null, 1, null, null, 30, true, now(), now()),

	-- caracterizacion_rango
	('6eb2af74-f69e-4d69-8f67-2e8d7b1d8db1', 'caracterizacion_rango', 'fenomenos_enunciativos', null, 1, null, null, 10, true, now(), now()),
	('4d1f1e52-5af3-4d53-bf64-f739d29ca123', 'caracterizacion_rango', 'cantado', '6eb2af74-f69e-4d69-8f67-2e8d7b1d8db1', 2, null, null, 11, true, now(), now()),
	('7ea9f03f-0ea1-4f8a-86f3-3028d862b35f', 'caracterizacion_rango', 'prosa', '6eb2af74-f69e-4d69-8f67-2e8d7b1d8db1', 2, null, null, 12, true, now(), now()),
	('c6e3c80d-f0be-4e42-96bb-c8b0ce4c9910', 'caracterizacion_rango', 'irregularidades_metricas', null, 1, null, null, 20, true, now(), now()),
	('4a2cf6a9-5879-4ef1-b5a7-93c5e2fb5c6a', 'caracterizacion_rango', 'hipometrico', 'c6e3c80d-f0be-4e42-96bb-c8b0ce4c9910', 2, null, null, 21, true, now(), now()),
	('aa4e8a79-0d5f-483b-8e90-83d5f458f65b', 'caracterizacion_rango', 'hipermetrico', 'c6e3c80d-f0be-4e42-96bb-c8b0ce4c9910', 2, null, null, 22, true, now(), now()),
	('271cadcb-79ca-47e6-b815-21b25e8f57ff', 'caracterizacion_rango', 'rima_defectuosa', 'c6e3c80d-f0be-4e42-96bb-c8b0ce4c9910', 2, null, null, 23, true, now(), now()),
	('02bd9e66-6248-4336-bf84-3b03eb0c28d4', 'caracterizacion_rango', 'laguna', 'c6e3c80d-f0be-4e42-96bb-c8b0ce4c9910', 2, null, null, 24, true, now(), now()),
	('5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9', 'caracterizacion_rango', 'final_acentual', null, 1, null, null, 30, true, now(), now()),
	('04649d89-bc9b-46c1-82cf-6c4606e9d901', 'caracterizacion_rango', 'mayoria_agudas', '5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9', 2, null, null, 31, true, now(), now()),
	('74fa5872-c359-4242-ab0b-cffc85c0d557', 'caracterizacion_rango', 'mayoria_esdrujulas', '5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9', 2, null, null, 32, true, now(), now())
on conflict (categoria, termino)
do update set
	nivel = excluded.nivel,
	patron_especifico = excluded.patron_especifico,
	tipo_forma = excluded.tipo_forma,
	orden = excluded.orden,
	activo = excluded.activo,
	updated_at = now();

update public.vocabularios
set
	numero_silabas = case termino
		when 'octosilabo' then 8
		when 'heptasilabo' then 7
		when 'endecasilabo' then 11
		else numero_silabas
	end,
	updated_at = now()
where categoria = 'metro'
	and termino in ('octosilabo', 'heptasilabo', 'endecasilabo');

update public.vocabularios
set
	etiqueta = case termino
		when 'vista_previa' then 'Vista previa'
		when 'listo_para_publicar' then 'Listo para publicar'
		else etiqueta
	end,
	updated_at = now()
where categoria = 'estado'
	and termino in ('vista_previa', 'listo_para_publicar');

-- Resolver jerarquia por termino para evitar dependencia de UUIDs historicos.
update public.vocabularios as child
set
	termino_padre_id = parent.termino_id,
	nivel = 2,
	updated_at = now()
from public.vocabularios as parent
where child.categoria = 'estrofa_tipo'
	and parent.categoria = 'estrofa_tipo'
	and parent.termino = 'romance'
	and child.termino in ('romance_e-a', 'romance_i-o');

update public.vocabularios
set
	termino_padre_id = null,
	nivel = 1,
	updated_at = now()
where categoria = 'estrofa_tipo'
	and termino in ('romance', 'redondilla', 'quintilla', 'decima', 'silva');

insert into public.estrofa_tipo_metros (estrofa_tipo_id, metro_id)
select estrofa.termino_id, metro.termino_id
from (
	values
		('romance', 'octosilabo'),
		('silva', 'heptasilabo'),
		('silva', 'endecasilabo')
) as pairs(estrofa_termino, metro_termino)
join public.vocabularios as estrofa
	on estrofa.categoria = 'estrofa_tipo'
	and estrofa.termino = pairs.estrofa_termino
join public.vocabularios as metro
	on metro.categoria = 'metro'
	and metro.termino = pairs.metro_termino
on conflict (estrofa_tipo_id, metro_id) do nothing;

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
	('9f4e4f21-e575-4af9-b759-2f41b5584a6c', 'tipo_rima', 'otras', 'Otras', null, 1, 30, true, now(), now()),
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
