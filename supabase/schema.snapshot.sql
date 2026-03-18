


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."actualizar_autoria_obra"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
declare
  v_obra_id uuid;
begin
  -- Get obra_id from the affected rango
  select r.obra_id into v_obra_id
  from public.rangos r
  where r.rango_id = coalesce(new.rango_id, old.rango_id);

  -- Refresh obras.autoria for the affected obra
  update public.obras o
  set autoria = (
    select array_agg(distinct a.nombre_completo order by a.nombre_completo)
    from public.rangos r
    join public.rangos_autores ra on ra.rango_id = r.rango_id
    join public.autores a on a.autor_id = ra.autor_id
    where r.obra_id = v_obra_id
  )
  where o.obra_id = v_obra_id;

  return coalesce(new, old);
end;
$$;


ALTER FUNCTION "public"."actualizar_autoria_obra"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."actualizar_autoria_obra"() IS 'Actualiza automáticamente el campo obras.autoria cuando cambian los autores en rangos_autores';



CREATE OR REPLACE FUNCTION "public"."actualizar_autoria_obras_por_autor"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
	if old.nombre_completo is not distinct from new.nombre_completo then
		return new;
	end if;

	update public.obras o
	set autoria = (
		select array_agg(distinct a.nombre_completo order by a.nombre_completo)
		from public.rangos r
		join public.rangos_autores ra on ra.rango_id = r.rango_id
		join public.autores a on a.autor_id = ra.autor_id
		where r.obra_id = o.obra_id
	)
	where exists (
		select 1
		from public.rangos r2
		join public.rangos_autores ra2 on ra2.rango_id = r2.rango_id
		where r2.obra_id = o.obra_id
			and ra2.autor_id = new.autor_id
	);

	return new;
end;
$$;


ALTER FUNCTION "public"."actualizar_autoria_obras_por_autor"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."actualizar_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;


ALTER FUNCTION "public"."actualizar_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_is_admin_or_ip"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
	select exists (
		select 1
		from public.editores e
		join public.vocabularios vr on vr.termino_id = e.role
		where e.user_id = auth.uid()
			and coalesce(e.activo, true)
			and lower(vr.termino) in ('admin', 'ip')
	);
$$;


ALTER FUNCTION "public"."auth_is_admin_or_ip"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_obra_ficha_publica"("p_obra_id" "uuid", "p_include_hidden" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
	v_publicado_id uuid;
	v_obra public.obras%rowtype;
