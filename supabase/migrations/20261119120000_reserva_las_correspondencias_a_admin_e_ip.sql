begin;

alter policy correspondencias_registrar on public.correspondencias_importador
	with check (
		public.auth_is_admin_or_ip()
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

commit;
