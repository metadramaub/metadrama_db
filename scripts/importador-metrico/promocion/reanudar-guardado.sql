-- Solo después de resolver la incidencia y comprobar la migración, con aprobación.
begin;
set local lock_timeout = '5s';
grant execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) to authenticated;
notify pgrst, 'reload schema';
commit;
