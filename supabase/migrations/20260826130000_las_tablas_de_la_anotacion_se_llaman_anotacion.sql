-- Las tablas de la anotación dejan de llamarse «del editor de prueba»
--
-- Se llamaban `*_editor_metrico` de cuando todo era un laboratorio, y `obras_editor_metrico_v2`
-- llevaba un «v2» que iba a envejecer mal. Cuando el sistema viejo muera, `secuencias_editor_metrico`
-- sería *la* tabla de la identidad métrica de una secuencia con un nombre que ya no diría nada.
--
-- **Se hace ahora porque hoy tienen cero filas sobre secuencias reales.** En cuanto el editor V2 se
-- monte en la pestaña de una obra y alguien guarde, deja de ser una migración y un `sed`.
--
-- **Y las claves van en el mismo viaje, que no es cosmética.** `secuencia_prueba_id` decía
-- «secuencia» y apuntaba a una anotación: las tres tablas que la llevan referencian la fila de
-- arriba, y solo esa conoce `secuencias_metricas`. Es un nombre que engaña al leer el modelo.
--
-- | hoy | pasa a ser |
-- |---|---|
-- | `secuencias_editor_metrico` | `anotaciones_metricas` |
-- | `realizaciones_editor_metrico` | `anotacion_realizaciones` |
-- | `elecciones_editor_metrico` | `anotacion_elecciones` |
-- | `elecciones_editor_metrico_resueltas` | `anotacion_elecciones_resueltas` |
-- | `desviaciones_editor_metrico` | `anotacion_desviaciones` |
-- | `escenarios_editor_metrico` | `anotacion_escenarios_prueba` |
-- | `obras_editor_metrico_v2` | `obras_anotacion_nueva` |
-- | `secuencia_prueba_id` | `anotacion_id` |
-- | `realizacion_prueba_id` | `realizacion_id` |
-- | `eleccion_prueba_id` | `eleccion_id` |
-- | `desviacion_prueba_id` | `desviacion_id` |
--
-- *El plural de la primera y el singular de las otras siguen la convención que ya tiene el proyecto:*
-- `formas_metricas` o `secuencias_metricas` son entidades por derecho propio; `esquema_rima_posiciones`
-- o `metro_segmentos` son lo que cuelga de una fila concreta. La anotación es lo primero y sus tres
-- hijas lo segundo.
--
-- Alcance contado antes de escribir: **6 tablas**, **1 vista**, **9 columnas**, **58 restricciones**,
-- **7 índices**, **7 políticas**, **13 disparadores** y **10 funciones**. Todo generado desde la
-- definición viva, no transcrito.
--
-- *La unicidad de `secuencia_id` no hace falta añadirla:* ya existe como índice parcial
-- —`unique (secuencia_id) where secuencia_id is not null`—, que además es lo correcto, porque las
-- anotaciones de escenario la dejan nula.

begin;

do $$
begin
	if to_regclass('public.anotaciones_metricas') is not null then
		raise exception 'El renombrado ya está hecho.';
	end if;
	if to_regclass('public.secuencias_editor_metrico') is null then
		raise exception 'No está la tabla que se quiere renombrar.';
	end if;
	-- **Se hace mientras no hay nada real anotado.** Si hubiera anotaciones de obra, esto dejaría
	-- de ser barato y habría que pensarlo de otra manera.
	if exists (select 1 from public.secuencias_editor_metrico where secuencia_id is not null) then
		raise exception 'Hay anotaciones sobre secuencias reales: el renombrado ya no es inocuo.';
	end if;
end $$;

-- ------------------------------------------------------------------ 1 · las tablas
--
-- Postgres arrastra solo las claves foráneas, los índices y las restricciones: guardan
-- referencias internas, no texto. Lo que no arrastra son los cuerpos de las funciones, que
-- vienen después, y los **nombres** de todo lo demás, que se renombran aquí a mano para que no
-- quede una familia a medias.
alter table public.realizaciones_editor_metrico rename to anotacion_realizaciones;
alter table public.desviaciones_editor_metrico rename to anotacion_desviaciones;
alter table public.secuencias_editor_metrico rename to anotaciones_metricas;
alter table public.escenarios_editor_metrico rename to anotacion_escenarios_prueba;
alter table public.elecciones_editor_metrico rename to anotacion_elecciones;
alter table public.obras_editor_metrico_v2 rename to obras_anotacion_nueva;

-- ------------------------------------------------------------------ 2 · las columnas
--
-- **`secuencia_prueba_id` decía «secuencia» y apuntaba a una anotación.** Las tres tablas que
-- la llevan referencian la fila de arriba, no `secuencias_metricas`; solo la de arriba conoce la
-- secuencia real. Era un nombre que engañaba al leer el modelo.
alter table public.anotaciones_metricas rename column secuencia_prueba_id to anotacion_id;
alter table public.anotacion_realizaciones rename column secuencia_prueba_id to anotacion_id;
alter table public.anotacion_realizaciones rename column realizacion_prueba_id to realizacion_id;
alter table public.anotacion_elecciones rename column secuencia_prueba_id to anotacion_id;
alter table public.anotacion_elecciones rename column realizacion_prueba_id to realizacion_id;
alter table public.anotacion_elecciones rename column eleccion_prueba_id to eleccion_id;
alter table public.anotacion_desviaciones rename column secuencia_prueba_id to anotacion_id;
alter table public.anotacion_desviaciones rename column realizacion_prueba_id to realizacion_id;
alter table public.anotacion_desviaciones rename column desviacion_prueba_id to desviacion_id;