begin
	select v.termino_id
	into v_publicado_id
	from public.vocabularios v
	where v.categoria = 'estado'
		and lower(v.termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		return null;
	end if;

	select o.*
	into v_obra
	from public.obras o
	where o.obra_id = p_obra_id
		and o.estado = v_publicado_id
		and (p_include_hidden or coalesce(o.visible_publico, false))
	limit 1;

	if not found then
		return null;
	end if;

	return (
		with jornadas_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'jornada_id', j.jornada_id,
						'jornada_num', j.jornada_num,
						'v_ini', j.v_ini,
						'v_fin', j.v_fin
					)
					order by j.jornada_num
				),
				'[]'::jsonb
			) as items
			from public.jornadas j
			where j.obra_id = v_obra.obra_id
		),
		cuadros_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'cuadro_id', c.cuadro_id,
						'jornada_id', c.jornada_id,
						'cuadro_num', c.cuadro_num,
						'v_ini', c.v_ini,
						'v_fin', c.v_fin,
						'descripcion', c.descripcion
					)
					order by j.jornada_num, c.cuadro_num
				),
				'[]'::jsonb
			) as items
			from public.cuadros c
			join public.jornadas j on j.jornada_id = c.jornada_id
			where j.obra_id = v_obra.obra_id
		),
		autoria_autores_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'autor_id', t.autor_id,
						'nombre_completo', t.nombre_completo
					)
					order by t.nombre_completo
				),
				'[]'::jsonb
			) as items
			from (
				select distinct a.autor_id, a.nombre_completo
				from public.rangos r
				join public.rangos_autores ra on ra.rango_id = r.rango_id
				join public.autores a on a.autor_id = ra.autor_id
				where r.obra_id = v_obra.obra_id
			) t
		),
		rangos_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'rango_id', r.rango_id,
						'v_ini', r.v_ini,
						'v_fin', r.v_fin,
						'autores', coalesce(rautores.items, '[]'::jsonb)
					)
					order by r.v_ini
				),
				'[]'::jsonb
			) as items
			from public.rangos r
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'autor_id', a.autor_id,
							'nombre_completo', a.nombre_completo
						)
						order by a.nombre_completo
					),
					'[]'::jsonb
				) as items
				from public.rangos_autores ra
				join public.autores a on a.autor_id = ra.autor_id
				where ra.rango_id = r.rango_id
			) rautores on true
			where r.obra_id = v_obra.obra_id
		),
		variaciones_by_secuencia as (
			select
				sv.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'variacion_id', sv.variacion_id,
							'tipo_variacion_id', sv.tipo_variacion_id,
							'tipo_variacion_term', coalesce(tv.termino, 'sin_tipo'),
							'v_ini', sv.v_ini,
							'v_fin', sv.v_fin,
							'observaciones', sv.observaciones
						)
						order by sv.v_ini, sv.v_fin, sv.variacion_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_variaciones sv
			join public.secuencias_metricas sm on sm.secuencia_id = sv.secuencia_id
			left join public.vocabularios tv on tv.termino_id = sv.tipo_variacion_id
			where sm.obra_id = v_obra.obra_id
			group by sv.secuencia_id
		),
		secuencias_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', sm.estrofa_tipo_id,
						'estrofa_tipo_term', coalesce(est.termino, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(est_parent.termino, est.termino, 'sin_estrofa'),
						'estrofa_tipo_forma', coalesce(est_parent.tipo_forma, est.tipo_forma),
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'personajes_genero', sm.personajes_genero,
						'personajes_donaire', sm.personajes_donaire,
						'personajes_sobrenatural', sm.personajes_sobrenatural,
						'sinopsis', sm.sinopsis,
						'jornada_id', jornada_ref.jornada_id,
						'jornada_num', jornada_ref.jornada_num,
						'cuadro_id', cuadro_ref.cuadro_id,
						'cuadro_num', cuadro_ref.cuadro_num,
						'variaciones', coalesce(vseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			left join lateral (
				select j.jornada_id, j.jornada_num
				from public.jornadas j
				where j.obra_id = sm.obra_id
					and sm.v_ini >= j.v_ini
					and sm.v_fin <= j.v_fin
				order by j.jornada_num
				limit 1
			) jornada_ref on true
			left join lateral (
				select c.cuadro_id, c.cuadro_num
				from public.cuadros c
				where c.jornada_id = jornada_ref.jornada_id
					and sm.v_ini >= c.v_ini
					and sm.v_fin <= c.v_fin
				order by c.cuadro_num
				limit 1
			) cuadro_ref on true
			left join variaciones_by_secuencia vseq on vseq.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(est_parent.termino, est.termino, 'sin_estrofa') as forma,
				sum(sm.n_versos)::int as versos
			from public.secuencias_metricas sm
			left join public.vocabularios est on est.termino_id = sm.estrofa_tipo_id
			left join public.vocabularios est_parent on est_parent.termino_id = est.termino_padre_id
			where sm.obra_id = v_obra.obra_id
			group by 1
		),
		distribucion_totales as (
			select coalesce(sum(d.versos), 0)::numeric as versos_totales
			from distribucion_base d
		),
		distribucion_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'forma', d.forma,
						'versos', d.versos,
						'porcentaje',
							case
								when t.versos_totales > 0 then round((d.versos::numeric * 100.0) / t.versos_totales, 2)
								else 0
							end
					)
					order by d.versos desc, d.forma
				),
				'[]'::jsonb
			) as items
			from distribucion_base d
			cross join distribucion_totales t
		)
		select jsonb_build_object(
			'obra',
			jsonb_build_object(
				'obra_id', v_obra.obra_id,
				'titulo', v_obra.titulo,
				'variantes_titulo', coalesce(v_obra.variantes_titulo, '{}'::text[]),
				'fecha_inicio_trad', v_obra.fecha_inicio_trad,
				'fecha_fin_trad', v_obra.fecha_fin_trad,
				'fuente_fecha', v_obra.fuente_fecha,
				'genero_term', (
					select vg.termino
					from public.vocabularios vg
					where vg.termino_id = v_obra.genero_id
					limit 1
				),
				'total_versos', v_obra.total_versos,
				'edicion', v_obra.edicion,
				'observaciones', v_obra.observaciones,
				'bibliografia', v_obra.bibliografia,
				'updated_at', v_obra.updated_at,
				'autor_ficha_publico', v_obra.autor_ficha_publico,
				'autor_ficha_email_publico', (
					select e.email
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'autor_ficha_orcid_publico', (
					select e.orcid
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'url_informe_autoria', v_obra.url_informe_autoria,
				'visible_publico', v_obra.visible_publico
			),
			'autoria',
			jsonb_build_object(
				'autores', (select items from autoria_autores_json),
				'rangos', (select items from rangos_json)
			),
			'estructura',
			jsonb_build_object(
				'jornadas', (select items from jornadas_json),
				'cuadros', (select items from cuadros_json)
			),
			'metrica',
			jsonb_build_object(
				'secuencias', (select items from secuencias_json),
				'distribucion_formas', (select items from distribucion_json)
			)
		)
	);
end;
$$;


ALTER FUNCTION "public"."get_obra_ficha_publica"("p_obra_id" "uuid", "p_include_hidden" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."obras_enforce_public_visibility"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
	v_publicado_id uuid;
begin
	select termino_id
	into v_publicado_id
	from public.vocabularios
	where categoria = 'estado'
		and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		raise exception 'No existe estado=publicado en vocabularios';
	end if;

	if coalesce(new.visible_publico, false)
		and new.estado is distinct from v_publicado_id then
		raise exception using
			errcode = '23514',
			message = 'visible_publico solo puede activarse cuando la obra esta en estado publicado';
	end if;

	if tg_op = 'UPDATE'
		and old.estado = v_publicado_id
		and new.estado is distinct from v_publicado_id then
		new.visible_publico := false;
	end if;

	return new;
end;
$$;


ALTER FUNCTION "public"."obras_enforce_public_visibility"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_obra_autor_ficha_publico"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
	if new.editor_asignado is null then
		new.autor_ficha_publico := null;
		return new;
	end if;

	select e.nombre_completo
	into new.autor_ficha_publico
	from public.editores e
	where e.user_id = new.editor_asignado
	limit 1;

	return new;
end;
$$;


ALTER FUNCTION "public"."sync_obra_autor_ficha_publico"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_estrofa_tipo_metros_categories"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
	v_estrofa_categoria text;
	v_metro_categoria text;
begin
	select categoria into v_estrofa_categoria
	from public.vocabularios
	where termino_id = new.estrofa_tipo_id;

	if v_estrofa_categoria is distinct from 'estrofa_tipo' then
		raise exception using
			errcode = '23514',
			message = 'estrofa_tipo_id debe apuntar a vocabularios.categoria=estrofa_tipo';
	end if;

	select categoria into v_metro_categoria
	from public.vocabularios
	where termino_id = new.metro_id;

	if v_metro_categoria is distinct from 'metro' then
		raise exception using
			errcode = '23514',
			message = 'metro_id debe apuntar a vocabularios.categoria=metro';
	end if;

	return new;
end;
$$;


ALTER FUNCTION "public"."validate_estrofa_tipo_metros_categories"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."autores" (
    "autor_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nombre_completo" character varying(200) NOT NULL,
    "nombre_normalizado" character varying(200),
    "variantes_nombre" "text"[],
    "bnedatos_id" character varying(20),
    "viaf_id" character varying(20),
    "wikidata_id" character varying(20),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."autores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comentarios_internos" (
    "comentario_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "obra_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "comentario" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tipo_comentario_id" "uuid" NOT NULL,
    "secuencia_id" "uuid",
    "jornada_id" "uuid",
    "cuadro_id" "uuid",
    "rango_id" "uuid",
    CONSTRAINT "comentarios_internos_un_contexto_chk" CHECK (((((COALESCE((("secuencia_id" IS NOT NULL))::integer, 0) + COALESCE((("jornada_id" IS NOT NULL))::integer, 0)) + COALESCE((("cuadro_id" IS NOT NULL))::integer, 0)) + COALESCE((("rango_id" IS NOT NULL))::integer, 0)) <= 1))
);


ALTER TABLE "public"."comentarios_internos" OWNER TO "postgres";


COMMENT ON TABLE "public"."comentarios_internos" IS 'Historial de comentarios internos entre editores y revisores';



CREATE TABLE IF NOT EXISTS "public"."cuadros" (
    "cuadro_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "jornada_id" "uuid" NOT NULL,
    "cuadro_num" integer NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL,
    "descripcion" "text",
    "certeza_editor" "uuid" NOT NULL
);


ALTER TABLE "public"."cuadros" OWNER TO "postgres";


COMMENT ON TABLE "public"."cuadros" IS 'Se revisa junto con la obra, sin estado independiente';



CREATE TABLE IF NOT EXISTS "public"."dashboard_activity_state" (
    "user_id" "uuid" NOT NULL,
    "last_seen_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."dashboard_activity_state" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."editores" (
    "user_id" "uuid" NOT NULL,
    "nombre_completo" character varying(200) NOT NULL,
    "email" character varying(255) NOT NULL,
    "role" "uuid" NOT NULL,
    "activo" boolean DEFAULT true,
    "institucion" character varying(200),
    "orcid" character varying(20),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_login" timestamp with time zone
);


ALTER TABLE "public"."editores" OWNER TO "postgres";


COMMENT ON TABLE "public"."editores" IS 'user_id debe coincidir con auth.users(id). Supabase Auth gestiona contraseñas y autenticación';



CREATE TABLE IF NOT EXISTS "public"."estrofa_tipo_metros" (
    "estrofa_tipo_id" "uuid" NOT NULL,
    "metro_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."estrofa_tipo_metros" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."jornadas" (
    "jornada_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "obra_id" "uuid" NOT NULL,
    "jornada_num" integer NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL
);


ALTER TABLE "public"."jornadas" OWNER TO "postgres";


COMMENT ON TABLE "public"."jornadas" IS 'División estructural formal de la obra. Autoría se declara en rangos/rangos_autores';



CREATE TABLE IF NOT EXISTS "public"."obras" (
    "obra_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "titulo" "text" NOT NULL,
    "titulo_normalizado" "text",
    "variantes_titulo" "text"[],
    "fecha_inicio_trad" integer,
    "fecha_fin_trad" integer,
    "fuente_fecha" "text",
    "fecha_inicio_metadrama" integer,
    "fecha_fin_metadrama" integer,
    "edicion" "text",
    "autoria" "text"[],
    "url_informe_autoria" "text",
    "editor_asignado" "uuid",
    "fecha_asignacion" timestamp with time zone,
    "estado" "uuid" NOT NULL,
    "visible_publico" boolean DEFAULT false,
    "fecha_cambio_estado" timestamp with time zone,
    "observaciones" "text",
    "genero_id" "uuid",
    "total_versos" integer,
    "bibliografia" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "autor_ficha_publico" "text"
);


ALTER TABLE "public"."obras" OWNER TO "postgres";


COMMENT ON COLUMN "public"."obras"."autoria" IS 'Array calculado de nombres de autores. Se genera automáticamente desde rangos_autores';



COMMENT ON COLUMN "public"."obras"."observaciones" IS 'Otras observaciones del editor sobre la obra. Texto libre en markdown.';



COMMENT ON COLUMN "public"."obras"."bibliografia" IS 'Bibliografía específica sobre la métrica de la obra.';



CREATE TABLE IF NOT EXISTS "public"."obras_revisores" (
    "obra_id" "uuid" NOT NULL,
    "revisor_id" "uuid" NOT NULL,
    "asignado_por" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obras_revisores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."proyecto_activo" (
    "id" integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'activo'::"text"
);


ALTER TABLE "public"."proyecto_activo" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."proyecto_activo_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."proyecto_activo_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."proyecto_activo_id_seq" OWNED BY "public"."proyecto_activo"."id";



CREATE TABLE IF NOT EXISTS "public"."rangos" (
    "rango_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "obra_id" "uuid" NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL,
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."rangos" OWNER TO "postgres";


COMMENT ON TABLE "public"."rangos" IS 'Rangos continuos de versos con la misma autoría. Un rango puede tener 1 autor (único) o múltiples (colaborada sin determinar)';



CREATE TABLE IF NOT EXISTS "public"."rangos_autores" (
    "rango_id" "uuid" NOT NULL,
    "autor_id" "uuid" NOT NULL
);


ALTER TABLE "public"."rangos_autores" OWNER TO "postgres";


COMMENT ON TABLE "public"."rangos_autores" IS '1 fila por rango = autoría única. 2+ filas por rango = autoría múltiple (obra colaborada sin determinar quién escribió cada parte)';



CREATE TABLE IF NOT EXISTS "public"."secuencias_metricas" (
    "secuencia_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "obra_id" "uuid" NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL,
    "n_versos" integer NOT NULL,
    "estrofa_tipo_id" "uuid",
    "inaugura_espacio" boolean DEFAULT false,
    "personajes_genero" character varying(20) DEFAULT 'mixto'::character varying NOT NULL,
    "personajes_donaire" character varying(20) DEFAULT 'ausente'::character varying NOT NULL,
    "personajes_sobrenatural" character varying(20) DEFAULT 'ausente'::character varying NOT NULL,
    "certeza_editor" "uuid" NOT NULL,
    "sinopsis" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "versos_partidos" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."secuencias_metricas" OWNER TO "postgres";


COMMENT ON TABLE "public"."secuencias_metricas" IS 'Unidad de análisis métrico. Autoría se consulta desde rangos/rangos_autores por overlap de versos';



COMMENT ON COLUMN "public"."secuencias_metricas"."sinopsis" IS 'Sinopsis argumental breve de la secuencia.';



CREATE TABLE IF NOT EXISTS "public"."secuencias_variaciones" (
    "variacion_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "secuencia_id" "uuid" NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL,
    "observaciones" "text",
    "tipo_variacion_id" "uuid" NOT NULL,
    CONSTRAINT "secuencias_variaciones_v_ini_le_v_fin_chk" CHECK (("v_ini" <= "v_fin"))
);


ALTER TABLE "public"."secuencias_variaciones" OWNER TO "postgres";


COMMENT ON TABLE "public"."secuencias_variaciones" IS 'Para marcar versos cantados u otras variaciones dentro de secuencias';



CREATE TABLE IF NOT EXISTS "public"."vocabularios" (
    "termino_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "categoria" character varying(50) NOT NULL,
    "termino" character varying(100) NOT NULL,
    "termino_padre_id" "uuid",
    "nivel" integer,
    "patron_especifico" character varying(50),
    "definicion" "text",
    "ejemplo" "text",
    "equivalencias" "text"[],
    "orden" integer,
    "activo" boolean DEFAULT true,
    "bibliografia" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "tipo_forma" "text",
    CONSTRAINT "vocabularios_tipo_forma_check" CHECK ((("tipo_forma" IS NULL) OR ("tipo_forma" = ANY (ARRAY['forma_espanola'::"text", 'forma_italiana'::"text"]))))
);


ALTER TABLE "public"."vocabularios" OWNER TO "postgres";


COMMENT ON TABLE "public"."vocabularios" IS 'Vocabulario único con jerarquía opcional. Incluye role_editor para roles del sistema';



COMMENT ON COLUMN "public"."vocabularios"."categoria" IS 'metro, estrofa_tipo, genero, estado, certeza_editor, personajes_genero, personajes_donaire, personajes_sobrenatural, role_editor';



ALTER TABLE ONLY "public"."proyecto_activo" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."proyecto_activo_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."autores"
    ADD CONSTRAINT "autores_pkey" PRIMARY KEY ("autor_id");



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_pkey" PRIMARY KEY ("comentario_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "cuadros_pkey" PRIMARY KEY ("cuadro_id");



ALTER TABLE ONLY "public"."dashboard_activity_state"
    ADD CONSTRAINT "dashboard_activity_state_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."estrofa_tipo_metros"
    ADD CONSTRAINT "estrofa_tipo_metros_pkey" PRIMARY KEY ("estrofa_tipo_id", "metro_id");



ALTER TABLE ONLY "public"."jornadas"
    ADD CONSTRAINT "jornadas_pkey" PRIMARY KEY ("jornada_id");



ALTER TABLE ONLY "public"."obras"
    ADD CONSTRAINT "obras_pkey" PRIMARY KEY ("obra_id");



ALTER TABLE ONLY "public"."obras_revisores"
    ADD CONSTRAINT "obras_revisores_pkey" PRIMARY KEY ("obra_id", "revisor_id");



ALTER TABLE ONLY "public"."proyecto_activo"
    ADD CONSTRAINT "proyecto_activo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_pkey" PRIMARY KEY ("rango_id", "autor_id");



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_pkey" PRIMARY KEY ("rango_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_pkey" PRIMARY KEY ("secuencia_id");



ALTER TABLE ONLY "public"."secuencias_variaciones"
    ADD CONSTRAINT "secuencias_variaciones_pkey" PRIMARY KEY ("variacion_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "uq_cuadros_jornada_num" UNIQUE ("jornada_id", "cuadro_num");



ALTER TABLE ONLY "public"."jornadas"
    ADD CONSTRAINT "uq_jornadas_obra_num" UNIQUE ("obra_id", "jornada_num");



ALTER TABLE ONLY "public"."vocabularios"
    ADD CONSTRAINT "uq_vocabularios_categoria_termino" UNIQUE ("categoria", "termino");



ALTER TABLE ONLY "public"."vocabularios"
    ADD CONSTRAINT "vocabularios_pkey" PRIMARY KEY ("termino_id");



CREATE INDEX "dashboard_activity_state_last_seen_idx" ON "public"."dashboard_activity_state" USING "btree" ("last_seen_at");



CREATE INDEX "idx_autores_nombre_normalizado" ON "public"."autores" USING "btree" ("nombre_normalizado");



CREATE UNIQUE INDEX "idx_autores_nombre_normalizado_unique" ON "public"."autores" USING "btree" ("nombre_normalizado") WHERE ("nombre_normalizado" IS NOT NULL);



CREATE INDEX "idx_comentarios_cuadro" ON "public"."comentarios_internos" USING "btree" ("cuadro_id");



CREATE INDEX "idx_comentarios_jornada" ON "public"."comentarios_internos" USING "btree" ("jornada_id");



CREATE INDEX "idx_comentarios_obra" ON "public"."comentarios_internos" USING "btree" ("obra_id");



CREATE INDEX "idx_comentarios_rango" ON "public"."comentarios_internos" USING "btree" ("rango_id");



CREATE INDEX "idx_comentarios_secuencia" ON "public"."comentarios_internos" USING "btree" ("secuencia_id");



CREATE INDEX "idx_comentarios_tipo" ON "public"."comentarios_internos" USING "btree" ("tipo_comentario_id");



CREATE INDEX "idx_comentarios_user" ON "public"."comentarios_internos" USING "btree" ("user_id");



CREATE INDEX "idx_cuadros_jornada" ON "public"."cuadros" USING "btree" ("jornada_id");



CREATE INDEX "idx_editores_activo" ON "public"."editores" USING "btree" ("activo");



CREATE INDEX "idx_editores_email" ON "public"."editores" USING "btree" ("email");



CREATE INDEX "idx_editores_role" ON "public"."editores" USING "btree" ("role");



CREATE INDEX "idx_estrofa_tipo_metros_metro_id" ON "public"."estrofa_tipo_metros" USING "btree" ("metro_id");



CREATE INDEX "idx_jornadas_obra" ON "public"."jornadas" USING "btree" ("obra_id");



CREATE INDEX "idx_obras_editor_asignado" ON "public"."obras" USING "btree" ("editor_asignado");



CREATE INDEX "idx_obras_estado" ON "public"."obras" USING "btree" ("estado");



CREATE INDEX "idx_obras_titulo_normalizado" ON "public"."obras" USING "btree" ("titulo_normalizado");



CREATE INDEX "idx_obras_visible_publico" ON "public"."obras" USING "btree" ("visible_publico");



CREATE INDEX "idx_rangos_autores_autor" ON "public"."rangos_autores" USING "btree" ("autor_id");



CREATE INDEX "idx_rangos_autores_rango" ON "public"."rangos_autores" USING "btree" ("rango_id");



CREATE INDEX "idx_rangos_obra" ON "public"."rangos" USING "btree" ("obra_id");



CREATE INDEX "idx_rangos_versos" ON "public"."rangos" USING "btree" ("obra_id", "v_ini", "v_fin");



CREATE INDEX "idx_secuencias_estrofa" ON "public"."secuencias_metricas" USING "btree" ("estrofa_tipo_id");



CREATE INDEX "idx_secuencias_obra" ON "public"."secuencias_metricas" USING "btree" ("obra_id");



CREATE INDEX "idx_secuencias_v_ini" ON "public"."secuencias_metricas" USING "btree" ("v_ini");



CREATE INDEX "idx_variaciones_secuencia" ON "public"."secuencias_variaciones" USING "btree" ("secuencia_id");



CREATE INDEX "idx_variaciones_tipo_id" ON "public"."secuencias_variaciones" USING "btree" ("tipo_variacion_id");



CREATE INDEX "idx_vocabularios_activo" ON "public"."vocabularios" USING "btree" ("activo");



CREATE INDEX "idx_vocabularios_categoria" ON "public"."vocabularios" USING "btree" ("categoria");



CREATE INDEX "idx_vocabularios_termino_padre" ON "public"."vocabularios" USING "btree" ("termino_padre_id");



CREATE INDEX "obras_revisores_obra_idx" ON "public"."obras_revisores" USING "btree" ("obra_id");



CREATE INDEX "obras_revisores_revisor_idx" ON "public"."obras_revisores" USING "btree" ("revisor_id");



CREATE OR REPLACE TRIGGER "trigger_actualizar_autoria" AFTER INSERT OR DELETE OR UPDATE ON "public"."rangos_autores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_autoria_obra"();



CREATE OR REPLACE TRIGGER "trigger_actualizar_autoria_por_cambio_autor" AFTER UPDATE OF "nombre_completo" ON "public"."autores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_autoria_obras_por_autor"();



CREATE OR REPLACE TRIGGER "trigger_autores_updated_at" BEFORE UPDATE ON "public"."autores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_dashboard_activity_state_updated_at" BEFORE UPDATE ON "public"."dashboard_activity_state" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_editores_updated_at" BEFORE UPDATE ON "public"."editores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_obras_enforce_public_visibility" BEFORE INSERT OR UPDATE ON "public"."obras" FOR EACH ROW EXECUTE FUNCTION "public"."obras_enforce_public_visibility"();



CREATE OR REPLACE TRIGGER "trigger_obras_sync_autor_ficha_publico" BEFORE INSERT OR UPDATE OF "editor_asignado" ON "public"."obras" FOR EACH ROW EXECUTE FUNCTION "public"."sync_obra_autor_ficha_publico"();



CREATE OR REPLACE TRIGGER "trigger_obras_updated_at" BEFORE UPDATE ON "public"."obras" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_rangos_updated_at" BEFORE UPDATE ON "public"."rangos" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_secuencias_updated_at" BEFORE UPDATE ON "public"."secuencias_metricas" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_validate_estrofa_tipo_metros_categories" BEFORE INSERT OR UPDATE ON "public"."estrofa_tipo_metros" FOR EACH ROW EXECUTE FUNCTION "public"."validate_estrofa_tipo_metros_categories"();



CREATE OR REPLACE TRIGGER "trigger_vocabularios_updated_at" BEFORE UPDATE ON "public"."vocabularios" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_cuadro_id_fkey" FOREIGN KEY ("cuadro_id") REFERENCES "public"."cuadros"("cuadro_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_jornada_id_fkey" FOREIGN KEY ("jornada_id") REFERENCES "public"."jornadas"("jornada_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_rango_id_fkey" FOREIGN KEY ("rango_id") REFERENCES "public"."rangos"("rango_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_secuencia_id_fkey" FOREIGN KEY ("secuencia_id") REFERENCES "public"."secuencias_metricas"("secuencia_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_tipo_comentario_id_fkey" FOREIGN KEY ("tipo_comentario_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."editores"("user_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "cuadros_certeza_editor_fkey" FOREIGN KEY ("certeza_editor") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "cuadros_jornada_id_fkey" FOREIGN KEY ("jornada_id") REFERENCES "public"."jornadas"("jornada_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dashboard_activity_state"
    ADD CONSTRAINT "dashboard_activity_state_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."editores"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_role_fkey" FOREIGN KEY ("role") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE NOT VALID;



ALTER TABLE ONLY "public"."estrofa_tipo_metros"
    ADD CONSTRAINT "estrofa_tipo_metros_estrofa_tipo_id_fkey" FOREIGN KEY ("estrofa_tipo_id") REFERENCES "public"."vocabularios"("termino_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."estrofa_tipo_metros"
    ADD CONSTRAINT "estrofa_tipo_metros_metro_id_fkey" FOREIGN KEY ("metro_id") REFERENCES "public"."vocabularios"("termino_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "fk_usuario" FOREIGN KEY ("user_id") REFERENCES "public"."editores"("user_id");



ALTER TABLE ONLY "public"."jornadas"
    ADD CONSTRAINT "jornadas_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obras"
    ADD CONSTRAINT "obras_editor_asignado_fkey" FOREIGN KEY ("editor_asignado") REFERENCES "public"."editores"("user_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."obras"
    ADD CONSTRAINT "obras_estado_fkey" FOREIGN KEY ("estado") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."obras"
    ADD CONSTRAINT "obras_genero_id_fkey" FOREIGN KEY ("genero_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."obras_revisores"
    ADD CONSTRAINT "obras_revisores_asignado_por_fkey" FOREIGN KEY ("asignado_por") REFERENCES "public"."editores"("user_id");



ALTER TABLE ONLY "public"."obras_revisores"
    ADD CONSTRAINT "obras_revisores_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obras_revisores"
    ADD CONSTRAINT "obras_revisores_revisor_id_fkey" FOREIGN KEY ("revisor_id") REFERENCES "public"."editores"("user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "public"."autores"("autor_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_rango_id_fkey" FOREIGN KEY ("rango_id") REFERENCES "public"."rangos"("rango_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_certeza_editor_fkey" FOREIGN KEY ("certeza_editor") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_estrofa_tipo_id_fkey" FOREIGN KEY ("estrofa_tipo_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_variaciones"
    ADD CONSTRAINT "secuencias_variaciones_secuencia_id_fkey" FOREIGN KEY ("secuencia_id") REFERENCES "public"."secuencias_metricas"("secuencia_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_variaciones"
    ADD CONSTRAINT "secuencias_variaciones_tipo_variacion_id_fkey" FOREIGN KEY ("tipo_variacion_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."vocabularios"
    ADD CONSTRAINT "vocabularios_termino_padre_id_fkey" FOREIGN KEY ("termino_padre_id") REFERENCES "public"."vocabularios"("termino_id") ON DELETE SET NULL;



CREATE POLICY "Permitir inserts keep-alive limitados" ON "public"."proyecto_activo" FOR INSERT TO "anon" WITH CHECK ((("status" = 'activo'::"text") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."proyecto_activo" "proyecto_activo_1"
  WHERE ("proyecto_activo_1"."timestamp" > ("now"() - '23:00:00'::interval)))))));



ALTER TABLE "public"."autores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "autores_delete_admin_ip" ON "public"."autores" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "autores_insert_admin_ip" ON "public"."autores" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "autores_select_authenticated_active" ON "public"."autores" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true)))));



CREATE POLICY "autores_update_admin_ip" ON "public"."autores" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "comentarios_delete_owner_or_admin" ON "public"."comentarios_internos" FOR DELETE TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])))))));



CREATE POLICY "comentarios_insert" ON "public"."comentarios_internos" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "comentarios_insert_assigned_reviewer" ON "public"."comentarios_internos" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."obras_revisores" "r"
  WHERE (("r"."obra_id" = "comentarios_internos"."obra_id") AND ("r"."revisor_id" = "auth"."uid"())))) AND ("user_id" = "auth"."uid"())));



ALTER TABLE "public"."comentarios_internos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comentarios_select" ON "public"."comentarios_internos" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "comentarios_select_assigned_reviewer" ON "public"."comentarios_internos" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."obras_revisores" "r"
  WHERE (("r"."obra_id" = "comentarios_internos"."obra_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "comentarios_update_owner_or_admin" ON "public"."comentarios_internos" FOR UPDATE TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))))) WITH CHECK ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])))))));



ALTER TABLE "public"."cuadros" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cuadros_delete_authenticated" ON "public"."cuadros" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."jornadas" "j"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "j"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "cuadros_insert_authenticated" ON "public"."cuadros" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."jornadas" "j"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "j"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "cuadros_select_assigned_reviewer" ON "public"."cuadros" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."jornadas" "j"
     JOIN "public"."obras_revisores" "r" ON (("r"."obra_id" = "j"."obra_id")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "cuadros_select_authenticated" ON "public"."cuadros" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."jornadas" "j"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "j"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "cuadros_update_authenticated" ON "public"."cuadros" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."jornadas" "j"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "j"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."jornadas" "j"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "j"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("j"."jornada_id" = "cuadros"."jornada_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."dashboard_activity_state" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "dashboard_activity_state_delete_self" ON "public"."dashboard_activity_state" FOR DELETE TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true))))));



CREATE POLICY "dashboard_activity_state_insert_self" ON "public"."dashboard_activity_state" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true))))));



