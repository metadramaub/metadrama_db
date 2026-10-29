-- RECUPERACIÓN OPERATIVA. Solo ejecutar con aprobación, en la base elegida explícitamente.
-- Detiene nuevas confirmaciones, incluidas las de admin/IP. No borra ni oculta las copias.
begin;
set local lock_timeout = '5s';
revoke execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) from authenticated;
notify pgrst, 'reload schema';
commit;