-- ------------------------------------------------------------------ 3 · lo que las nombraba
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_check to anotacion_desviaciones_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_dimension_check to anotacion_desviaciones_dimension_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_esquema_rima_observado_id_fkey to anotacion_desviaciones_esquema_rima_observado_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_falta_sin_observado_check to anotacion_desviaciones_falta_sin_observado_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_metro_observado_id_fkey to anotacion_desviaciones_metro_observado_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_observado_dimension_check to anotacion_desviaciones_observado_dimension_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_pkey to anotacion_desviaciones_pkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_realizacion_prueba_id_fkey to anotacion_desviaciones_realizacion_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_relacion_dimension_check to anotacion_desviaciones_relacion_dimension_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_relacion_norma_check to anotacion_desviaciones_relacion_norma_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_repeticion_observada_id_fkey to anotacion_desviaciones_repeticion_observada_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_seccion_observada_id_fkey to anotacion_desviaciones_seccion_observada_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_secuencia_prueba_id_fkey to anotacion_desviaciones_anotacion_id_fkey;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_v_ini_check to anotacion_desviaciones_v_ini_check;
alter table public.anotacion_desviaciones rename constraint desviaciones_editor_metrico_valor_rasgo_observado_id_fkey to anotacion_desviaciones_valor_rasgo_observado_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_esquema_metrico_id_fkey to anotacion_elecciones_esquema_metrico_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_esquema_rima_id_fkey to anotacion_elecciones_esquema_rima_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_grupo_eleccion_id_fkey to anotacion_elecciones_grupo_eleccion_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_metro_id_fkey to anotacion_elecciones_metro_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_pkey to anotacion_elecciones_pkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_realizacion_prueba_id_fkey to anotacion_elecciones_realizacion_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_repeticion_id_fkey to anotacion_elecciones_repeticion_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_seccion_id_fkey to anotacion_elecciones_seccion_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_secuencia_prueba_id_fkey to anotacion_elecciones_anotacion_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_una_entidad to anotacion_elecciones_una_entidad;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_valor_rasgo_id_fkey to anotacion_elecciones_valor_rasgo_id_fkey;
alter table public.anotacion_elecciones rename constraint elecciones_editor_metrico_variedad_id_fkey to anotacion_elecciones_variedad_id_fkey;
alter table public.anotacion_escenarios_prueba rename constraint escenarios_editor_metrico_created_by_fkey to anotacion_escenarios_prueba_created_by_fkey;
alter table public.anotacion_escenarios_prueba rename constraint escenarios_editor_metrico_nombre_check to anotacion_escenarios_prueba_nombre_check;
alter table public.anotacion_escenarios_prueba rename constraint escenarios_editor_metrico_pkey to anotacion_escenarios_prueba_pkey;
alter table public.anotacion_escenarios_prueba rename constraint escenarios_editor_metrico_updated_by_fkey to anotacion_escenarios_prueba_updated_by_fkey;
alter table public.obras_anotacion_nueva rename constraint obras_editor_metrico_v2_created_by_fkey to obras_anotacion_nueva_created_by_fkey;
alter table public.obras_anotacion_nueva rename constraint obras_editor_metrico_v2_obra_id_fkey to obras_anotacion_nueva_obra_id_fkey;
alter table public.obras_anotacion_nueva rename constraint obras_editor_metrico_v2_pkey to obras_anotacion_nueva_pkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_arquitectura_id_fkey to anotacion_realizaciones_arquitectura_id_fkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_check to anotacion_realizaciones_check;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_check1 to anotacion_realizaciones_check1;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_extension_patron to anotacion_realizaciones_extension_patron;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_orden_check to anotacion_realizaciones_orden_check;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_pkey to anotacion_realizaciones_pkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_realizacion_padre_id_fkey to anotacion_realizaciones_realizacion_padre_id_fkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_seccion_id_fkey to anotacion_realizaciones_seccion_id_fkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_secuencia_prueba_id_fkey to anotacion_realizaciones_anotacion_id_fkey;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_secuencia_prueba_id_orden_key to anotacion_realizaciones_anotacion_id_orden_key;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_unidad_check to anotacion_realizaciones_unidad_check;
alter table public.anotacion_realizaciones rename constraint realizaciones_editor_metrico_v_ini_check to anotacion_realizaciones_v_ini_check;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_arquitectura_id_fkey to anotaciones_metricas_arquitectura_id_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_check to anotaciones_metricas_check;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_created_by_fkey to anotaciones_metricas_created_by_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_escenario_id_fkey to anotaciones_metricas_escenario_id_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_escenario_id_orden_key to anotaciones_metricas_escenario_id_orden_key;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_forma_id_fkey to anotaciones_metricas_forma_id_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_orden_check to anotaciones_metricas_orden_check;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_origen_check to anotaciones_metricas_origen_check;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_pkey to anotaciones_metricas_pkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_secuencia_id_fkey to anotaciones_metricas_secuencia_id_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_updated_by_fkey to anotaciones_metricas_updated_by_fkey;
alter table public.anotaciones_metricas rename constraint secuencias_editor_metrico_v_ini_check to anotaciones_metricas_v_ini_check;
alter index public.desviaciones_editor_metrico_secuencia_idx rename to anotacion_desviaciones_secuencia_idx;
alter index public.elecciones_editor_metrico_secuencia_grupo_idx rename to anotacion_elecciones_secuencia_grupo_idx;
alter index public.elecciones_editor_metrico_secuencia_texto_idx rename to anotacion_elecciones_secuencia_texto_idx;
alter index public.elecciones_editor_metrico_unidad_texto_idx rename to anotacion_elecciones_unidad_texto_idx;
alter index public.realizaciones_editor_metrico_secuencia_idx rename to anotacion_realizaciones_secuencia_idx;
alter index public.secuencias_editor_metrico_escenario_idx rename to anotaciones_metricas_escenario_idx;
alter index public.secuencias_editor_metrico_secuencia_unica rename to anotaciones_metricas_secuencia_unica;
alter policy desviaciones_editor_metrico_admin_ip on public.anotacion_desviaciones rename to anotacion_desviaciones_admin_ip;
alter policy elecciones_editor_metrico_admin_ip on public.anotacion_elecciones rename to anotacion_elecciones_admin_ip;
alter policy escenarios_editor_metrico_admin_ip on public.anotacion_escenarios_prueba rename to anotacion_escenarios_prueba_admin_ip;
alter policy obras_editor_metrico_v2_escritura on public.obras_anotacion_nueva rename to obras_anotacion_nueva_escritura;
alter policy obras_editor_metrico_v2_lectura on public.obras_anotacion_nueva rename to obras_anotacion_nueva_lectura;
alter policy realizaciones_editor_metrico_admin_ip on public.anotacion_realizaciones rename to anotacion_realizaciones_admin_ip;
alter policy secuencias_editor_metrico_admin_ip on public.anotaciones_metricas rename to anotaciones_metricas_admin_ip;
alter trigger trigger_desviaciones_editor_metrico_updated_at on public.anotacion_desviaciones rename to trigger_anotacion_desviaciones_updated_at;
alter trigger trigger_validar_desviacion_editor_metrico on public.anotacion_desviaciones rename to trigger_validar_anotacion_desviacion;
alter trigger trigger_validar_eleccion_editor_metrico on public.anotacion_elecciones rename to trigger_validar_anotacion_eleccion;
alter trigger validar_posicion_eleccion on public.anotacion_elecciones rename to validar_posicion_eleccion;
alter trigger trigger_escenarios_editor_metrico_updated_at on public.anotacion_escenarios_prueba rename to trigger_anotacion_escenarios_prueba_updated_at;
alter trigger realizaciones_editor_metrico_extension_patron on public.anotacion_realizaciones rename to anotacion_realizaciones_extension_patron;
alter trigger trigger_realizaciones_editor_metrico_updated_at on public.anotacion_realizaciones rename to trigger_anotacion_realizaciones_updated_at;
alter trigger trigger_validar_arquitectura_de_realizacion on public.anotacion_realizaciones rename to trigger_validar_arquitectura_de_realizacion;
alter trigger trigger_validar_estructura_unidad_diferida on public.anotacion_realizaciones rename to trigger_validar_estructura_unidad_diferida;
alter trigger trigger_validar_realizacion_editor_metrico on public.anotacion_realizaciones rename to trigger_validar_anotacion_realizacion;
alter trigger trigger_secuencias_editor_metrico_updated_at on public.anotaciones_metricas rename to trigger_anotaciones_metricas_updated_at;
alter trigger trigger_validar_estructura_secuencia_diferida on public.anotaciones_metricas rename to trigger_validar_estructura_secuencia_diferida;
alter trigger trigger_validar_secuencia_editor_metrico on public.anotaciones_metricas rename to trigger_validar_anotacion_metrica;

