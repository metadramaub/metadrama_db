-- Fase 5 del plan de precomputación: exposición pública de obras_resumen al catálogo.
--
-- La RLS inicial dejaba leer el resumen a cualquier authenticated (using(true)) y a
-- nadie anónimo. Eso (a) no permite al catálogo público leer métricas y (b) filtra el
-- resumen de obras publicadas-no-visibles a cualquier logueado.
--
-- Aquí se replica EXACTAMENTE la visibilidad de obras (choque nº1 del plan):
--   anon          → solo obras publicadas y visibles.
--   authenticated → admin/IP (todo lo publicado) · editor asignado (su obra) · visibles.
-- Se usan helpers SECURITY DEFINER para evitar recursión de RLS contra obras.

begin;

-- Helper: ¿la obra está publicada y es visible sin login?
create or replace function public.obra_publica_visible(p_obra_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.obras o
    join public.vocabularios v on v.termino_id = o.estado
    where o.obra_id = p_obra_id
      and v.categoria = 'estado'
      and lower(v.termino) = 'publicado'
      and coalesce(o.visible_publico, false) = true
  );
$$;

-- Helper: ¿la obra está publicada y asignada a este editor?
create or replace function public.obra_publicada_asignada(p_obra_id uuid, p_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.obras o
    join public.vocabularios v on v.termino_id = o.estado
    where o.obra_id = p_obra_id
      and v.categoria = 'estado'
      and lower(v.termino) = 'publicado'
      and o.editor_asignado = p_user
  );
$$;

-- Reemplaza la política demasiado amplia.
drop policy if exists "obras_resumen_authenticated_select" on public.obras_resumen;

drop policy if exists "obras_resumen_anon_select" on public.obras_resumen;
create policy "obras_resumen_anon_select"
  on public.obras_resumen for select
  to anon
  using (public.obra_publica_visible(obra_id));

drop policy if exists "obras_resumen_auth_select" on public.obras_resumen;
create policy "obras_resumen_auth_select"
  on public.obras_resumen for select
  to authenticated
  using (
    public.auth_is_admin_or_ip()
    or public.obra_publica_visible(obra_id)
    or public.obra_publicada_asignada(obra_id, auth.uid())
  );

commit;
