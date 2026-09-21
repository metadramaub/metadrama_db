-- Un editor puede crear el autor que falta.
--
-- La aplicación lo daba por hecho desde siempre —`canCreateAutores` admite a `editor`, y el
-- endpoint y el botón del dashboard van con ella—, pero la base solo dejaba insertar a admin/IP.
-- El editor veía entonces el mensaje crudo de Postgres, que dice que la fila viola la política
-- de seguridad, y se lee como que no tiene permiso.
--
-- La asimetría se veía además en la propia anotación: `atribucion_autores` deja ya que el editor
-- asignado a una obra le atribuya un autor existente. Lo único que no podía era crear el que
-- faltaba, que es justo lo que aparece al anotar una obra nueva.
--
-- Solo se abre la inserción. Corregir un autor y borrarlo siguen siendo de admin/IP, como dicen
-- `canManageAutores` y `canDeleteAutores`: el nombre de un autor lo leen las fichas públicas y
-- las atribuciones de todas las obras, y un renombrado toca mucho más que la obra que se anota.

drop policy if exists "autores_insert_admin_ip" on public.autores;
drop policy if exists "autores_insert_editor_activo" on public.autores;
create policy "autores_insert_editor_activo"
on public.autores
for insert
to authenticated
with check (
	exists (
		select 1
		from public.editores e
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
	)
);