-- ------------------------------------------------------------------ 4 · la vista
--
-- **No basta con renombrarla.** Una vista fija los nombres de sus columnas de salida al
-- crearse, así que seguiría publicando `eleccion_prueba_id` sobre una columna que ya no se
-- llama así. Se rehace, y se le devuelven sus permisos.
drop view public.elecciones_editor_metrico_resueltas;
create view public.anotacion_elecciones_resueltas as
 SELECT e.eleccion_id,
    e.anotacion_id,
    e.realizacion_id,
    e.grupo_eleccion_id,
    e.observaciones,
    e.created_at,
    e.valor_texto,
    e.metro_id,
    e.esquema_metrico_id,
    e.esquema_rima_id,
    e.seccion_id,
    e.repeticion_id,
    e.valor_rasgo_id,
    e.variedad_id,
    e.posicion_unidad,
    o.opcion_eleccion_id
   FROM anotacion_elecciones e
     LEFT JOIN opciones_eleccion_metrica o ON o.grupo_eleccion_id = e.grupo_eleccion_id AND NOT o.metro_id IS DISTINCT FROM e.metro_id AND NOT o.esquema_metrico_id IS DISTINCT FROM e.esquema_metrico_id AND NOT o.esquema_rima_id IS DISTINCT FROM e.esquema_rima_id AND NOT o.seccion_id IS DISTINCT FROM e.seccion_id AND NOT o.repeticion_id IS DISTINCT FROM e.repeticion_id AND NOT o.valor_rasgo_id IS DISTINCT FROM e.valor_rasgo_id AND NOT o.variedad_id IS DISTINCT FROM e.variedad_id AND NOT o.posicion_unidad IS DISTINCT FROM e.posicion_unidad;
grant select on public.anotacion_elecciones_resueltas to authenticated, anon, service_role;

