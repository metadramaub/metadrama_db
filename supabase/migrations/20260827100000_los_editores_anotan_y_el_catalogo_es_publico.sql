-- Los editores anotan lo suyo, y el catálogo es público de verdad
--
-- Dos cosas que van juntas porque sin las dos un editor no puede anotar nada.
--
-- **El catálogo métrico pasa a ser legible por cualquiera.** Lo era ya de hecho —veintitrés de sus
-- veintiséis tablas tenían `SELECT = catalogo_metrico_publico()`, que mira si la sección `formas`
-- está activa para anónimos—, pero esa condición hacía dos trabajos a la vez y uno estaba de más:
-- **apagar la sección desde `/dashboard/publicacion` dejaba también sin catálogo al equipo
-- editorial**, a mitad de una anotación. Ocultar la página ya lo hace la propia página, con
-- `requireSectionVisible('formas')`, y seguirá haciéndolo.
--
-- Así que `catalogo_metrico_publico()` pasa a decir que sí, sin condiciones, y las veintitrés
-- políticas la siguen sin tocarlas. `/formas` y `/demarcador` son recursos consultables por
-- cualquiera, como quiere el IP; lo que el interruptor apaga es la página, no el dato.
--
-- Se añaden además las **tres que no la tenían**: `catalogo_metrico_estado` —que es la que muerde,
-- porque el cargador se rinde si no puede leer la revisión y el editor recibiría el catálogo
-- vacío— y `metro_segmentos` y `repeticion_posiciones`, tablas de detalle de otras que sí eran
-- públicas. *`catalogo_metrico_estado` publica de paso quién tocó el catálogo por última vez; es un
-- identificador de editor y el proyecto los acredita, así que no se considera un dato reservado.*
--
-- **Y la anotación se abre a los editores, con el alcance por obra asignada.** Las políticas de
-- admin/IP se quedan como están y **se añade una segunda** a cada tabla: las políticas se suman, así
-- que nada de lo que hoy funciona cambia. El predicado no se inventa: es el mismo que gobierna
-- `secuencias_metricas` desde siempre —admin o IP siempre; editor si la obra es la suya—, ahora en
-- una función para no repetirlo cinco veces.
--
-- *El revisor lee y no escribe*, como en `secuencias_metricas`. La figura no se usa todavía.
--
-- *El laboratorio se queda en admin/IP*: no es de nadie y se retira pronto.

begin;

do $$
begin
	if to_regprocedure('public.catalogo_metrico_publico()') is null then
		raise exception 'No está la función que gobierna la lectura del catálogo.';
	end if;
	if to_regclass('public.anotaciones_metricas') is null then
		raise exception 'No están las tablas de la anotación.';
	end if;
end $$;

-- ------------------------------------------------------------------ 1 · el catálogo, público
create or replace function public.catalogo_metrico_publico()
returns boolean
language sql
immutable
set search_path to 'public'
as $$
	-- **El catálogo métrico se lee siempre.** `/formas` y el demarcador son recursos consultables
	-- por cualquiera, y el equipo editorial necesita el catálogo para anotar. Que la página se
	-- muestre o no lo decide `secciones_publicas`, y lo aplica la propia página.
	select true;
$$;

create policy catalogo_metrico_estado_publico on public.catalogo_metrico_estado
	for select using (public.catalogo_metrico_publico());
create policy metro_segmentos_publico on public.metro_segmentos
	for select using (public.catalogo_metrico_publico());
create policy repeticion_posiciones_publico on public.repeticion_posiciones
	for select using (public.catalogo_metrico_publico());

