begin;

-- Ambos slugs se calculan en triggers BEFORE INSERT. El valor vacío declara
-- también ante PostgREST que el campo puede omitirse al insertar; el trigger
-- lo sustituye por el slug normalizado y único, como hacía hasta ahora.
alter table public.obras
	alter column slug set default '';

alter table public.autores
	alter column slug set default '';

commit;
