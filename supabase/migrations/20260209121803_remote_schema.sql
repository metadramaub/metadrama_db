


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


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."actualizar_autoria_obra"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_obra_id UUID;
BEGIN
  -- Obtener obra_id desde el rango
  SELECT obra_id INTO v_obra_id
  FROM rangos
  WHERE rango_id = COALESCE(NEW.rango_id, OLD.rango_id);
  
  -- Actualizar campo autoria en obras
  UPDATE obras
  SET autoria = (
    SELECT array_agg(DISTINCT a.nombre_completo ORDER BY a.nombre_completo)
    FROM rangos r
    JOIN rangos_autores ra ON ra.rango_id = r.rango_id
    JOIN autores a ON a.autor_id = ra.autor_id
    WHERE r.obra_id = v_obra_id
  )
  WHERE obra_id = v_obra_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."actualizar_autoria_obra"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."actualizar_autoria_obra"() IS 'Actualiza automáticamente el campo obras.autoria cuando cambian los autores en rangos_autores';



CREATE OR REPLACE FUNCTION "public"."actualizar_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."actualizar_updated_at"() OWNER TO "postgres";

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
    "created_at" timestamp with time zone DEFAULT "now"()
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
    "analisis_editor" "text",
    "genero_id" "uuid",
    "total_versos" integer,
    "bibliografia" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."obras" OWNER TO "postgres";


COMMENT ON COLUMN "public"."obras"."autoria" IS 'Array calculado de nombres de autores. Se genera automáticamente desde rangos_autores';



COMMENT ON COLUMN "public"."obras"."analisis_editor" IS 'Análisis público del editor. Texto largo con formato rico (markdown). Visible en web pública';



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
    "estado_revision" "uuid" NOT NULL,
    "certeza_editor" "uuid" NOT NULL,
    "observaciones" "text",
    "notas_internas" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."secuencias_metricas" OWNER TO "postgres";


COMMENT ON TABLE "public"."secuencias_metricas" IS 'Unidad de análisis métrico. Autoría se consulta desde rangos/rangos_autores por overlap de versos';



CREATE TABLE IF NOT EXISTS "public"."secuencias_metros" (
    "secuencia_id" "uuid" NOT NULL,
    "metro_id" "uuid" NOT NULL
);


ALTER TABLE "public"."secuencias_metros" OWNER TO "postgres";


COMMENT ON TABLE "public"."secuencias_metros" IS '1 fila = metro único. 2+ filas = combinación (ej: heptasílabos + endecasílabos en silva)';