-- ------------------------------------------------------------------ 2 · quién puede con qué obra
create or replace function public.auth_puede_editar_obra(p_obra_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
	-- El mismo predicado que gobierna `secuencias_metricas`: admin o IP con cualquiera; editor solo
	-- con la suya.
	select exists (
		select 1
		from public.obras o
		join public.editores e on e.user_id = auth.uid()
		join public.vocabularios vr on vr.termino_id = e.role
		where o.obra_id = p_obra_id
			and coalesce(e.activo, true)
			and (
				lower(vr.termino) in ('admin', 'ip')
				or (lower(vr.termino) = 'editor' and o.editor_asignado = e.user_id)
			)
	);
$$;

create or replace function public.auth_puede_ver_obra(p_obra_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
	-- Ver alcanza además al revisor, y a quien esté apuntado como revisor de esa obra.
	select public.auth_puede_editar_obra(p_obra_id)
		or exists (
			select 1
			from public.editores e
			join public.vocabularios vr on vr.termino_id = e.role
			where e.user_id = auth.uid()
				and coalesce(e.activo, true)
				and lower(vr.termino) = 'revisor'
		)
		or exists (
			select 1 from public.obras_revisores r
			where r.obra_id = p_obra_id and r.revisor_id = auth.uid()
		);
$$;

/**
 * De qué obra es una anotación.
 *
 * Una anotación cuelga o de una secuencia real —y entonces tiene obra— o de un escenario de
 * pruebas, que no es de nadie. Devuelve nulo en el segundo caso, y así las políticas de obra no
 * alcanzan al laboratorio, que sigue siendo de admin e IP.
 */
create or replace function public.obra_de_anotacion(p_anotacion_id uuid)
returns uuid
language sql
stable
security definer
set search_path to 'public'
as $$
	select s.obra_id
	from public.anotaciones_metricas a
	join public.secuencias_metricas s on s.secuencia_id = a.secuencia_id
	where a.anotacion_id = p_anotacion_id;
$$;

-- ------------------------------------------------------------------ 3 · la anotación, por obra
--
-- Las políticas se suman: estas se añaden a las de admin/IP, que no se tocan.
create policy anotaciones_metricas_editor on public.anotaciones_metricas
	for all
	using (secuencia_id is not null and public.auth_puede_editar_obra(
		(select s.obra_id from public.secuencias_metricas s where s.secuencia_id = anotaciones_metricas.secuencia_id)
	))
	with check (secuencia_id is not null and public.auth_puede_editar_obra(
		(select s.obra_id from public.secuencias_metricas s where s.secuencia_id = anotaciones_metricas.secuencia_id)
	));

create policy anotaciones_metricas_lectura on public.anotaciones_metricas
	for select
	using (secuencia_id is not null and public.auth_puede_ver_obra(
		(select s.obra_id from public.secuencias_metricas s where s.secuencia_id = anotaciones_metricas.secuencia_id)
	));

create policy anotacion_realizaciones_editor on public.anotacion_realizaciones
	for all
	using (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)))
	with check (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)));
create policy anotacion_realizaciones_lectura on public.anotacion_realizaciones
	for select using (public.auth_puede_ver_obra(public.obra_de_anotacion(anotacion_id)));

create policy anotacion_elecciones_editor on public.anotacion_elecciones
	for all
	using (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)))
	with check (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)));
create policy anotacion_elecciones_lectura on public.anotacion_elecciones
	for select using (public.auth_puede_ver_obra(public.obra_de_anotacion(anotacion_id)));

create policy anotacion_desviaciones_editor on public.anotacion_desviaciones
	for all
	using (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)))
	with check (public.auth_puede_editar_obra(public.obra_de_anotacion(anotacion_id)));
create policy anotacion_desviaciones_lectura on public.anotacion_desviaciones
	for select using (public.auth_puede_ver_obra(public.obra_de_anotacion(anotacion_id)));

-- ------------------------------------------------------------------ Comprobaciones
--
-- **Una función SQL no está probada hasta que se ejecuta.** Los predicados se prueban con un editor
-- de verdad y sus obras de verdad, poniéndose en su lugar con `request.jwt.claims`, que es lo que
-- hace PostgREST.
do $$
declare
	v_editor uuid;
	v_suya uuid;
	v_ajena uuid;
begin
	select e.user_id into v_editor
	from public.editores e
	join public.vocabularios v on v.termino_id = e.role
	where lower(v.termino) = 'editor' and coalesce(e.activo, true)
		and exists (select 1 from public.obras o where o.editor_asignado = e.user_id)
	limit 1;
	if v_editor is null then
		raise exception 'No hay ningún editor con obra asignada donde comprobarlo.';
	end if;

	select obra_id into v_suya from public.obras where editor_asignado = v_editor limit 1;
	select obra_id into v_ajena
	from public.obras
	where editor_asignado is distinct from v_editor
	limit 1;
	if v_suya is null or v_ajena is null then
		raise exception 'Hacen falta una obra suya y una ajena para comprobarlo.';
	end if;

	perform set_config('request.jwt.claims',
		json_build_object('sub', v_editor::text, 'role', 'authenticated')::text, true);

	if not public.auth_puede_editar_obra(v_suya) then
		raise exception 'Un editor no puede editar su propia obra.';
	end if;
	if public.auth_puede_editar_obra(v_ajena) then
		raise exception 'Un editor puede editar una obra que no es suya.';
	end if;
	if not public.auth_puede_ver_obra(v_suya) then
		raise exception 'Un editor no puede ver su propia obra.';
	end if;

	-- Y sin sesión no puede nada.
	perform set_config('request.jwt.claims', '', true);
	if public.auth_puede_editar_obra(v_suya) then
		raise exception 'Alguien sin sesión puede editar una obra.';
	end if;

	-- El catálogo, en cambio, se lee siempre.
	if not public.catalogo_metrico_publico() then
		raise exception 'El catálogo no es legible.';
	end if;
end $$;

commit;
