-- SOLO ENSAYO: elimina exclusivamente las tablas nuevas. El origen no se ha modificado.
begin;
do $$ begin
 if current_database()<>'control_obras_preparacion' then
  raise exception 'Reversión restringida a la restauración aislada';
 end if;
end $$;
drop view if exists public.control_obras_preparacion;
drop table if exists public.obras_corpus;
drop table if exists public.corpus;
drop table if exists public.fichas_completas;
commit;