CREATE TABLE IF NOT EXISTS "public"."secuencias_variaciones" (
    "variacion_id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "secuencia_id" "uuid" NOT NULL,
    "tipo_variacion" character varying(20) NOT NULL,
    "v_ini" integer NOT NULL,
    "v_fin" integer NOT NULL,
    "observaciones" "text"
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
    "updated_at" timestamp with time zone DEFAULT "now"()
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



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."jornadas"
    ADD CONSTRAINT "jornadas_pkey" PRIMARY KEY ("jornada_id");



ALTER TABLE ONLY "public"."obras"
    ADD CONSTRAINT "obras_pkey" PRIMARY KEY ("obra_id");



ALTER TABLE ONLY "public"."proyecto_activo"
    ADD CONSTRAINT "proyecto_activo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_pkey" PRIMARY KEY ("rango_id", "autor_id");



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_pkey" PRIMARY KEY ("rango_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_pkey" PRIMARY KEY ("secuencia_id");



ALTER TABLE ONLY "public"."secuencias_metros"
    ADD CONSTRAINT "secuencias_metros_pkey" PRIMARY KEY ("secuencia_id", "metro_id");



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



CREATE INDEX "idx_autores_nombre_normalizado" ON "public"."autores" USING "btree" ("nombre_normalizado");



CREATE INDEX "idx_comentarios_obra" ON "public"."comentarios_internos" USING "btree" ("obra_id");



CREATE INDEX "idx_comentarios_user" ON "public"."comentarios_internos" USING "btree" ("user_id");



CREATE INDEX "idx_cuadros_jornada" ON "public"."cuadros" USING "btree" ("jornada_id");



CREATE INDEX "idx_editores_activo" ON "public"."editores" USING "btree" ("activo");



CREATE INDEX "idx_editores_email" ON "public"."editores" USING "btree" ("email");



CREATE INDEX "idx_editores_role" ON "public"."editores" USING "btree" ("role");



CREATE INDEX "idx_jornadas_obra" ON "public"."jornadas" USING "btree" ("obra_id");



CREATE INDEX "idx_obras_editor_asignado" ON "public"."obras" USING "btree" ("editor_asignado");



CREATE INDEX "idx_obras_estado" ON "public"."obras" USING "btree" ("estado");



CREATE INDEX "idx_obras_titulo_normalizado" ON "public"."obras" USING "btree" ("titulo_normalizado");



CREATE INDEX "idx_obras_visible_publico" ON "public"."obras" USING "btree" ("visible_publico");



CREATE INDEX "idx_rangos_autores_autor" ON "public"."rangos_autores" USING "btree" ("autor_id");



CREATE INDEX "idx_rangos_autores_rango" ON "public"."rangos_autores" USING "btree" ("rango_id");



CREATE INDEX "idx_rangos_obra" ON "public"."rangos" USING "btree" ("obra_id");



CREATE INDEX "idx_rangos_versos" ON "public"."rangos" USING "btree" ("obra_id", "v_ini", "v_fin");



CREATE INDEX "idx_secuencias_estado" ON "public"."secuencias_metricas" USING "btree" ("estado_revision");



CREATE INDEX "idx_secuencias_estrofa" ON "public"."secuencias_metricas" USING "btree" ("estrofa_tipo_id");



CREATE INDEX "idx_secuencias_metros_metro" ON "public"."secuencias_metros" USING "btree" ("metro_id");



CREATE INDEX "idx_secuencias_metros_secuencia" ON "public"."secuencias_metros" USING "btree" ("secuencia_id");



CREATE INDEX "idx_secuencias_obra" ON "public"."secuencias_metricas" USING "btree" ("obra_id");



CREATE INDEX "idx_secuencias_v_ini" ON "public"."secuencias_metricas" USING "btree" ("v_ini");



CREATE INDEX "idx_variaciones_secuencia" ON "public"."secuencias_variaciones" USING "btree" ("secuencia_id");



CREATE INDEX "idx_variaciones_tipo" ON "public"."secuencias_variaciones" USING "btree" ("tipo_variacion");



CREATE INDEX "idx_vocabularios_activo" ON "public"."vocabularios" USING "btree" ("activo");



CREATE INDEX "idx_vocabularios_categoria" ON "public"."vocabularios" USING "btree" ("categoria");



CREATE INDEX "idx_vocabularios_termino_padre" ON "public"."vocabularios" USING "btree" ("termino_padre_id");



CREATE OR REPLACE TRIGGER "trigger_actualizar_autoria" AFTER INSERT OR DELETE OR UPDATE ON "public"."rangos_autores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_autoria_obra"();



CREATE OR REPLACE TRIGGER "trigger_autores_updated_at" BEFORE UPDATE ON "public"."autores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_editores_updated_at" BEFORE UPDATE ON "public"."editores" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_obras_updated_at" BEFORE UPDATE ON "public"."obras" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_rangos_updated_at" BEFORE UPDATE ON "public"."rangos" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_secuencias_updated_at" BEFORE UPDATE ON "public"."secuencias_metricas" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_vocabularios_updated_at" BEFORE UPDATE ON "public"."vocabularios" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_updated_at"();



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "comentarios_internos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."editores"("user_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "cuadros_certeza_editor_fkey" FOREIGN KEY ("certeza_editor") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."cuadros"
    ADD CONSTRAINT "cuadros_jornada_id_fkey" FOREIGN KEY ("jornada_id") REFERENCES "public"."jornadas"("jornada_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_role_fkey" FOREIGN KEY ("role") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."editores"
    ADD CONSTRAINT "editores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE NOT VALID;



ALTER TABLE ONLY "public"."comentarios_internos"
    ADD CONSTRAINT "fk_obra" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id");



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



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "public"."autores"("autor_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rangos_autores"
    ADD CONSTRAINT "rangos_autores_rango_id_fkey" FOREIGN KEY ("rango_id") REFERENCES "public"."rangos"("rango_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_certeza_editor_fkey" FOREIGN KEY ("certeza_editor") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_estado_revision_fkey" FOREIGN KEY ("estado_revision") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_estrofa_tipo_id_fkey" FOREIGN KEY ("estrofa_tipo_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metricas"
    ADD CONSTRAINT "secuencias_metricas_obra_id_fkey" FOREIGN KEY ("obra_id") REFERENCES "public"."obras"("obra_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_metros"
    ADD CONSTRAINT "secuencias_metros_metro_id_fkey" FOREIGN KEY ("metro_id") REFERENCES "public"."vocabularios"("termino_id");



ALTER TABLE ONLY "public"."secuencias_metros"
    ADD CONSTRAINT "secuencias_metros_secuencia_id_fkey" FOREIGN KEY ("secuencia_id") REFERENCES "public"."secuencias_metricas"("secuencia_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secuencias_variaciones"
    ADD CONSTRAINT "secuencias_variaciones_secuencia_id_fkey" FOREIGN KEY ("secuencia_id") REFERENCES "public"."secuencias_metricas"("secuencia_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vocabularios"
    ADD CONSTRAINT "vocabularios_termino_padre_id_fkey" FOREIGN KEY ("termino_padre_id") REFERENCES "public"."vocabularios"("termino_id") ON DELETE SET NULL;



CREATE POLICY "Permitir inserts keep-alive limitados" ON "public"."proyecto_activo" FOR INSERT TO "anon" WITH CHECK ((("status" = 'activo'::"text") AND (NOT (EXISTS ( SELECT 1
   FROM "public"."proyecto_activo" "proyecto_activo_1"
  WHERE ("proyecto_activo_1"."timestamp" > ("now"() - '23:00:00'::interval)))))));



CREATE POLICY "admin_all_access" ON "public"."editores" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."editores" "e"
  WHERE (("e"."user_id" = "auth"."uid"()) AND ("e"."activo" = true)))));



ALTER TABLE "public"."autores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comentarios_insert" ON "public"."comentarios_internos" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."comentarios_internos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comentarios_select" ON "public"."comentarios_internos" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."cuadros" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."editores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."jornadas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obras" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "obras_authenticated_select" ON "public"."obras" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "obras_publicas_select" ON "public"."obras" FOR SELECT TO "anon" USING (("visible_publico" = true));



ALTER TABLE "public"."proyecto_activo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rangos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rangos_autores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."secuencias_metricas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."secuencias_metros" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."secuencias_variaciones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vocabularios" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vocabularios_public_select" ON "public"."vocabularios" FOR SELECT TO "authenticated", "anon" USING (("activo" = true));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_autoria_obra"() TO "service_role";



GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_updated_at"() TO "service_role";
























GRANT ALL ON TABLE "public"."autores" TO "anon";
GRANT ALL ON TABLE "public"."autores" TO "authenticated";
GRANT ALL ON TABLE "public"."autores" TO "service_role";



GRANT ALL ON TABLE "public"."comentarios_internos" TO "anon";
GRANT ALL ON TABLE "public"."comentarios_internos" TO "authenticated";
GRANT ALL ON TABLE "public"."comentarios_internos" TO "service_role";



GRANT ALL ON TABLE "public"."cuadros" TO "anon";
GRANT ALL ON TABLE "public"."cuadros" TO "authenticated";
GRANT ALL ON TABLE "public"."cuadros" TO "service_role";



GRANT ALL ON TABLE "public"."editores" TO "anon";
GRANT ALL ON TABLE "public"."editores" TO "authenticated";
GRANT ALL ON TABLE "public"."editores" TO "service_role";



GRANT ALL ON TABLE "public"."jornadas" TO "anon";
GRANT ALL ON TABLE "public"."jornadas" TO "authenticated";
GRANT ALL ON TABLE "public"."jornadas" TO "service_role";



GRANT ALL ON TABLE "public"."obras" TO "anon";
GRANT ALL ON TABLE "public"."obras" TO "authenticated";
GRANT ALL ON TABLE "public"."obras" TO "service_role";



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



GRANT ALL ON TABLE "public"."secuencias_metros" TO "anon";
GRANT ALL ON TABLE "public"."secuencias_metros" TO "authenticated";
GRANT ALL ON TABLE "public"."secuencias_metros" TO "service_role";



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