-- ------------------------------------------------------------------ 5 · las funciones
--
-- Aquí está el peligro de este renombrado. Un `rename` no revalida un cuerpo entrecomillado:
-- las diez seguirían pareciendo sanas y fallarían **la primera vez que alguien guarde**. Se
-- rehacen con los nombres nuevos y después se renombran ellas, que es lo que conserva los
-- disparadores: guardan el identificador interno de la función, no su nombre.
CREATE OR REPLACE FUNCTION public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
	declare
		v_secuencia_id uuid;
		v_escenario_id uuid;
		v_real_id uuid;
		v_real record;
		v_v_ini integer;
		v_v_fin integer;
		v_item jsonb;
		v_grupo record;
		v_total integer;
	begin
		if not public.auth_is_admin_or_ip() then
			raise exception 'Solo admin o IP pueden usar el editor métrico de prueba'
				using errcode = '42501';
		end if;

		v_secuencia_id := nullif(p_datos ->> 'anotacion_id', '')::uuid;
		v_escenario_id := nullif(p_datos ->> 'escenario_id', '')::uuid;
		v_real_id := nullif(p_datos ->> 'secuencia_id', '')::uuid;

		if num_nonnulls(v_escenario_id, v_real_id) <> 1 then
			raise exception 'Una prueba cuelga de un escenario o de una secuencia real, nunca de las dos ni de ninguna';
		end if;

		v_v_ini := (p_datos ->> 'v_ini')::integer;
		v_v_fin := (p_datos ->> 'v_fin')::integer;

		if v_escenario_id is not null then
			if not exists (
				select 1 from public.anotacion_escenarios_prueba
				where escenario_id = v_escenario_id
			) then
				raise exception 'El escenario de prueba no existe';
			end if;
		else
			select s.secuencia_id, s.obra_id, s.v_ini, s.v_fin
			into v_real
			from public.secuencias_metricas s
			where s.secuencia_id = v_real_id;

			if not found then
				raise exception 'La secuencia real que se quiere anotar no existe';
			end if;

			-- El interruptor es por obra: anotar en sombra una obra que nadie ha abierto sería
			-- empezar la migración por la puerta de atrás.
			if not exists (
				select 1 from public.obras_anotacion_nueva
				where obra_id = v_real.obra_id
			) then
				raise exception 'La obra de esta secuencia no está abierta al editor V2';
			end if;

			-- El rango lo manda la secuencia real. La sombra dice qué es ese pasaje, no dónde
			-- empieza: si además se moviera, el contraste entre modelos no compararía lo mismo.
			v_v_ini := v_real.v_ini;
			v_v_fin := v_real.v_fin;
		end if;

		if v_secuencia_id is null then
			insert into public.anotaciones_metricas (
				escenario_id, secuencia_id, orden, v_ini, v_fin, forma_id, arquitectura_id,
				observaciones, created_by, updated_by
			)
			values (
				v_escenario_id,
				v_real_id,
				coalesce((p_datos ->> 'orden')::integer, 1),
				v_v_ini,
				v_v_fin,
				(p_datos ->> 'forma_id')::uuid,
				nullif(p_datos ->> 'arquitectura_id', '')::uuid,
				nullif(btrim(p_datos ->> 'observaciones'), ''),
				auth.uid(),
				auth.uid()
			)
			returning anotacion_id into v_secuencia_id;
		else
			update public.anotaciones_metricas
			set
				escenario_id = v_escenario_id,
				secuencia_id = v_real_id,
				orden = coalesce((p_datos ->> 'orden')::integer, orden),
				v_ini = v_v_ini,
				v_fin = v_v_fin,
				forma_id = (p_datos ->> 'forma_id')::uuid,
				arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid,
				observaciones = nullif(btrim(p_datos ->> 'observaciones'), ''),
				updated_by = auth.uid()
			where anotacion_id = v_secuencia_id;

			if not found then
				raise exception 'Secuencia métrica de prueba no encontrada';
			end if;
		end if;

		delete from public.anotacion_desviaciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_elecciones
		where anotacion_id = v_secuencia_id;
		delete from public.anotacion_realizaciones
		where anotacion_id = v_secuencia_id;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'unidades', '[]'::jsonb))
		loop
			insert into public.anotacion_realizaciones (
				realizacion_id, anotacion_id, realizacion_padre_id, seccion_id,
				orden, v_ini, v_fin, etiqueta, observaciones, arquitectura_id
			)
			values (
				(v_item ->> 'realizacion_id')::uuid,
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_padre_id', '')::uuid,
				nullif(v_item ->> 'seccion_id', '')::uuid,
				(v_item ->> 'orden')::integer,
				(v_item ->> 'v_ini')::integer,
				(v_item ->> 'v_fin')::integer,
				nullif(btrim(v_item ->> 'etiqueta'), ''),
				nullif(btrim(v_item ->> 'observaciones'), ''),
				-- La arquitectura de la unidad cuando no es la de su secuencia: la décima aumentada
				-- entre décimas normales. Nulo es el caso corriente, y el disparador comprueba que sea
				-- de la misma forma y esté declarada intercalable.
				nullif(v_item ->> 'arquitectura_id', '')::uuid
			);
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'elecciones', '[]'::jsonb))
		loop
			-- El formulario sigue enviando la opción que el editor pulsó, pero lo que se guarda es
			-- el dato del catálogo que esa opción representa. Cuando la respuesta es abierta no hay
			-- opción que resolver y el texto viaja tal cual.
			insert into public.anotacion_elecciones (
				anotacion_id,
				realizacion_id,
				grupo_eleccion_id,
				metro_id,
				esquema_metrico_id,
				esquema_rima_id,
				seccion_id,
				repeticion_id,
				valor_rasgo_id,
				variedad_id,
				posicion_unidad,
				valor_texto,
				observaciones
			)
			select
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_id', '')::uuid,
				(v_item ->> 'grupo_eleccion_id')::uuid,
				o.metro_id,
				o.esquema_metrico_id,
				o.esquema_rima_id,
				o.seccion_id,
				o.repeticion_id,
				o.valor_rasgo_id,
				o.variedad_id,
				o.posicion_unidad,
				nullif(btrim(v_item ->> 'valor_texto'), ''),
				nullif(btrim(v_item ->> 'observaciones'), '')
			from (select nullif(v_item ->> 'opcion_eleccion_id', '')::uuid as elegida) k
			left join public.opciones_eleccion_metrica o
				on o.opcion_eleccion_id = k.elegida;
		end loop;

		for v_item in
			select value from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb))
		loop
			insert into public.anotacion_desviaciones (
				anotacion_id, realizacion_id, v_ini, v_fin, dimension,
				relacion_norma, metro_observado_id, esquema_rima_observado_id,
				seccion_observada_id, repeticion_observada_id,
				valor_rasgo_observado_id, observaciones
			)
			values (
				v_secuencia_id,
				nullif(v_item ->> 'realizacion_id', '')::uuid,
				(v_item ->> 'v_ini')::integer,
				(v_item ->> 'v_fin')::integer,
				v_item ->> 'dimension',
				v_item ->> 'relacion_norma',
				nullif(v_item ->> 'metro_observado_id', '')::uuid,
				nullif(v_item ->> 'esquema_rima_observado_id', '')::uuid,
				nullif(v_item ->> 'seccion_observada_id', '')::uuid,
				nullif(v_item ->> 'repeticion_observada_id', '')::uuid,
				nullif(v_item ->> 'valor_rasgo_observado_id', '')::uuid,
				nullif(btrim(v_item ->> 'observaciones'), '')
			);
		end loop;

		for v_grupo in
			select *
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and alcance = 'secuencia'
		loop
			select count(*) into v_total
			from public.anotacion_elecciones
			where anotacion_id = v_secuencia_id
				and grupo_eleccion_id = v_grupo.grupo_eleccion_id
				and realizacion_id is null;

			if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
				raise exception 'La pregunta «%» necesita entre % y % respuestas',
					v_grupo.nombre,
					v_grupo.selecciones_min,
					v_grupo.selecciones_max;
			end if;
		end loop;

		-- Una pregunta sin sección se aplica a la unidad entera, que es la realización que no
		-- cuelga de ninguna otra.
		for v_grupo in
			select grupo.*, unidad.realizacion_id
			from public.anotacion_realizaciones unidad
			join public.grupos_eleccion_metrica_resueltos grupo
				on grupo.arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and grupo.activo
				and grupo.alcance = 'unidad'
				and (
					(grupo.seccion_id is null and unidad.realizacion_padre_id is null)
					or grupo.seccion_id = unidad.seccion_id
				)
			where unidad.anotacion_id = v_secuencia_id
		loop
			select count(*) into v_total
			from public.anotacion_elecciones
			where anotacion_id = v_secuencia_id
				and realizacion_id = v_grupo.realizacion_id
				and grupo_eleccion_id = v_grupo.grupo_eleccion_id;

			if v_total < v_grupo.selecciones_min or v_total > v_grupo.selecciones_max then
				raise exception 'La pregunta «%» necesita entre % y % respuestas en cada unidad aplicable',
					v_grupo.nombre,
					v_grupo.selecciones_min,
					v_grupo.selecciones_max;
			end if;
		end loop;

		-- Lo que declara la norma no puede contradecirse dentro de la unidad que lo contiene.
		-- Se comparan conjuntos completos de respuestas, porque una pregunta puede admitir
		-- varias —la medida de cada posición de la estancia, por ejemplo—.
		for v_grupo in
			select *
			from public.grupos_eleccion_metrica_resueltos
			where arquitectura_id = nullif(p_datos ->> 'arquitectura_id', '')::uuid
				and activo
				and define_norma
		loop
			with recursive ascendencia as (
				select
					realizacion_id,
					realizacion_id as unidad_id
				from public.anotacion_realizaciones
				where anotacion_id = v_secuencia_id
					and realizacion_padre_id is null
				union all
				select
					hija.realizacion_id,
					ascendencia.unidad_id
				from public.anotacion_realizaciones hija
				join ascendencia
					on ascendencia.realizacion_id = hija.realizacion_padre_id
				where hija.anotacion_id = v_secuencia_id
			),
			firmas as (
				select
					-- Una pregunta anclada en una sección se compara dentro de su unidad; una
					-- pregunta de la unidad entera, dentro de la secuencia.
					case when v_grupo.seccion_id is not null then ascendencia.unidad_id end as contenedor,
					eleccion.realizacion_id,
					string_agg(
						coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto),
						'|' order by coalesce(eleccion.opcion_eleccion_id::text, eleccion.valor_texto)
					) as firma
				from public.anotacion_elecciones eleccion
				join ascendencia
					on ascendencia.realizacion_id = eleccion.realizacion_id
				where eleccion.anotacion_id = v_secuencia_id
					and eleccion.grupo_eleccion_id = v_grupo.grupo_eleccion_id
				group by 1, 2
			)
			select count(*)
			into v_total
			from (
				select contenedor
				from firmas
				group by contenedor
				having count(distinct firma) > 1
			) discrepancias;

			if v_total > 0 then
				raise exception
					'La pregunta «%» declara la norma del pasaje: debe responderse igual en todas sus realizaciones',
					v_grupo.nombre;
			end if;
		end loop;

		return v_secuencia_id;
	end;
	$function$
