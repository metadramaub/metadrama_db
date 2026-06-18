-- Añade vocabularios.etiqueta: nombre legible para uso público (ficha,
-- selectores, catálogo). Fallback a 'termino' cuando esté vacío.
-- Las etiquetas iniciales se generan a partir del slug; revisables a mano.
--
-- Solo escribe la nueva columna etiqueta (por termino_id); no modifica
-- ningún campo existente de la tabla. La RPC pública pasa a usar
-- coalesce(etiqueta, termino, ...) en los campos de presentación.
--
-- Esta red bloquea el puerto de Postgres: la migración se aplica por el SQL
-- Editor del panel (HTTPS/443) y se registra abajo en schema_migrations con
-- un INSERT manual para que 'supabase db push' no la reclame en otro local.

begin;

alter table public.vocabularios add column if not exists etiqueta text;

-- Backfill de etiquetas (revisar/ajustar manualmente las que no convenzan).
update public.vocabularios set etiqueta = 'Irregular' where termino_id = '00f1532c-fc1f-4449-a304-ec071e70426e';
update public.vocabularios set etiqueta = 'Tragedia' where termino_id = '0146d93a-dec3-4118-a043-fac0d24a957c';
update public.vocabularios set etiqueta = 'Mayoría de agudas' where termino_id = '04649d89-bc9b-46c1-82cf-6c4606e9d901';
update public.vocabularios set etiqueta = 'Copla real' where termino_id = '04f3b8a4-cae2-4b49-8396-10a780d174e6';
update public.vocabularios set etiqueta = 'Romancillo' where termino_id = '07176066-61f6-4b5c-a118-2ae49de4562a';
update public.vocabularios set etiqueta = 'Romancillo heptasílabo' where termino_id = '07d78e10-159e-4a29-837b-4bf46015d9cb';
update public.vocabularios set etiqueta = 'Mixto' where termino_id = '07f54dfa-fc74-43e2-84fe-9f71b4e3f603';
update public.vocabularios set etiqueta = 'Copla real sin quebrado' where termino_id = '08317ef5-a679-4ede-854a-87887ff221e3';
update public.vocabularios set etiqueta = 'Canción endecasílaba' where termino_id = '0d7d464b-541b-4ecd-af02-bd6ea8503d6a';
update public.vocabularios set etiqueta = 'Soneto, tercetos de rima nuclear (ABBAABBACDCEDE)' where termino_id = '0e46109d-1f44-45e4-812f-36f776cf0ae5';
update public.vocabularios set etiqueta = 'Desconocida' where termino_id = '0e7099ae-8ea3-4b9e-bb57-db6f003b02f1';
update public.vocabularios set etiqueta = 'Pareado de arte menor' where termino_id = '0eb921c3-fac8-4619-b41f-572a402907b4';
update public.vocabularios set etiqueta = 'Revisor' where termino_id = '0ed86556-04df-4f1e-9555-a50faeae93cd';
update public.vocabularios set etiqueta = 'Redondilla heptasílaba' where termino_id = '105e6394-6d90-481a-8f49-9b1b214cb35b';
update public.vocabularios set etiqueta = 'Canción petrarquista' where termino_id = '10d7f0d4-9f73-4674-bd88-0bc9d4a51775';
update public.vocabularios set etiqueta = 'Romance (a-e)' where termino_id = '116a7e0b-25eb-4fce-afff-d297964896be';
update public.vocabularios set etiqueta = 'Octava real de esdrújulos' where termino_id = '12a4847e-01f0-4dfb-a13a-b6a92f8c96d5';
update public.vocabularios set etiqueta = 'Solo' where termino_id = '15225823-ad28-4f8a-beec-626f865ca279';
update public.vocabularios set etiqueta = 'Redondilla regular' where termino_id = '1525ae6c-8052-446c-af93-3042341cf610';
update public.vocabularios set etiqueta = 'Romance' where termino_id = '15a34e36-622e-4a1e-be7d-925124e05d9e';
update public.vocabularios set etiqueta = 'Silva de endecasílabos' where termino_id = '1676ad47-403a-4f0e-a6e2-144fd3bdc22e';
update public.vocabularios set etiqueta = 'Romance (a-a)' where termino_id = '18615f98-73c6-47bf-966a-b835b2f42f35';
update public.vocabularios set etiqueta = 'Canción de 8 versos' where termino_id = '18742e01-b696-4998-a8c0-c3c877a7a668';
update public.vocabularios set etiqueta = 'Lira' where termino_id = '187be9a5-f24c-4fde-a4dd-591e9e742c39';
update public.vocabularios set etiqueta = 'Con otros' where termino_id = '198d7e42-a087-46db-93f9-36a2f74f0f2c';
update public.vocabularios set etiqueta = 'Quintilla 2 (abbab)' where termino_id = '1a51a530-0b78-49cd-b36a-d9b6b3a2dfc7';
update public.vocabularios set etiqueta = 'Redondilla' where termino_id = '1affe499-c92d-4cf0-a0f6-46c76a26f88f';
update public.vocabularios set etiqueta = 'IP' where termino_id = '1b652762-8304-4b36-ba17-7fdb64f3cf80';
update public.vocabularios set etiqueta = 'Villancico' where termino_id = '1ba6f164-41c7-4c94-a75d-cc629fc16048';
update public.vocabularios set etiqueta = 'Soneto de esdrújulos' where termino_id = '1d8f8c4e-e2fe-433c-acd9-d5c6550897de';
update public.vocabularios set etiqueta = 'Estilometría léxica' where termino_id = '1f528a44-cbf0-43c6-ae47-d64f4a5bd048';
update public.vocabularios set etiqueta = 'Silva libre' where termino_id = '1fae99e1-dc44-4524-b3ef-ef2469106c24';
update public.vocabularios set etiqueta = 'Quintilla 1 (ababa)' where termino_id = '23ff65f2-d189-4bda-995e-64f22a00ff83';
update public.vocabularios set etiqueta = 'Décima espinela' where termino_id = '25b849f1-02d0-4f97-8636-8b43a5e04855';
update public.vocabularios set etiqueta = 'Colaborativa' where termino_id = '2a39abc6-588b-4e1b-9a39-dc147e1befaf';
update public.vocabularios set etiqueta = 'Borrador' where termino_id = '2c84bf0c-f17f-42fc-8a66-2c9f10bd18c3';
update public.vocabularios set etiqueta = 'Entremés' where termino_id = '2d195eb3-0279-4a73-8e74-4bacab6c30a5';
update public.vocabularios set etiqueta = 'Quintilla 6 (abbaa)' where termino_id = '2ed2d601-df44-4950-ae67-9aef3bc66f7b';
update public.vocabularios set etiqueta = 'Irregularidades métricas' where termino_id = '3007210f-d542-4227-8c91-c5d27bc1f834';
update public.vocabularios set etiqueta = 'Alejandrino' where termino_id = '30800a77-a16b-43d1-81f1-0b7851d5ac02';
update public.vocabularios set etiqueta = 'Dodecasílabo' where termino_id = '32fd1ce9-e230-4961-8043-3857fc03b755';
update public.vocabularios set etiqueta = 'Pareado hexasílabo' where termino_id = '34e96201-72c7-4d8c-97ad-1990df457b07';
update public.vocabularios set etiqueta = 'Copla de pie quebrado' where termino_id = '352eadd0-adb0-4bdc-af69-bdb64586376a';
update public.vocabularios set etiqueta = 'Comedia o tragicomedia' where termino_id = '35a5e896-e622-49cd-a85e-fe61b9db2ea1';
update public.vocabularios set etiqueta = 'Romance (-a)' where termino_id = '36f1dc4d-7dcd-4496-ad39-c7420f4eddba';
update public.vocabularios set etiqueta = 'Romance (u-o)' where termino_id = '3cd773c6-5879-480e-b193-5dd13808643d';
update public.vocabularios set etiqueta = 'Romance (e-o)' where termino_id = '3e1d162a-3fe1-42ab-8ca5-ccb8613c47ca';
update public.vocabularios set etiqueta = 'Patrón alternativo' where termino_id = '403ed6f3-8fbe-4116-8a57-de32dfb58541';
update public.vocabularios set etiqueta = 'Hipermétrico' where termino_id = '41fadfb8-c9c9-4f19-a8bf-91a721a74d8c';
update public.vocabularios set etiqueta = 'Irregular de arte menor' where termino_id = '42599c19-beea-412d-b882-4cd59bc16f32';
update public.vocabularios set etiqueta = 'Solo masculino' where termino_id = '493fd3e5-0ef0-4d17-a2ed-e67c4ef7a710';
update public.vocabularios set etiqueta = 'Quintilla' where termino_id = '4d6d8107-5f7f-4b22-a26e-676df130ffdf';
update public.vocabularios set etiqueta = 'Sexteto-lira a1 (aBaBcC)' where termino_id = '4e6806a3-b21f-4f6a-84b2-33efd8f3a788';
update public.vocabularios set etiqueta = 'Heptasílabo' where termino_id = '4f2d2610-1e55-40a2-8ad4-e57708d80489';
update public.vocabularios set etiqueta = 'Soneto' where termino_id = '5094076a-b93a-4fc4-8b43-a32791b03196';
update public.vocabularios set etiqueta = 'Soneto, tercetos de rima paralela (ABBAABBACDECDE)' where termino_id = '51f337d4-9671-4b4b-b8b2-5552593f64ac';
update public.vocabularios set etiqueta = 'Terceto sin encadenar 1 (AXABYB)' where termino_id = '534f3a96-d168-457d-b6f2-1013f6f789cc';
update public.vocabularios set etiqueta = 'Endecasílabo suelto encadenado' where termino_id = '56ad5023-e0a2-486e-ad32-a4f36037deef';
update public.vocabularios set etiqueta = 'Silva' where termino_id = '590d40a4-5eb4-4992-b0cf-3edf0d379b83';
update public.vocabularios set etiqueta = 'Sextina' where termino_id = '5c7527be-75e8-44b3-bb5e-fbf62174c569';
update public.vocabularios set etiqueta = 'Romancillo hexasílabo' where termino_id = '5c86e84e-b988-4c00-8b92-d8ba80c04e65';
update public.vocabularios set etiqueta = 'Pareado octosílabo' where termino_id = '5c9a5f91-82a6-4af8-b665-89084f9df9a9';
update public.vocabularios set etiqueta = 'Romance (-o)' where termino_id = '5e66c24a-aa59-4fe2-ac2c-181cfe1052d5';
update public.vocabularios set etiqueta = 'Final acentual' where termino_id = '5f6554ef-a87f-49a9-9b1d-5bbd3c90f4d9';
update public.vocabularios set etiqueta = 'Validado' where termino_id = '602b1d44-dc8e-4754-b4ed-61fc48422e64';
update public.vocabularios set etiqueta = 'Romance (o-o)' where termino_id = '62584480-81c9-4f3d-b1b5-496cc99f2918';
update public.vocabularios set etiqueta = 'Quintilla 4 (aabab)' where termino_id = '6362485a-ceef-432b-b07a-f6b6c874da78';
update public.vocabularios set etiqueta = 'Romance (a-o)' where termino_id = '6775de70-f45b-45e6-977d-2ba6d818377c';
update public.vocabularios set etiqueta = 'Endecasílabo suelto puro sin dístico final' where termino_id = '69fd3152-57ab-40ac-87dc-0d5737301b59';
update public.vocabularios set etiqueta = 'Hexasílabo' where termino_id = '6e6e3a7e-40d2-4aff-bab7-27044174b5e5';
update public.vocabularios set etiqueta = 'Fenómenos enunciativos' where termino_id = '6eb2af74-f69e-4d69-8f67-2e8d7b1d8db1';
update public.vocabularios set etiqueta = 'Romance (-i)' where termino_id = '6f6ce057-19d4-4788-b7a9-394dac96f2bc';
update public.vocabularios set etiqueta = 'Sexteto-lira c1 (AabBcC)' where termino_id = '70db0ad6-00e1-4699-bb9b-659cbb6d886e';
update public.vocabularios set etiqueta = 'Endecasílabo' where termino_id = '72fbe06d-9f46-4690-9df8-a4d9f0611d0d';
update public.vocabularios set etiqueta = 'Mayoría de esdrújulas' where termino_id = '74fa5872-c359-4242-ab0b-cffc85c0d557';
update public.vocabularios set etiqueta = 'Endecasílabo suelto y pareado' where termino_id = '7687702c-d260-4693-b88c-7f5eb7e11686';
update public.vocabularios set etiqueta = 'Terceto encadenado' where termino_id = '76b9e1c9-c9ff-4280-afec-5d31d3347677';
update public.vocabularios set etiqueta = 'Romance (-e)' where termino_id = '7727d432-a970-4516-a314-78724484f27a';
update public.vocabularios set etiqueta = 'Quintilla 8 (abbba)' where termino_id = '7880a937-79bf-44cc-b50f-fd0fe20d9106';
update public.vocabularios set etiqueta = 'Irregular de arte mayor' where termino_id = '7b385b78-1fed-468b-8de0-b8260583275d';
update public.vocabularios set etiqueta = 'Seguidilla' where termino_id = '7baf2cc1-b4e5-43f6-9d7a-e2cd46b9856b';
update public.vocabularios set etiqueta = 'Canción sin rima' where termino_id = '7c77b0f1-b224-4726-914a-70c6cce5089d';
update public.vocabularios set etiqueta = 'Loa' where termino_id = '7dde1992-ad94-47c8-948b-1ab00137f540';
update public.vocabularios set etiqueta = 'Redondilla hexasílaba' where termino_id = '7f1bcbaf-834e-4c6f-8190-2547a066a6df';
update public.vocabularios set etiqueta = 'Ausente' where termino_id = '7f34a8b6-c2a8-44a7-bd57-42574b4b63f4';
update public.vocabularios set etiqueta = 'Romance (i-o)' where termino_id = '8269fd6d-905c-4525-8335-9c8978cdbd36';
update public.vocabularios set etiqueta = 'Octosílabo' where termino_id = '82bd7a89-675e-41a9-9324-538589731000';
update public.vocabularios set etiqueta = 'Endecasílabo suelto puro' where termino_id = '834ad9fa-1db6-409e-8084-96a42ffd745c';
update public.vocabularios set etiqueta = 'Zéjel' where termino_id = '838d5dc2-f529-41ce-8b28-94e65e4279e7';
update public.vocabularios set etiqueta = 'Única' where termino_id = '8762cbd9-b92f-4619-b1f4-33c34ec72008';
update public.vocabularios set etiqueta = 'Silva de consonantes irregular' where termino_id = '891fde85-79fc-4330-9e6d-1d5fac1190b8';
update public.vocabularios set etiqueta = 'Solo femenino' where termino_id = '89d0f013-904c-4ab0-b5bd-1d796f89f52f';
update public.vocabularios set etiqueta = 'Romance heroico' where termino_id = '8bcba9bd-996c-4e52-8b92-0316a083ef91';
update public.vocabularios set etiqueta = 'Hipométrico' where termino_id = '8c651724-d4fb-48cd-9348-10a2eb9a0eab';
update public.vocabularios set etiqueta = 'Romance (o-e)' where termino_id = '903a9c8c-d5b6-4184-b66d-f1ddd0826177';
update public.vocabularios set etiqueta = 'Rima defectuosa' where termino_id = '926a2092-22ea-4cfd-b3da-08332200c3cd';
update public.vocabularios set etiqueta = 'Sexteto-lira b2 (AbbACC)' where termino_id = '9309836a-5d11-4bf9-82c9-4ef2951e45c9';
update public.vocabularios set etiqueta = 'Pendiente' where termino_id = '93e52b62-2d7f-408a-bc99-8a51ae02aa4e';
update public.vocabularios set etiqueta = 'Canción de 9 versos' where termino_id = '9a751fd7-3fce-4725-9c14-5ef1bad2cc16';
update public.vocabularios set etiqueta = 'Romance (i-a)' where termino_id = '9c1b50c1-0726-43a3-a9ea-4b5c187fda53';
update public.vocabularios set etiqueta = 'General' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f001';
update public.vocabularios set etiqueta = 'Revisión' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f002';
update public.vocabularios set etiqueta = 'Técnico' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f003';
update public.vocabularios set etiqueta = 'Estado' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f004';
update public.vocabularios set etiqueta = 'Nota propia' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f005';
update public.vocabularios set etiqueta = 'Observación pública' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f006';
update public.vocabularios set etiqueta = 'Individual' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f101';
update public.vocabularios set etiqueta = 'Colaborada' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f102';
update public.vocabularios set etiqueta = 'Desconocida' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f103';
update public.vocabularios set etiqueta = 'Propuesta versológica' where termino_id = '9c8fb9aa-0d4a-4a0a-b43f-35d2c4f3f104';
update public.vocabularios set etiqueta = 'Romance (i-e)' where termino_id = '9d7ac474-6473-4d8f-828d-c834cbc6e0db';
update public.vocabularios set etiqueta = 'Romance (u-a)' where termino_id = '9dc5bbfd-f437-4b5b-aa55-c72d764b11c1';
update public.vocabularios set etiqueta = 'Soneto, tercetos de rima conclusiva (ABBAABBACDEDCE)' where termino_id = '9ec0265c-07cc-472c-9741-9ce906429ad3';
update public.vocabularios set etiqueta = 'Irregular mixto' where termino_id = '9fdc6b5c-dbb8-45cf-8e50-4655c15b6972';
update public.vocabularios set etiqueta = 'Prosa' where termino_id = 'a2086ad5-59fc-438e-aaf3-784efa95a0be';
update public.vocabularios set etiqueta = 'Administrador' where termino_id = 'a23e5a7d-bb90-4d60-b47c-ebebd052acfc';
update public.vocabularios set etiqueta = 'Canción de 15 versos' where termino_id = 'a4286d70-8b15-4640-8b70-4685a74217be';
update public.vocabularios set etiqueta = 'En revisión' where termino_id = 'a479c256-151d-488c-b098-6b554f0b3ea2';
update public.vocabularios set etiqueta = 'Sexteto-lira' where termino_id = 'ae1e40bd-8528-41b8-9edc-dbcf7153896b';
update public.vocabularios set etiqueta = 'Romance (e-e)' where termino_id = 'ae81ce5a-ae84-43cc-8968-a123023fbf89';
update public.vocabularios set etiqueta = 'Décima aumentada' where termino_id = 'b112e17f-3ecf-4556-a648-dead6063c7f2';
update public.vocabularios set etiqueta = 'Copla real de pie quebrado' where termino_id = 'b30e8a01-94d9-40ec-a3ef-222ca3f9f484';
update public.vocabularios set etiqueta = 'Romance (e-a)' where termino_id = 'b50c2b7c-b5cf-40b5-bd84-59a63027c0bf';
update public.vocabularios set etiqueta = 'Laguna' where termino_id = 'b791cb19-e8aa-4b7c-a77d-5dc7490c6454';
update public.vocabularios set etiqueta = 'Tetrasílabo' where termino_id = 'b7d3c277-feaf-4f2f-905a-cfddc45773c4';
update public.vocabularios set etiqueta = 'Endecasílabo suelto' where termino_id = 'b8462640-842d-43a6-a3f4-afaaff19b769';
update public.vocabularios set etiqueta = 'Sexteto-lira c2 (AabBCC)' where termino_id = 'b9b5346d-4b5d-42b4-80d0-d9a1f0d43fb2';
update public.vocabularios set etiqueta = 'Sexteto-lira b1 (abbacC)' where termino_id = 'ba289c1f-df90-465b-8c91-2d530bcbc2af';
update public.vocabularios set etiqueta = 'Terceto de esdrújulos' where termino_id = 'baa17a25-a1db-407c-8d9d-9c7ee33e45aa';
update public.vocabularios set etiqueta = 'Solo' where termino_id = 'bd6a7f91-c2ff-4738-be94-b0fe6356d565';
update public.vocabularios set etiqueta = 'Endecasílabo suelto y pareado sin dístico final' where termino_id = 'be0e5363-1d0e-4124-83b9-475d3a6ad3de';
update public.vocabularios set etiqueta = 'Endecasílabo suelto de esdrújulos' where termino_id = 'bed63177-6811-4a9c-99e8-4822cc60af3c';
update public.vocabularios set etiqueta = 'Quintilla 3 (abaab)' where termino_id = 'befae401-d21f-43cd-8515-15c2c85bce51';
update public.vocabularios set etiqueta = 'Terceto' where termino_id = 'c0a062a4-3ee3-474d-a08f-eb466147e283';
update public.vocabularios set etiqueta = 'Baja' where termino_id = 'c203e638-384a-41d3-b864-0bb1e6661480';
update public.vocabularios set etiqueta = 'Sexteto-lira de esdrújulos' where termino_id = 'c6e16938-cec7-4c3c-950e-7dbe1f600fa4';
update public.vocabularios set etiqueta = 'Canción sin rima de esdrújulos' where termino_id = 'c8154c3a-1158-4ebf-bf9a-72e4fb8424dc';
update public.vocabularios set etiqueta = 'Canción regular (abCabCcdeeDfF)' where termino_id = 'cca8de4d-25af-4840-bc36-0500b37eb60a';
update public.vocabularios set etiqueta = 'Ausente' where termino_id = 'ccf63b66-30b3-4e15-8f2c-38a2810d9527';
update public.vocabularios set etiqueta = 'Octava real' where termino_id = 'd07d21de-bef3-40f3-9573-ce5ac4639651';
update public.vocabularios set etiqueta = 'Publicado' where termino_id = 'd0c8bbe1-8737-4f5e-87cc-2592a41a033f';
update public.vocabularios set etiqueta = 'Alta' where termino_id = 'd47b2c9f-0dd8-4d40-a13a-202765103b8d';
update public.vocabularios set etiqueta = 'Décima' where termino_id = 'd8382ff9-249f-4d47-a69e-4c3f7410cb39';
update public.vocabularios set etiqueta = 'Soneto regular (ABBAABBACDCDCD)' where termino_id = 'ddbf3064-5354-4757-842f-fd21f2c817a0';
update public.vocabularios set etiqueta = 'Tradicional' where termino_id = 'de6e3214-ee01-40da-b4fc-ddfccc97c5df';
update public.vocabularios set etiqueta = 'Editor' where termino_id = 'e08644dc-a40b-4755-a2a7-c894f86a5179';
update public.vocabularios set etiqueta = 'Alternativa' where termino_id = 'e0908d4d-eadb-493e-b1ba-a40c17694632';
update public.vocabularios set etiqueta = 'Quintilla 7 (ababb)' where termino_id = 'e43a29b8-6756-4c3e-be01-5adffb4c9a13';
update public.vocabularios set etiqueta = 'Quintilla 5 (aabba)' where termino_id = 'e493cc23-0fc8-4fcf-9516-7e220ca77004';
update public.vocabularios set etiqueta = 'Octava real regular' where termino_id = 'e51c9fea-b5e1-4942-9407-230a559a31bf';
update public.vocabularios set etiqueta = 'Cantado' where termino_id = 'e61fa399-7b03-4934-b960-db97903e6211';
update public.vocabularios set etiqueta = 'Redondilla doble (abbaacca)' where termino_id = 'e8e11481-6af2-4830-a9cf-a13a0e2221b2';
update public.vocabularios set etiqueta = 'Pentasílabo' where termino_id = 'eac128ba-e438-49b4-8a13-057733271b38';
update public.vocabularios set etiqueta = 'Romance (u-e)' where termino_id = 'ed9fcddb-935b-4a01-ae1b-70f573991903';
update public.vocabularios set etiqueta = 'Terceto sin encadenar 2 (XAAYBB)' where termino_id = 'f2d23e9f-5327-4c5e-b7e5-6b0999de34ff';
update public.vocabularios set etiqueta = 'Con otros' where termino_id = 'f3277981-dd41-4e66-a577-c2f7a0d0a249';
update public.vocabularios set etiqueta = 'Pareado endecasílabo' where termino_id = 'f44a79b4-46d1-47c1-87cf-50e2e4b72f08';
update public.vocabularios set etiqueta = 'Auto sacramental' where termino_id = 'f5134af0-6c04-4d1f-8b02-9695b83baecb';
update public.vocabularios set etiqueta = 'Romance (o-a)' where termino_id = 'f9fce1f1-0dc6-44ab-81e3-2e3845056e49';
update public.vocabularios set etiqueta = 'Silva de consonantes regular' where termino_id = 'fadf6b49-b809-470b-86a9-3e574692c1b5';
update public.vocabularios set etiqueta = 'Media' where termino_id = 'fd3d2e57-d43c-45b0-9843-f4244b7af005';
update public.vocabularios set etiqueta = 'Terceto octosílabo' where termino_id = 'fd8101fc-0915-46ba-be2c-5d3548fa2d5f';

