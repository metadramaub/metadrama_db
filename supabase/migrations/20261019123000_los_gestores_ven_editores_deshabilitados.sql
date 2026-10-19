-- El gestor necesita retirar encargos de personas deshabilitadas; cada persona
-- debe poder distinguir su deshabilitación de la ausencia de perfil.
drop policy if exists editores_select_gestores on public.editores;
create policy editores_select_gestores on public.editores
for select to authenticated using (public.auth_is_admin_or_ip());
alter policy editores_select_self on public.editores to authenticated
using (user_id = auth.uid());