;

CREATE OR REPLACE FUNCTION public.validar_arquitectura_de_realizacion()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
	declare
		v_forma_secuencia uuid;
		v_forma_excepcion uuid;
		v_intercalable boolean;
	begin
		if new.arquitectura_id is null then
			return new;
		end if;

		-- Una excepción es de la unidad, no de una parte suya: una sección no cambia de
		-- arquitectura, cambia la estrofa entera.
		if new.realizacion_padre_id is not null or new.seccion_id is not null then
			raise exception 'Solo una unidad completa puede declarar otra arquitectura, no una de sus partes';
		end if;

		select a.forma_id into v_forma_secuencia
		from public.anotaciones_metricas s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where s.anotacion_id = new.anotacion_id;

		select forma_id, intercalable into v_forma_excepcion, v_intercalable
		from public.arquitecturas_forma
		where arquitectura_id = new.arquitectura_id;

		if v_forma_secuencia is null then
			raise exception 'La secuencia no declara arquitectura: no hay de qué ser excepción';
		end if;
		if v_forma_excepcion is distinct from v_forma_secuencia then
			raise exception 'Una realización solo puede declarar otra arquitectura de su misma forma';
		end if;
		if not coalesce(v_intercalable, false) then
			raise exception 'Esa arquitectura no está declarada intercalable en el catálogo';
		end if;

		return new;
	end;
	$function$
;

CREATE OR REPLACE FUNCTION public.validar_desviacion_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_secuencia_ini integer;
	v_secuencia_fin integer;
	v_configuracion_id uuid;
