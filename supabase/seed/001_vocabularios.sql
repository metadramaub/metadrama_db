-- Seed idempotente de vocabularios base para METADRAMA.
-- Requiere unique(categoria, termino) en public.vocabularios.

insert into public.vocabularios (
	termino_id,
	categoria,
	termino,
	termino_padre_id,
	nivel,
	patron_especifico,
	orden,
	activo,
	created_at,
	updated_at
)
values
	-- role_editor
	('df0b4c28-7c01-4229-95f6-3f592335d7fa', 'role_editor', 'editor', null, 1, null, 10, true, now(), now()),
	('a1d0369c-1dd0-48d9-aec2-8a4a6f4bf37d', 'role_editor', 'admin', null, 1, null, 30, true, now(), now()),
	('74574b9e-6a26-46e3-8eb7-938dd6f083f6', 'role_editor', 'IP', null, 1, null, 40, true, now(), now()),

	-- estado
	('7ff66f88-4b89-4fdf-9f8b-1698c58f67dc', 'estado', 'borrador', null, 1, null, 10, true, now(), now()),
	('2d6136ac-1458-4b27-bc77-3b3c77a7e04a', 'estado', 'pendiente', null, 1, null, 20, true, now(), now()),
	('bfe8c41a-bf1a-4fb3-b3b4-76af88f85483', 'estado', 'en_revision', null, 1, null, 30, true, now(), now()),
	('0df1a8c1-6c9c-4345-b267-32cd51f1e4f9', 'estado', 'validado', null, 1, null, 40, true, now(), now()),
	('2bd57d38-6f8d-4fb2-af39-214dd6b50f29', 'estado', 'publicado', null, 1, null, 50, true, now(), now()),

	-- estado_revision
	('ef18f734-8cf5-4586-b5ca-0df411a8f4d7', 'estado_revision', 'borrador', null, 1, null, 10, true, now(), now()),
	('d8b5d82d-c129-4eba-8841-bd2bef092f15', 'estado_revision', 'pendiente', null, 1, null, 20, true, now(), now()),
	('fd934174-72a2-4fc9-a771-7f9f47671fcf', 'estado_revision', 'en_revision', null, 1, null, 30, true, now(), now()),
	('55b522f9-a2b4-4f89-a8dc-5e97ef9e43f0', 'estado_revision', 'validado', null, 1, null, 40, true, now(), now()),

	-- certeza_editor
	('f9f22b11-15a4-4f90-b3ea-7ce90c31fbd3', 'certeza_editor', 'baja', null, 1, null, 10, true, now(), now()),
	('0d7c6dfb-dcc1-47ad-b607-9b4f2dbedc17', 'certeza_editor', 'media', null, 1, null, 20, true, now(), now()),
	('4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7', 'certeza_editor', 'alta', null, 1, null, 30, true, now(), now()),

	-- genero
	('e7212f8c-8d4d-4a9f-9e5d-d22959e761f4', 'genero', 'comedia', null, 1, null, 10, true, now(), now()),
	('8540f042-cabc-49cf-8f07-af0aa5d0568a', 'genero', 'tragedia', null, 1, null, 20, true, now(), now()),
	('d0908775-bbe6-4e8d-996d-c1bc3b0c6455', 'genero', 'auto_sacramental', null, 1, null, 30, true, now(), now()),
	('37f97ed5-b47f-499d-bee9-3f66ac7e8d5a', 'genero', 'entremes', null, 1, null, 40, true, now(), now()),
	('4b0196fd-a4ad-4c57-8bc2-1190c2b37723', 'genero', 'loa', null, 1, null, 50, true, now(), now()),

	-- estrofa_tipo (jerarquia)
	('b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 'estrofa_tipo', 'romance', null, 1, null, 10, true, now(), now()),
	('e4f15fc1-87a1-4d5e-bf55-2aa9536f4f6e', 'estrofa_tipo', 'romance_e-a', 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 2, 'e-a', 11, true, now(), now()),
	('7f96e16d-a005-4d6f-bfd5-c8083fa94ef3', 'estrofa_tipo', 'romance_i-o', 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7', 2, 'i-o', 12, true, now(), now()),
	('574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad', 'estrofa_tipo', 'redondilla', null, 1, null, 20, true, now(), now()),
	('8f8b9491-d40d-40eb-a2af-a25bc19fb3da', 'estrofa_tipo', 'quintilla', null, 1, null, 30, true, now(), now()),
	('d8382ff9-249f-4d47-a69e-4c3f7410cb39', 'estrofa_tipo', 'decima', null, 1, null, 40, true, now(), now()),
	('769f4a14-4592-4dc7-9b3e-79d568ca4209', 'estrofa_tipo', 'silva', null, 1, null, 50, true, now(), now()),

	-- metro
	('81567f6d-5e8b-419f-b2c0-f9e9ed7f1017', 'metro', 'octosilabo', null, 1, null, 10, true, now(), now()),
	('72fbe06d-9f46-4690-9df8-a4d9f0611d0d', 'metro', 'endecasilabo', null, 1, null, 20, true, now(), now()),
	('4f2d2610-1e55-40a2-8ad4-e57708d80489', 'metro', 'heptasilabo', null, 1, null, 30, true, now(), now()),

	-- personajes
	('07f54dfa-fc74-43e2-84fe-9f71b4e3f603', 'personajes_genero', 'mixto', null, 1, null, 10, true, now(), now()),
	('493fd3e5-0ef0-4d17-a2ed-e67c4ef7a710', 'personajes_genero', 'solo_masculino', null, 1, null, 20, true, now(), now()),
	('89d0f013-904c-4ab0-b5bd-1d796f89f52f', 'personajes_genero', 'solo_femenino', null, 1, null, 30, true, now(), now()),
	('7f34a8b6-c2a8-44a7-bd57-42574b4b63f4', 'personajes_donaire', 'ausente', null, 1, null, 10, true, now(), now()),
	('15225823-ad28-4f8a-beec-626f865ca279', 'personajes_donaire', 'solo', null, 1, null, 20, true, now(), now()),
	('f3277981-dd41-4e66-a577-c2f7a0d0a249', 'personajes_donaire', 'con_otros', null, 1, null, 30, true, now(), now()),
	('ccf63b66-30b3-4e15-8f2c-38a2810d9527', 'personajes_sobrenatural', 'ausente', null, 1, null, 10, true, now(), now()),
	('bd6a7f91-c2ff-4738-be94-b0fe6356d565', 'personajes_sobrenatural', 'solo', null, 1, null, 20, true, now(), now()),
	('198d7e42-a087-46db-93f9-36a2f74f0f2c', 'personajes_sobrenatural', 'con_otros', null, 1, null, 30, true, now(), now())
on conflict (categoria, termino)
do update set
	termino_padre_id = excluded.termino_padre_id,
	nivel = excluded.nivel,
	patron_especifico = excluded.patron_especifico,
	orden = excluded.orden,
	activo = excluded.activo,
	updated_at = now();