CREATE POLICY "dashboard_activity_state_select_self" ON "public"."dashboard_activity_state" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true))))));



CREATE POLICY "dashboard_activity_state_update_self" ON "public"."dashboard_activity_state" FOR UPDATE TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true)))))) WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true))))));



ALTER TABLE "public"."editores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "editores_select_active_authenticated" ON "public"."editores" FOR SELECT TO "authenticated" USING (COALESCE("activo", true));



CREATE POLICY "editores_select_self" ON "public"."editores" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND COALESCE("activo", true)));



ALTER TABLE "public"."estrofa_tipo_metros" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "estrofa_tipo_metros_delete_admin_ip" ON "public"."estrofa_tipo_metros" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "estrofa_tipo_metros_insert_admin_ip" ON "public"."estrofa_tipo_metros" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "estrofa_tipo_metros_select" ON "public"."estrofa_tipo_metros" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "estrofa_tipo_metros_update_admin_ip" ON "public"."estrofa_tipo_metros" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



ALTER TABLE "public"."jornadas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "jornadas_delete_authenticated" ON "public"."jornadas" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "jornadas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "jornadas_insert_authenticated" ON "public"."jornadas" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "jornadas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "jornadas_select_assigned_reviewer" ON "public"."jornadas" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."obras_revisores" "r"
  WHERE (("r"."obra_id" = "jornadas"."obra_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "jornadas_select_authenticated" ON "public"."jornadas" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "jornadas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "jornadas_update_authenticated" ON "public"."jornadas" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "jornadas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "jornadas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."obras" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "obras_authenticated_select" ON "public"."obras" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "obras_delete_authenticated" ON "public"."obras" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "obras_insert_authenticated" ON "public"."obras" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "obras_publicas_select" ON "public"."obras" FOR SELECT TO "anon" USING ((("visible_publico" = true) AND (EXISTS ( SELECT 1
   FROM "public"."vocabularios" "v"
  WHERE (("v"."termino_id" = "obras"."estado") AND (("v"."categoria")::"text" = 'estado'::"text") AND ("lower"(("v"."termino")::"text") = 'publicado'::"text"))))));



ALTER TABLE "public"."obras_revisores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "obras_revisores_delete" ON "public"."obras_revisores" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "obras_revisores_insert" ON "public"."obras_revisores" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "obras_revisores_select" ON "public"."obras_revisores" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true)))));



CREATE POLICY "obras_revisores_update" ON "public"."obras_revisores" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND ("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"]))))));