begin
	select v_ini, v_fin, arquitectura_id
	into v_secuencia_ini, v_secuencia_fin, v_configuracion_id
	from public.anotaciones_metricas
	where anotacion_id = new.anotacion_id;

	if v_configuracion_id is null then
		raise exception 'Una tramo sin forma no admite desviaciones respecto de una norma inexistente';
	end if;
	if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
		raise exception 'La desviación debe quedar dentro del rango de la secuencia';
	end if;
	if new.realizacion_id is not null and not exists (
		select 1 from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_id
			and anotacion_id = new.anotacion_id
	) then
		raise exception 'La unidad de la desviación no pertenece a la secuencia';
	end if;
	return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validar_eleccion_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_arquitectura_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_padre_unidad uuid;
	v_maximo integer;
	v_tipo_control text;
	v_longitud_esperada integer;
	v_total integer;
	v_entidades integer;
begin
	select arquitectura_id into v_arquitectura_id
	from public.anotaciones_metricas
	where anotacion_id = new.anotacion_id;

	select alcance, seccion_id, selecciones_max, tipo_control
	into v_alcance, v_seccion_grupo, v_maximo, v_tipo_control
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and arquitectura_id = v_arquitectura_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la arquitectura seleccionada';
	end if;

	v_entidades := num_nonnulls(
		new.metro_id, new.esquema_metrico_id, new.esquema_rima_id, new.seccion_id,
		new.repeticion_id, new.valor_rasgo_id, new.variedad_id
	);

	if v_tipo_control = 'opciones' then
		if v_entidades <> 1 or new.valor_texto is not null then
			raise exception 'Esta pregunta necesita un dato normalizado del catálogo';
		end if;
		-- La elección tiene que estar entre las admitidas por la pregunta. Hoy las admitidas
		-- son las opciones declaradas; cuando se deriven, esta comprobación mirará ahí sin que
		-- cambie nada de lo guardado.
		if not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = new.grupo_eleccion_id
				and o.activo
				and o.metro_id is not distinct from new.metro_id
				and o.esquema_metrico_id is not distinct from new.esquema_metrico_id
				and o.esquema_rima_id is not distinct from new.esquema_rima_id
				and o.seccion_id is not distinct from new.seccion_id
				and o.repeticion_id is not distinct from new.repeticion_id
				and o.valor_rasgo_id is not distinct from new.valor_rasgo_id
				and o.variedad_id is not distinct from new.variedad_id
				and o.posicion_unidad is not distinct from new.posicion_unidad
		) then
			raise exception 'La elección no está admitida por esta pregunta';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		if v_entidades <> 0 or new.valor_texto is null then
			raise exception 'Esta pregunta necesita un esquema de rima escrito';
		end if;
	end if;

	if v_alcance = 'unidad' then
		if new.realizacion_id is null then
			raise exception 'La elección de unidad necesita una realización';
		end if;

		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre_unidad, v_longitud_esperada
		from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_id
			and anotacion_id = new.anotacion_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;

		if v_seccion_grupo is null then
			if v_padre_unidad is not null then
				raise exception 'La pregunta se refiere a la unidad y no a una de sus partes';
			end if;
		elsif v_seccion_grupo is distinct from v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		select v_fin - v_ini + 1
		into v_longitud_esperada
		from public.anotaciones_metricas
		where anotacion_id = new.anotacion_id;
	end if;

	if v_tipo_control = 'esquema_rima'
		and length(replace(new.valor_texto, ':', '')) <> v_longitud_esperada
	then
		raise exception
			'El esquema de rima debe tener % posiciones y tiene %',
			v_longitud_esperada,
			length(replace(new.valor_texto, ':', ''));
	end if;

	select count(*)
	into v_total
	from public.anotacion_elecciones
	where anotacion_id = new.anotacion_id
		and grupo_eleccion_id = new.grupo_eleccion_id
		and realizacion_id is not distinct from new.realizacion_id
		and eleccion_id <> new.eleccion_id;

	if v_total + 1 > v_maximo then
		raise exception 'La elección supera la cardinalidad máxima del grupo';
	end if;

	return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validar_estructura_editor_metrico_diferida()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
	perform public.validar_estructura_anotacion(
		case when tg_op = 'DELETE' then old.anotacion_id else new.anotacion_id end
	);
	return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
	declare
		v_configuracion_id uuid;
		v_seccion record;
		v_unidad record;
		v_padre record;
		v_total integer;
	begin
		select arquitectura_id into v_configuracion_id
		from public.anotaciones_metricas
		where anotacion_id = p_secuencia_id;

		if v_configuracion_id is null then
			return;
		end if;

		-- Las secciones raíz, cada unidad contra las de su propia arquitectura.
		for v_unidad in
			select realizacion_id,
				coalesce(arquitectura_id, v_configuracion_id) as arquitectura_id
			from public.anotacion_realizaciones
			where anotacion_id = p_secuencia_id
				and realizacion_padre_id is null
				and seccion_id is null
		loop
			for v_seccion in
				select *
				from public.estructuras_secciones
				where arquitectura_id = v_unidad.arquitectura_id
					and seccion_padre_id is null
			loop
				select count(*) into v_total
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and realizacion_padre_id = v_unidad.realizacion_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null and v_total > v_seccion.repeticiones_max then
					raise exception 'Cada unidad admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;

		-- Las secciones internas se buscan por su sección superior, que ya identifica una sola
		-- arquitectura: basta con mirar las de todas las que están en juego en esta secuencia.
		for v_seccion in
			select s.*
			from public.estructuras_secciones s
			where s.seccion_padre_id is not null
				and s.arquitectura_id in (
					select v_configuracion_id
					union
					select arquitectura_id
					from public.anotacion_realizaciones
					where anotacion_id = p_secuencia_id
						and arquitectura_id is not null
				)
		loop
			for v_padre in
				select realizacion_id
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and seccion_id = v_seccion.seccion_padre_id
			loop
				select count(*) into v_total
				from public.anotacion_realizaciones
				where anotacion_id = p_secuencia_id
					and realizacion_padre_id = v_padre.realizacion_id
					and seccion_id = v_seccion.seccion_id;

				if v_total < coalesce(v_seccion.repeticiones_min, 0) then
					raise exception 'Cada unidad superior necesita al menos % realizaciones de «%»',
						v_seccion.repeticiones_min,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
				if v_seccion.repeticiones_max is not null
					and v_total > v_seccion.repeticiones_max
				then
					raise exception 'Cada unidad superior admite como máximo % realizaciones de «%»',
						v_seccion.repeticiones_max,
						coalesce(v_seccion.nombre, v_seccion.tipo_seccion);
				end if;
			end loop;
		end loop;
	end;
	$function$