-- Recrea la ficha pública: coalesce(etiqueta, termino, ...) en los campos
-- de presentación. El resto de la función queda idéntico.
create or replace function public.get_obra_ficha_publica(
	p_obra_id uuid,
	p_include_hidden boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_publicado_id uuid;
	v_obra public.obras%rowtype;
begin
	select v.termino_id
	into v_publicado_id
	from public.vocabularios v
	where v.categoria = 'estado'
		and lower(v.termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		return null;
	end if;

	select o.*
	into v_obra
	from public.obras o
	where o.obra_id = p_obra_id
		and o.estado = v_publicado_id
		and (p_include_hidden or coalesce(o.visible_publico, false))
	limit 1;

	if not found then
		return null;
	end if;

	return (
		with jornadas_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'jornada_id', j.jornada_id,
						'jornada_num', j.jornada_num,
						'v_ini', j.v_ini,
						'v_fin', j.v_fin
					)
					order by j.jornada_num
				),
				'[]'::jsonb
			) as items
			from public.jornadas j
			where j.obra_id = v_obra.obra_id
		),
		cuadros_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'cuadro_id', c.cuadro_id,
						'jornada_id', c.jornada_id,
						'cuadro_num', c.cuadro_num,
						'v_ini', c.v_ini,
						'v_fin', c.v_fin
					)
					order by j.jornada_num, c.cuadro_num
				),
				'[]'::jsonb
			) as items
			from public.cuadros c
			join public.jornadas j on j.jornada_id = c.jornada_id
			where j.obra_id = v_obra.obra_id
		),
		grupos_base as (
			select
				g.grupo_atribucion_id,
				g.obra_id as obra_ref_id,
				g.jornada_id,
				j.jornada_num,
				g.created_at
			from public.grupos_atribucion g
			left join public.jornadas j on j.jornada_id = g.jornada_id
			where coalesce(g.obra_id, j.obra_id) = v_obra.obra_id
		),
		propuestas_base as (
			select
				a.atribucion_id,
				a.grupo_atribucion_id,
				a.composicion_autoria_id,
				coalesce(vc.etiqueta, vc.termino, 'individual') as composicion_autoria_term,
				a.created_at
			from public.atribuciones a
			join grupos_base gb on gb.grupo_atribucion_id = a.grupo_atribucion_id
			left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
		),
		autoria_autores_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'autor_id', t.autor_id,
						'nombre_completo', t.nombre_completo
					)
					order by t.nombre_completo
				),
				'[]'::jsonb
			) as items
			from (
				select distinct au.autor_id, au.nombre_completo
				from grupos_base gb
				join propuestas_base pb on pb.grupo_atribucion_id = gb.grupo_atribucion_id
				join public.atribucion_autores aa on aa.atribucion_id = pb.atribucion_id
				join public.autores au on au.autor_id = aa.autor_id
				where gb.jornada_id is null
					and (
						select count(*)
						from propuestas_base pb_count
						where pb_count.grupo_atribucion_id = gb.grupo_atribucion_id
					) = 1
			) t
		),
		grupos_autoria_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'grupo_atribucion_id', gb.grupo_atribucion_id,
						'scope', case when gb.jornada_id is null then 'obra' else 'jornada' end,
						'obra_id', gb.obra_ref_id,
						'jornada_id', gb.jornada_id,
						'jornada_num', gb.jornada_num,
						'propuestas', coalesce(prop.items, '[]'::jsonb)
					)
					order by case when gb.jornada_id is null then 0 else 1 end, coalesce(gb.jornada_num, 0), gb.created_at
				),
				'[]'::jsonb
			) as items
			from grupos_base gb
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'atribucion_id', pb.atribucion_id,
							'composicion_autoria_id', pb.composicion_autoria_id,
							'composicion_autoria_term', pb.composicion_autoria_term,
							'autores', coalesce(aut.items, '[]'::jsonb),
							'evidencias', coalesce(evi.items, '[]'::jsonb)
						)
						order by pb.created_at, pb.atribucion_id
					),
					'[]'::jsonb
				) as items
				from propuestas_base pb
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'autor_id', au.autor_id,
								'nombre_completo', au.nombre_completo
							)
							order by coalesce(aa.orden, 2147483647), au.nombre_completo
						),
						'[]'::jsonb
					) as items
					from public.atribucion_autores aa
					join public.autores au on au.autor_id = aa.autor_id
					where aa.atribucion_id = pb.atribucion_id
				) aut on true
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'atribucion_evidencia_id', ae.atribucion_evidencia_id,
								'tipo_atribucion_id', ae.tipo_atribucion_id,
								'tipo_atribucion_term', coalesce(vt.etiqueta, vt.termino, 'sin_tipo'),
								'fuente_autoria', ae.fuente_autoria
							)
							order by coalesce(vt.termino, ''), ae.created_at, ae.atribucion_evidencia_id
						),
						'[]'::jsonb
					) as items
					from public.atribucion_evidencias ae
					left join public.vocabularios vt on vt.termino_id = ae.tipo_atribucion_id
					where ae.atribucion_id = pb.atribucion_id
				) evi on true
				where pb.grupo_atribucion_id = gb.grupo_atribucion_id
			) prop on true
		),
		caracterizaciones_by_secuencia as (
			select
				scr.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'caracterizacion_rango_id', scr.caracterizacion_rango_id,
							'tipo_caracterizacion_rango_id', scr.tipo_caracterizacion_rango_id,
							'tipo_caracterizacion_rango_term', coalesce(tv.etiqueta, tv.termino, 'sin_tipo'),
							'v_ini', scr.v_ini,
							'v_fin', scr.v_fin,
							'observaciones', scr.observaciones
						)
						order by scr.v_ini, scr.v_fin, scr.caracterizacion_rango_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_caracterizaciones_rango scr
			join public.secuencias_metricas sm on sm.secuencia_id = scr.secuencia_id
			left join public.vocabularios tv on tv.termino_id = scr.tipo_caracterizacion_rango_id
			where sm.obra_id = v_obra.obra_id
			group by scr.secuencia_id
		),
		subtipos_by_secuencia as (
			select
				sse.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'subtipo_secuencia_id', sse.subtipo_secuencia_id,
							'subtipo_estrofa_id', sse.subtipo_estrofa_id,
							'subtipo_estrofa_term', coalesce(sv.etiqueta, sv.termino, 'sin_subtipo'),
							'v_ini', sse.v_ini,
							'v_fin', sse.v_fin
						)
						order by sse.v_ini, sse.v_fin, sse.subtipo_secuencia_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_subtipos_estrofa sse
			join public.secuencias_metricas sm on sm.secuencia_id = sse.secuencia_id
			left join public.vocabularios sv on sv.termino_id = sse.subtipo_estrofa_id
			where sm.obra_id = v_obra.obra_id
			group by sse.secuencia_id
		),
		secuencias_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(est_parent.etiqueta, est_parent.termino, est.etiqueta, est.termino, 'sin_estrofa'),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'evocacion_metrica', sm.evocacion_metrica,
						'evocacion_metrica_texto', sm.evocacion_metrica_texto,
						'intervencion_personajes_femeninos', sm.intervencion_personajes_femeninos,
						'intervencion_figuras_donaire', sm.intervencion_figuras_donaire,
						'intervencion_personajes_sobrenaturales', sm.intervencion_personajes_sobrenaturales,
						'sinopsis', sm.sinopsis,
						'jornada_id', jornada_ref.jornada_id,
						'jornada_num', jornada_ref.jornada_num,
						'cuadro_id', cuadro_ref.cuadro_id,
						'cuadro_num', cuadro_ref.cuadro_num,
						'caracterizaciones_rango', coalesce(cseq.items, '[]'::jsonb),
						'subtipos_estrofa', coalesce(sseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			left join lateral (
				select j.jornada_id, j.jornada_num
				from public.jornadas j
				where j.obra_id = sm.obra_id
					and sm.v_ini >= j.v_ini
					and sm.v_fin <= j.v_fin
				order by j.jornada_num
				limit 1
			) jornada_ref on true
			left join lateral (
				select c.cuadro_id, c.cuadro_num
				from public.cuadros c
				where c.jornada_id = jornada_ref.jornada_id
					and sm.v_ini >= c.v_ini
					and sm.v_fin <= c.v_fin
				order by c.cuadro_num
				limit 1
			) cuadro_ref on true
			left join caracterizaciones_by_secuencia cseq on cseq.secuencia_id = sm.secuencia_id
			left join subtipos_by_secuencia sseq on sseq.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		sinopsis_metrica_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.etiqueta, est.termino, 'sin_estrofa'),
						'sinopsis', sm.sinopsis
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(est_parent.etiqueta, est_parent.termino, est.etiqueta, est.termino, 'sin_estrofa') as forma,
				sum(sm.n_versos)::int as versos
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			where sm.obra_id = v_obra.obra_id
			group by 1
		),
		distribucion_totales as (
			select coalesce(sum(d.versos), 0)::numeric as versos_totales
			from distribucion_base d
		),
		distribucion_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'forma', d.forma,
						'versos', d.versos,
						'porcentaje',
							case
								when t.versos_totales > 0 then round((d.versos::numeric * 100.0) / t.versos_totales, 2)
								else 0
							end
					)
					order by d.versos desc, d.forma
				),
				'[]'::jsonb
			) as items
			from distribucion_base d
			cross join distribucion_totales t
		),
		comentarios_publicos_json as (
			select public.get_obra_comentarios_publicos(v_obra.obra_id, p_include_hidden) as items
		)
		select jsonb_build_object(
			'obra',
			jsonb_build_object(
				'obra_id', v_obra.obra_id,
				'titulo', v_obra.titulo,
				'variantes_titulo', coalesce(v_obra.variantes_titulo, '{}'::text[]),
				'fecha_inicio_trad', v_obra.fecha_inicio_trad,
				'fecha_fin_trad', v_obra.fecha_fin_trad,
				'fuente_fecha', v_obra.fuente_fecha,
				'genero_term', (
					select coalesce(vg.etiqueta, vg.termino)
					from public.vocabularios vg
					where vg.termino_id = v_obra.genero_id
					limit 1
				),
				'total_versos', v_obra.total_versos,
				'edicion', v_obra.edicion,
				'observaciones', v_obra.observaciones,
				'bibliografia', v_obra.bibliografia,
				'updated_at', v_obra.updated_at,
				'autor_ficha_publico', v_obra.autor_ficha_publico,
				'autor_ficha_email_publico', (
					select e.email
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'autor_ficha_orcid_publico', (
					select e.orcid
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'visible_publico', v_obra.visible_publico
			),
			'autoria',
			jsonb_build_object(
				'autores', (select items from autoria_autores_json),
				'grupos', (select items from grupos_autoria_json)
			),
			'estructura',
			jsonb_build_object(
				'jornadas', (select items from jornadas_json),
				'cuadros', (select items from cuadros_json)
			),
			'metrica',
			jsonb_build_object(
				'secuencias', (select items from secuencias_json),
				'distribucion_formas', (select items from distribucion_json)
			),
			'sinopsis_metrica',
			jsonb_build_object(
				'secuencias', (select items from sinopsis_metrica_json)
			),
			'comentarios_publicos',
			coalesce((select items from comentarios_publicos_json), '[]'::jsonb)
		)
	);
end;
$$;

grant execute on function public.get_obra_ficha_publica(uuid, boolean) to anon;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to authenticated;
grant execute on function public.get_obra_ficha_publica(uuid, boolean) to service_role;

-- Registrar como aplicada para el historial del CLI de Supabase.
insert into supabase_migrations.schema_migrations (version, name)
values ('20260618180000', 'vocabularios_etiqueta')
on conflict (version) do nothing;

commit;
