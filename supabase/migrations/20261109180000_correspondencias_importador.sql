-- Correspondencias que el importador aprende de quien importa.
--
-- Cuando una fila llega sin identificar y quien importa la resuelve a mano, puede registrar
-- «este término de la edición es esta forma (y, si quiere, esta arquitectura)». Las
-- importaciones siguientes lo proponen solo en filas pendientes: nunca pisan una regla de
-- data/importador-metrico/equivalencias.propuestas.json ni eligen entre registros que se
-- contradicen. La edición, la obra y la fila de donde salió quedan como procedencia, y
-- creado_por dice quién señaló la equivalencia que faltaba.
--
-- Registra quien tiene permiso de importar; admin/IP revisa después lo nuevo y puede
-- retirarlo. Una correspondencia no se reescribe: si está mal, se borra y se registra otra.
begin;

create table public.correspondencias_importador (
	id uuid primary key default gen_random_uuid(),
	literal text not null check (length(btrim(literal)) between 1 and 400),
	forma text not null,
	arquitectura text,
	procedencia jsonb not null check (jsonb_typeof(procedencia) = 'object'),
	creado_por uuid not null default auth.uid() references auth.users (id),
	creado_en timestamptz not null default now(),
	revisado_por uuid references auth.users (id),
	revisado_en timestamptz,
	check ((revisado_por is null) = (revisado_en is null))
);

comment on table public.correspondencias_importador is
	'Términos de edición que llegaron sin identificar y se resolvieron a mano al importar. Se proponen en importaciones siguientes, solo para filas pendientes.';

-- Una misma correspondencia no se registra dos veces; dos destinos distintos para el mismo
-- término sí, y el importador los trata como conflicto.
create unique index correspondencias_importador_unica
	on public.correspondencias_importador (lower(btrim(literal)), forma, coalesce(arquitectura, ''));

alter table public.correspondencias_importador enable row level security;

create policy correspondencias_consultar on public.correspondencias_importador
	for select to authenticated
	using (public.auth_puede_importar_metrica() or public.auth_is_admin_or_ip());

create policy correspondencias_registrar on public.correspondencias_importador
	for insert to authenticated
	with check (
		public.auth_puede_importar_metrica()
		and creado_por = auth.uid()
		and revisado_por is null
		and exists (
			select 1 from public.formas_metricas f
			where f.slug = forma and f.activo
				and (arquitectura is null or exists (
					select 1 from public.arquitecturas_forma a
					where a.forma_id = f.forma_id and a.slug = arquitectura and a.activo
				))
		)
	);

create policy correspondencias_revisar on public.correspondencias_importador
	for update to authenticated
	using (public.auth_is_admin_or_ip())
	with check (public.auth_is_admin_or_ip() and revisado_por = auth.uid());

create policy correspondencias_retirar on public.correspondencias_importador
	for delete to authenticated
	using (public.auth_is_admin_or_ip());

revoke all on public.correspondencias_importador from anon, authenticated;
grant select, insert, delete on public.correspondencias_importador to authenticated;
-- La revisión solo puede marcar quién y cuándo; el término y el destino no se reescriben.
grant update (revisado_por, revisado_en) on public.correspondencias_importador to authenticated;

-- Guarda: ejecuta la comprobación de catálogo de la política contra el catálogo real.
do $$
begin
	perform 1 from public.formas_metricas f
	where f.activo and exists (
		select 1 from public.arquitecturas_forma a where a.forma_id = f.forma_id and a.activo
	);
	if not found then
		raise exception 'El catálogo no tiene formas activas con arquitectura: la política de registro no podría validar destinos.';
	end if;
	perform count(*) from public.correspondencias_importador;
end $$;

commit;