CREATE POLICY "obras_select_authenticated_active" ON "public"."obras" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true)))));



CREATE POLICY "obras_update_authenticated" ON "public"."obras" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("obras"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."editores" "e"
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("e"."user_id" = "auth"."uid"()) AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("obras"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."proyecto_activo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rangos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rangos_autores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "rangos_autores_delete_authenticated" ON "public"."rangos_autores" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."rangos" "r"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "r"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("r"."rango_id" = "rangos_autores"."rango_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_autores_insert_authenticated" ON "public"."rangos_autores" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."rangos" "r"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "r"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("r"."rango_id" = "rangos_autores"."rango_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_autores_select_assigned_reviewer" ON "public"."rangos_autores" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."rangos" "ra"
     JOIN "public"."obras_revisores" "r" ON (("r"."obra_id" = "ra"."obra_id")))
  WHERE (("ra"."rango_id" = "rangos_autores"."rango_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "rangos_autores_select_authenticated" ON "public"."rangos_autores" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."rangos" "r"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "r"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("r"."rango_id" = "rangos_autores"."rango_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_autores_update_authenticated" ON "public"."rangos_autores" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."rangos" "r"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "r"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("r"."rango_id" = "rangos_autores"."rango_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."rangos" "r"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "r"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("r"."rango_id" = "rangos_autores"."rango_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_delete_authenticated" ON "public"."rangos" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "rangos"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_insert_authenticated" ON "public"."rangos" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "rangos"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_select_assigned_reviewer" ON "public"."rangos" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."obras_revisores" "r"
  WHERE (("r"."obra_id" = "rangos"."obra_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "rangos_select_authenticated" ON "public"."rangos" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "rangos"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "rangos_update_authenticated" ON "public"."rangos" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "rangos"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "rangos"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_delete_authenticated" ON "public"."secuencias_metricas" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "secuencias_metricas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_insert_authenticated" ON "public"."secuencias_metricas" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "secuencias_metricas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."secuencias_metricas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "secuencias_select_assigned_reviewer" ON "public"."secuencias_metricas" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."obras_revisores" "r"
  WHERE (("r"."obra_id" = "secuencias_metricas"."obra_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "secuencias_select_authenticated" ON "public"."secuencias_metricas" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "secuencias_metricas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_update_authenticated" ON "public"."secuencias_metricas" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "secuencias_metricas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."obras" "o"
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("o"."obra_id" = "secuencias_metricas"."obra_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."secuencias_variaciones" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "secuencias_variaciones_delete_authenticated" ON "public"."secuencias_variaciones" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."secuencias_metricas" "sm"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "sm"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_variaciones_insert_authenticated" ON "public"."secuencias_variaciones" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."secuencias_metricas" "sm"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "sm"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_variaciones_select_assigned_reviewer" ON "public"."secuencias_variaciones" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."secuencias_metricas" "sm"
     JOIN "public"."obras_revisores" "r" ON (("r"."obra_id" = "sm"."obra_id")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND ("r"."revisor_id" = "auth"."uid"())))));



CREATE POLICY "secuencias_variaciones_select_authenticated" ON "public"."secuencias_variaciones" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."secuencias_metricas" "sm"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "sm"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text", 'revisor'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



CREATE POLICY "secuencias_variaciones_update_authenticated" ON "public"."secuencias_variaciones" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."secuencias_metricas" "sm"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "sm"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ((("public"."secuencias_metricas" "sm"
     JOIN "public"."obras" "o" ON (("o"."obra_id" = "sm"."obra_id")))
     JOIN "public"."editores" "e" ON (("e"."user_id" = "auth"."uid"())))
     JOIN "public"."vocabularios" "vr" ON (("vr"."termino_id" = "e"."role")))
  WHERE (("sm"."secuencia_id" = "secuencias_variaciones"."secuencia_id") AND COALESCE("e"."activo", true) AND (("lower"(("vr"."termino")::"text") = ANY (ARRAY['admin'::"text", 'ip'::"text"])) OR (("lower"(("vr"."termino")::"text") = 'editor'::"text") AND ("o"."editor_asignado" = "e"."user_id")))))));



ALTER TABLE "public"."vocabularios" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vocabularios_delete_admin_ip" ON "public"."vocabularios" FOR DELETE TO "authenticated" USING ("public"."auth_is_admin_or_ip"());



CREATE POLICY "vocabularios_insert_admin_ip" ON "public"."vocabularios" FOR INSERT TO "authenticated" WITH CHECK ("public"."auth_is_admin_or_ip"());



CREATE POLICY "vocabularios_public_select" ON "public"."vocabularios" FOR SELECT TO "authenticated", "anon" USING (("activo" = true));



CREATE POLICY "vocabularios_select_admin_ip" ON "public"."vocabularios" FOR SELECT TO "authenticated" USING ("public"."auth_is_admin_or_ip"());



CREATE POLICY "vocabularios_update_admin_ip" ON "public"."vocabularios" FOR UPDATE TO "authenticated" USING ("public"."auth_is_admin_or_ip"()) WITH CHECK ("public"."auth_is_admin_or_ip"());



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "service_role";



GRANT ALL ON FUNCTION "public"."actualizar_autoria_obras_por_autor"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obras_por_autor"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obras_por_autor"() TO "service_role";



GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."auth_is_admin_or_ip"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."auth_is_admin_or_ip"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_is_admin_or_ip"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_is_admin_or_ip"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_obra_ficha_publica"("p_obra_id" "uuid", "p_include_hidden" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."get_obra_ficha_publica"("p_obra_id" "uuid", "p_include_hidden" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_obra_ficha_publica"("p_obra_id" "uuid", "p_include_hidden" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."obras_enforce_public_visibility"() TO "anon";
GRANT ALL ON FUNCTION "public"."obras_enforce_public_visibility"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."obras_enforce_public_visibility"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_obra_autor_ficha_publico"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_obra_autor_ficha_publico"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_obra_autor_ficha_publico"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_estrofa_tipo_metros_categories"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_estrofa_tipo_metros_categories"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_estrofa_tipo_metros_categories"() TO "service_role";



GRANT ALL ON TABLE "public"."autores" TO "anon";
GRANT ALL ON TABLE "public"."autores" TO "authenticated";
GRANT ALL ON TABLE "public"."autores" TO "service_role";



GRANT ALL ON TABLE "public"."comentarios_internos" TO "anon";
GRANT ALL ON TABLE "public"."comentarios_internos" TO "authenticated";
GRANT ALL ON TABLE "public"."comentarios_internos" TO "service_role";



GRANT ALL ON TABLE "public"."cuadros" TO "anon";
GRANT ALL ON TABLE "public"."cuadros" TO "authenticated";
GRANT ALL ON TABLE "public"."cuadros" TO "service_role";



GRANT ALL ON TABLE "public"."dashboard_activity_state" TO "anon";
GRANT ALL ON TABLE "public"."dashboard_activity_state" TO "authenticated";
GRANT ALL ON TABLE "public"."dashboard_activity_state" TO "service_role";



GRANT ALL ON TABLE "public"."editores" TO "anon";
GRANT ALL ON TABLE "public"."editores" TO "authenticated";
GRANT ALL ON TABLE "public"."editores" TO "service_role";



GRANT ALL ON TABLE "public"."estrofa_tipo_metros" TO "anon";
GRANT ALL ON TABLE "public"."estrofa_tipo_metros" TO "authenticated";
GRANT ALL ON TABLE "public"."estrofa_tipo_metros" TO "service_role";



GRANT ALL ON TABLE "public"."jornadas" TO "anon";
GRANT ALL ON TABLE "public"."jornadas" TO "authenticated";
GRANT ALL ON TABLE "public"."jornadas" TO "service_role";



GRANT ALL ON TABLE "public"."obras" TO "anon";
GRANT ALL ON TABLE "public"."obras" TO "authenticated";
GRANT ALL ON TABLE "public"."obras" TO "service_role";



GRANT ALL ON TABLE "public"."obras_revisores" TO "anon";
GRANT ALL ON TABLE "public"."obras_revisores" TO "authenticated";
GRANT ALL ON TABLE "public"."obras_revisores" TO "service_role";



GRANT ALL ON TABLE "public"."proyecto_activo" TO "anon";
GRANT ALL ON TABLE "public"."proyecto_activo" TO "authenticated";
GRANT ALL ON TABLE "public"."proyecto_activo" TO "service_role";



GRANT ALL ON SEQUENCE "public"."proyecto_activo_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."proyecto_activo_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."proyecto_activo_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."rangos" TO "anon";
GRANT ALL ON TABLE "public"."rangos" TO "authenticated";
GRANT ALL ON TABLE "public"."rangos" TO "service_role";



GRANT ALL ON TABLE "public"."rangos_autores" TO "anon";
GRANT ALL ON TABLE "public"."rangos_autores" TO "authenticated";
GRANT ALL ON TABLE "public"."rangos_autores" TO "service_role";



GRANT ALL ON TABLE "public"."secuencias_metricas" TO "anon";
GRANT ALL ON TABLE "public"."secuencias_metricas" TO "authenticated";
GRANT ALL ON TABLE "public"."secuencias_metricas" TO "service_role";



GRANT ALL ON TABLE "public"."secuencias_variaciones" TO "anon";
GRANT ALL ON TABLE "public"."secuencias_variaciones" TO "authenticated";
GRANT ALL ON TABLE "public"."secuencias_variaciones" TO "service_role";



GRANT ALL ON TABLE "public"."vocabularios" TO "anon";
GRANT ALL ON TABLE "public"."vocabularios" TO "authenticated";
GRANT ALL ON TABLE "public"."vocabularios" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