;

CREATE OR REPLACE FUNCTION public.validar_extension_patron_realizaciones_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_secuencia_id uuid := coalesce(new.anotacion_id, old.anotacion_id);
	v_incompatibles integer;
begin
	select count(*)
	into v_incompatibles
	from (
		select r.seccion_id, r.realizacion_padre_id
		from public.anotacion_realizaciones r
		join public.estructuras_secciones s on s.seccion_id = r.seccion_id
		where r.anotacion_id = v_secuencia_id
			and s.primera_realizacion_define_patron
		group by r.seccion_id, r.realizacion_padre_id
		having count(distinct (r.v_fin - r.v_ini + 1)) > 1
	) discrepancias;

	if v_incompatibles > 0 then
		raise exception 'Las realizaciones cuyo patrón declara la primera deben tener la misma extensión';
	end if;

	return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validar_posicion_eleccion_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_versos integer;
	v_repetida integer;
begin
	if new.posicion_unidad is null or new.realizacion_id is null then
		return new;
	end if;

	select v_fin - v_ini + 1 into v_versos
	from public.anotacion_realizaciones
	where realizacion_id = new.realizacion_id;

	if v_versos is not null and new.posicion_unidad > v_versos then
		raise exception
			'La posición % no existe: la realización tiene % versos',
			new.posicion_unidad, v_versos;
	end if;

	select count(*) into v_repetida
	from public.anotacion_elecciones eleccion
	where eleccion.realizacion_id = new.realizacion_id
		and eleccion.grupo_eleccion_id = new.grupo_eleccion_id
		and eleccion.eleccion_id is distinct from new.eleccion_id
		and eleccion.posicion_unidad = new.posicion_unidad;

	if v_repetida > 0 then
		raise exception 'Ya hay una respuesta para la posición %', new.posicion_unidad;
	end if;

	return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validar_realizacion_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
	declare
		v_arquitectura_id uuid;
		v_arquitectura_unidad uuid;
		v_arquitectura_efectiva uuid;
		v_secuencia_ini integer;
		v_secuencia_fin integer;
		v_seccion_padre_esperada uuid;
		v_seccion_padre_real uuid;
		v_padre_ini integer;
		v_padre_fin integer;
	begin
		select arquitectura_id, v_ini, v_fin
		into v_arquitectura_id, v_secuencia_ini, v_secuencia_fin
		from public.anotaciones_metricas
		where anotacion_id = new.anotacion_id;

		if new.v_ini < v_secuencia_ini or new.v_fin > v_secuencia_fin then
			raise exception 'La realización debe quedar dentro del rango de la secuencia';
		end if;

		-- Una realización sin sección es la realización de la unidad que define la forma.
		if new.seccion_id is null then
			if new.realizacion_padre_id is not null then
				raise exception 'La realización de la unidad no cuelga de ninguna otra';
			end if;
			return new;
		end if;

		if new.realizacion_padre_id is null then
			raise exception 'Una sección se realiza siempre dentro de una unidad';
		end if;

		-- **La arquitectura de la unidad de la que cuelga esta sección.** Se sube por la cadena
		-- hasta la realización sin padre, que es la de la unidad. Casi siempre no declara nada y
		-- manda la de la secuencia; cuando declara una intercalada, manda la suya.
		with recursive cadena as (
			select realizacion_id, realizacion_padre_id, arquitectura_id
			from public.anotacion_realizaciones
			where realizacion_id = new.realizacion_padre_id
				and anotacion_id = new.anotacion_id
			union all
			select superior.realizacion_id,
				superior.realizacion_padre_id,
				superior.arquitectura_id
			from public.anotacion_realizaciones superior
			join cadena on cadena.realizacion_padre_id = superior.realizacion_id
			where superior.anotacion_id = new.anotacion_id
		)
		select arquitectura_id into v_arquitectura_unidad
		from cadena
		where realizacion_padre_id is null;

		v_arquitectura_efectiva := coalesce(v_arquitectura_unidad, v_arquitectura_id);

		select seccion_padre_id
		into v_seccion_padre_esperada
		from public.estructuras_secciones
		where seccion_id = new.seccion_id
			and arquitectura_id = v_arquitectura_efectiva;

		if not found then
			raise exception 'La sección realizada no pertenece a la arquitectura seleccionada';
		end if;

		select seccion_id, v_ini, v_fin
		into v_seccion_padre_real, v_padre_ini, v_padre_fin
		from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_padre_id
			and anotacion_id = new.anotacion_id;

		if not found then
			raise exception 'La realización superior debe pertenecer a la misma secuencia';
		end if;
		-- Una sección raíz cuelga de la unidad, cuya realización no tiene sección; una sección
		-- interna cuelga de la realización de su sección superior.
		if v_seccion_padre_real is distinct from v_seccion_padre_esperada then
			raise exception 'La realización superior no corresponde a la jerarquía de la sección';
		end if;
		if new.v_ini < v_padre_ini or new.v_fin > v_padre_fin then
			raise exception 'La sección interna debe quedar dentro del rango de su unidad';
		end if;

		return new;
	end;
	$function$
;

CREATE OR REPLACE FUNCTION public.validar_secuencia_editor_metrico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_tipo_registro text;
	v_slug text;
