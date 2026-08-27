begin;

drop function if exists public.publicar_demarcador_version(uuid);
drop table if exists public.demarcador_versiones;

drop table if exists public.demarcador_familias_config;
drop function if exists public.ensure_demarcador_familia_raiz();

commit;