begin
	select tipo_registro, slug
	into v_tipo_registro, v_slug
	from public.formas_metricas
	where forma_id = new.forma_id
		and activo;

	if v_tipo_registro is null then
		raise exception 'La entrada métrica no está activa';
	end if;

	if v_tipo_registro = 'sin_forma' then
		if new.arquitectura_id is not null then
			raise exception 'Una tramo sin forma no admite arquitectura normativa';
		end if;
		if v_slug = 'verso_aislado' and new.v_fin <> new.v_ini then
			raise exception 'Verso aislado debe abarcar exactamente un verso';
		end if;
		if v_slug = 'irregular' and new.v_fin - new.v_ini + 1 < 2 then
			raise exception 'Versificación irregular debe abarcar al menos dos versos';
		end if;
		return new;
	end if;

	if new.arquitectura_id is null or not exists (
		select 1
		from public.arquitecturas_forma configuracion
		where configuracion.arquitectura_id = new.arquitectura_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
	) then
		raise exception 'La arquitectura no pertenece a una forma activa';
	end if;

	return new;
end;
$function$
;

alter function public.validar_extension_patron_realizaciones_editor_metrico() rename to validar_extension_patron_anotacion_realizaciones;
alter function public.validar_estructura_secuencia_editor_metrico(p_secuencia_id uuid) rename to validar_estructura_anotacion;
alter function public.validar_estructura_editor_metrico_diferida() rename to validar_estructura_anotacion_diferida;
alter function public.validar_posicion_eleccion_editor_metrico() rename to validar_posicion_anotacion_eleccion;
alter function public.guardar_secuencia_editor_metrico_prueba(p_datos jsonb) rename to guardar_anotacion_metrica;
alter function public.validar_realizacion_editor_metrico() rename to validar_anotacion_realizacion;
alter function public.validar_desviacion_editor_metrico() rename to validar_anotacion_desviacion;
alter function public.validar_secuencia_editor_metrico() rename to validar_anotacion_metrica;
alter function public.validar_eleccion_editor_metrico() rename to validar_anotacion_eleccion;

-- ------------------------------------------------------------------ Comprobaciones
--
-- **Una función SQL no está probada hasta que se ejecuta**, y aquí se han rehecho diez. Seis son
-- disparadores, así que se ejercitan escribiendo una anotación de verdad y deshaciéndola.
--
-- *`guardar_anotacion_metrica` no se puede probar aquí*: empieza exigiendo `auth_is_admin_or_ip()`,
-- que en una migración es falso. Se prueba guardando una secuencia desde el editor, que es la
-- prueba buena y la que se hizo al aplicar esto.

do $$
declare
	v_escenario uuid;
	v_autor uuid;
	v_anotacion uuid;
	v_unidad uuid;
	v_forma uuid;
	v_arquitectura uuid;
	v_restos integer;
begin
	-- 1 · Nada conserva el nombre viejo.
	select count(*) into v_restos
	from pg_class c
	where c.relnamespace = 'public'::regnamespace and c.relname like '%editor_metrico%';
	if v_restos > 0 then
		raise exception 'Quedan % objetos con el nombre viejo.', v_restos;
	end if;

	select count(*) into v_restos
	from pg_proc p
	where p.pronamespace = 'public'::regnamespace
		and (p.proname like '%editor_metrico%'
			or pg_get_functiondef(p.oid) ~ '(secuencias_editor_metrico|realizaciones_editor_metrico|elecciones_editor_metrico|desviaciones_editor_metrico|escenarios_editor_metrico|obras_editor_metrico_v2|secuencia_prueba_id|realizacion_prueba_id|eleccion_prueba_id|desviacion_prueba_id)');
	if v_restos > 0 then
		raise exception 'Quedan % funciones que nombran lo viejo.', v_restos;
	end if;

	-- 2 · Y una anotación entera entra y sale, con sus seis disparadores por medio.
	select escenario_id, created_by into v_escenario, v_autor
	from public.anotacion_escenarios_prueba limit 1;
	if v_escenario is null then
		raise exception 'No hay escenario de prueba donde comprobarlo.';
	end if;
	if v_autor is null then
		select created_by into v_autor from public.anotaciones_metricas where created_by is not null limit 1;
	end if;

	select a.arquitectura_id, a.forma_id into v_arquitectura, v_forma
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'redondilla' and a.activo
	limit 1;
	if v_arquitectura is null then
		raise exception 'No está la redondilla donde comprobarlo.';
	end if;

	insert into public.anotaciones_metricas
		(escenario_id, orden, v_ini, v_fin, forma_id, arquitectura_id, created_by, updated_by)
	values (v_escenario, 9999, 200001, 200004, v_forma, v_arquitectura, v_autor, v_autor)
	returning anotacion_id into v_anotacion;

	insert into public.anotacion_realizaciones
		(realizacion_id, anotacion_id, realizacion_padre_id, seccion_id, orden, v_ini, v_fin)
	values (gen_random_uuid(), v_anotacion, null, null, 1, 200001, 200004)
	returning realizacion_id into v_unidad;

	-- Fuerza las diferidas ahora, sobre estas filas y no sobre las de nadie.
	set constraints all immediate;
	perform public.validar_estructura_anotacion(v_anotacion);

	if (select count(*) from public.anotacion_realizaciones where anotacion_id = v_anotacion) <> 1 then
		raise exception 'La realización no ha entrado.';
	end if;

	delete from public.anotaciones_metricas where anotacion_id = v_anotacion;
	set constraints all immediate;

	-- 3 · Y la vista publica los nombres nuevos.
	if not exists (
		select 1 from information_schema.columns
		where table_name = 'anotacion_elecciones_resueltas' and column_name = 'anotacion_id'
	) then
		raise exception 'La vista sigue publicando el nombre viejo.';
	end if;
end $$;

commit;
