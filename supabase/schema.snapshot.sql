-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.proyecto_activo (
  id integer NOT NULL DEFAULT nextval('proyecto_activo_id_seq'::regclass),
  timestamp timestamp without time zone DEFAULT now(),
  status text DEFAULT 'activo'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT proyecto_activo_pkey PRIMARY KEY (id)
);
CREATE TABLE public.vocabularios (
  termino_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  categoria character varying NOT NULL,
  termino character varying NOT NULL,
  termino_padre_id uuid,
  nivel integer,
  patron_especifico character varying,
  definicion text,
  ejemplo text,
  equivalencias ARRAY,
  orden integer,
  activo boolean DEFAULT true,
  bibliografia text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  tipo_forma text CHECK (tipo_forma IS NULL OR (tipo_forma = ANY (ARRAY['forma_espanola'::text, 'forma_italiana'::text]))),
  CONSTRAINT vocabularios_pkey PRIMARY KEY (termino_id),
  CONSTRAINT vocabularios_termino_padre_id_fkey FOREIGN KEY (termino_padre_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.editores (
  user_id uuid NOT NULL,
  nombre_completo character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  role uuid NOT NULL,
  activo boolean DEFAULT true,
  institucion character varying,
  orcid character varying,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  last_login timestamp with time zone,
  CONSTRAINT editores_pkey PRIMARY KEY (user_id),
  CONSTRAINT editores_role_fkey FOREIGN KEY (role) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT editores_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.autores (
  autor_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  nombre_completo character varying NOT NULL,
  nombre_normalizado character varying,
  variantes_nombre ARRAY,
  bnedatos_id character varying,
  viaf_id character varying,
  wikidata_id character varying,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT autores_pkey PRIMARY KEY (autor_id)
);
CREATE TABLE public.obras (
  obra_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  titulo text NOT NULL,
  titulo_normalizado text,
  variantes_titulo ARRAY,
  fecha_inicio_trad integer,
  fecha_fin_trad integer,
  fuente_fecha text,
  fecha_inicio_metadrama integer,
  fecha_fin_metadrama integer,
  edicion text,
  editor_asignado uuid,
  fecha_asignacion timestamp with time zone,
  estado uuid NOT NULL,
  visible_publico boolean DEFAULT false,
  fecha_cambio_estado timestamp with time zone,
  observaciones text,
  genero_id uuid,
  total_versos integer,
  bibliografia text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  autor_ficha_publico text,
  CONSTRAINT obras_pkey PRIMARY KEY (obra_id),
  CONSTRAINT obras_editor_asignado_fkey FOREIGN KEY (editor_asignado) REFERENCES public.editores(user_id),
  CONSTRAINT obras_estado_fkey FOREIGN KEY (estado) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT obras_genero_id_fkey FOREIGN KEY (genero_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.jornadas (
  jornada_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  obra_id uuid NOT NULL,
  jornada_num integer NOT NULL,
  v_ini integer NOT NULL,
  v_fin integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT jornadas_pkey PRIMARY KEY (jornada_id),
  CONSTRAINT jornadas_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id)
);
CREATE TABLE public.cuadros (
  cuadro_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  jornada_id uuid NOT NULL,
  cuadro_num integer NOT NULL,
  v_ini integer NOT NULL,
  v_fin integer NOT NULL,
  certeza_editor uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT cuadros_pkey PRIMARY KEY (cuadro_id),
  CONSTRAINT cuadros_jornada_id_fkey FOREIGN KEY (jornada_id) REFERENCES public.jornadas(jornada_id),
  CONSTRAINT cuadros_certeza_editor_fkey FOREIGN KEY (certeza_editor) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.secuencias_metricas (
  secuencia_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  obra_id uuid NOT NULL,
  v_ini integer NOT NULL,
  v_fin integer NOT NULL,
  n_versos integer NOT NULL,
  estrofa_tipo_id uuid,
  inaugura_espacio boolean DEFAULT false,
  intervencion_personajes_femeninos character varying NOT NULL DEFAULT 'sin_intervencion'::character varying CHECK (intervencion_personajes_femeninos::text = ANY (ARRAY['sin_intervencion'::character varying, 'exclusiva'::character varying, 'compartida'::character varying]::text[])),
  intervencion_figuras_donaire character varying NOT NULL DEFAULT 'sin_intervencion'::character varying CHECK (intervencion_figuras_donaire::text = ANY (ARRAY['sin_intervencion'::character varying, 'exclusiva'::character varying, 'compartida'::character varying]::text[])),
  intervencion_personajes_sobrenaturales character varying NOT NULL DEFAULT 'sin_intervencion'::character varying CHECK (intervencion_personajes_sobrenaturales::text = ANY (ARRAY['sin_intervencion'::character varying, 'exclusiva'::character varying, 'compartida'::character varying]::text[])),
  certeza_editor uuid NOT NULL,
  sinopsis text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  versos_partidos boolean NOT NULL DEFAULT false,
  evocacion_metrica boolean NOT NULL DEFAULT false,
  evocacion_metrica_texto text,
  CONSTRAINT secuencias_metricas_pkey PRIMARY KEY (secuencia_id),
  CONSTRAINT secuencias_metricas_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id),
  CONSTRAINT secuencias_metricas_estrofa_tipo_id_fkey FOREIGN KEY (estrofa_tipo_id) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT secuencias_metricas_certeza_editor_fkey FOREIGN KEY (certeza_editor) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.secuencias_caracterizaciones_rango (
  caracterizacion_rango_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  secuencia_id uuid NOT NULL,
  v_ini integer NOT NULL,
  v_fin integer NOT NULL,
  observaciones text,
  tipo_caracterizacion_rango_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT secuencias_caracterizaciones_rango_pkey PRIMARY KEY (caracterizacion_rango_id),
  CONSTRAINT secuencias_caracterizaciones_rango_secuencia_id_fkey FOREIGN KEY (secuencia_id) REFERENCES public.secuencias_metricas(secuencia_id),
  CONSTRAINT secuencias_caracterizaciones_rango_tipo_caracterizacion_rango_i FOREIGN KEY (tipo_caracterizacion_rango_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.comentarios_internos (
  comentario_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  obra_id uuid NOT NULL,
  user_id uuid NOT NULL,
  comentario text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  tipo_comentario_id uuid NOT NULL,
  secuencia_id uuid,
  jornada_id uuid,
  cuadro_id uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  seccion text CHECK (seccion IS NULL OR (seccion = ANY (ARRAY['datos'::text, 'estructura'::text, 'secuencias'::text, 'autoria'::text, 'observaciones'::text, 'revision'::text]))),
  visible_publico boolean NOT NULL DEFAULT false,
  publicado_por uuid,
  publicado_at timestamp with time zone,
  CONSTRAINT comentarios_internos_pkey PRIMARY KEY (comentario_id),
  CONSTRAINT comentarios_internos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.editores(user_id),
  CONSTRAINT fk_usuario FOREIGN KEY (user_id) REFERENCES public.editores(user_id),
  CONSTRAINT comentarios_internos_tipo_comentario_id_fkey FOREIGN KEY (tipo_comentario_id) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT comentarios_internos_secuencia_id_fkey FOREIGN KEY (secuencia_id) REFERENCES public.secuencias_metricas(secuencia_id),
  CONSTRAINT comentarios_internos_jornada_id_fkey FOREIGN KEY (jornada_id) REFERENCES public.jornadas(jornada_id),
  CONSTRAINT comentarios_internos_cuadro_id_fkey FOREIGN KEY (cuadro_id) REFERENCES public.cuadros(cuadro_id),
  CONSTRAINT comentarios_internos_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id),
  CONSTRAINT comentarios_internos_publicado_por_fkey FOREIGN KEY (publicado_por) REFERENCES public.editores(user_id)
);
CREATE TABLE public.obras_revisores (
  obra_id uuid NOT NULL,
  revisor_id uuid NOT NULL,
  asignado_por uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT obras_revisores_pkey PRIMARY KEY (obra_id, revisor_id),
  CONSTRAINT obras_revisores_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id),
  CONSTRAINT obras_revisores_revisor_id_fkey FOREIGN KEY (revisor_id) REFERENCES public.editores(user_id),
  CONSTRAINT obras_revisores_asignado_por_fkey FOREIGN KEY (asignado_por) REFERENCES public.editores(user_id)
);
CREATE TABLE public.dashboard_activity_state (
  user_id uuid NOT NULL,
  last_seen_at timestamp with time zone,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT dashboard_activity_state_pkey PRIMARY KEY (user_id),
  CONSTRAINT dashboard_activity_state_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.editores(user_id)
);
CREATE TABLE public.estrofa_tipo_metros (
  estrofa_tipo_id uuid NOT NULL,
  metro_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT estrofa_tipo_metros_pkey PRIMARY KEY (estrofa_tipo_id, metro_id),
  CONSTRAINT estrofa_tipo_metros_estrofa_tipo_id_fkey FOREIGN KEY (estrofa_tipo_id) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT estrofa_tipo_metros_metro_id_fkey FOREIGN KEY (metro_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.secuencias_subtipos_estrofa (
  subtipo_secuencia_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  secuencia_id uuid NOT NULL,
  subtipo_estrofa_id uuid NOT NULL,
  v_ini integer NOT NULL,
  v_fin integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT secuencias_subtipos_estrofa_pkey PRIMARY KEY (subtipo_secuencia_id),
  CONSTRAINT secuencias_subtipos_estrofa_secuencia_id_fkey FOREIGN KEY (secuencia_id) REFERENCES public.secuencias_metricas(secuencia_id),
  CONSTRAINT secuencias_subtipos_estrofa_subtipo_estrofa_id_fkey FOREIGN KEY (subtipo_estrofa_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.atribuciones (
  atribucion_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  obra_id uuid,
  jornada_id uuid,
  tipo_atribucion_id uuid NOT NULL,
  modalidad_atribucion_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  fuente_autoria text,
  grupo_atribucion_id uuid,
  composicion_autoria_id uuid,
  perfil_metrico boolean NOT NULL DEFAULT false,
  CONSTRAINT atribuciones_pkey PRIMARY KEY (atribucion_id),
  CONSTRAINT atribuciones_grupo_atribucion_id_fkey FOREIGN KEY (grupo_atribucion_id) REFERENCES public.grupos_atribucion(grupo_atribucion_id),
  CONSTRAINT atribuciones_composicion_autoria_id_fkey FOREIGN KEY (composicion_autoria_id) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT atribuciones_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id),
  CONSTRAINT atribuciones_jornada_id_fkey FOREIGN KEY (jornada_id) REFERENCES public.jornadas(jornada_id),
  CONSTRAINT atribuciones_tipo_atribucion_id_fkey FOREIGN KEY (tipo_atribucion_id) REFERENCES public.vocabularios(termino_id),
  CONSTRAINT atribuciones_modalidad_atribucion_id_fkey FOREIGN KEY (modalidad_atribucion_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.atribucion_autores (
  atribucion_id uuid NOT NULL,
  autor_id uuid NOT NULL,
  orden integer,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT atribucion_autores_pkey PRIMARY KEY (atribucion_id, autor_id),
  CONSTRAINT atribucion_autores_atribucion_id_fkey FOREIGN KEY (atribucion_id) REFERENCES public.atribuciones(atribucion_id),
  CONSTRAINT atribucion_autores_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.autores(autor_id)
);
CREATE TABLE public.grupos_atribucion (
  grupo_atribucion_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  obra_id uuid,
  jornada_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT grupos_atribucion_pkey PRIMARY KEY (grupo_atribucion_id),
  CONSTRAINT grupos_atribucion_obra_id_fkey FOREIGN KEY (obra_id) REFERENCES public.obras(obra_id),
  CONSTRAINT grupos_atribucion_jornada_id_fkey FOREIGN KEY (jornada_id) REFERENCES public.jornadas(jornada_id)
);
CREATE TABLE public.atribucion_evidencias (
  atribucion_evidencia_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  atribucion_id uuid NOT NULL,
  tipo_atribucion_id uuid NOT NULL,
  fuente_autoria text,
  orden integer,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT atribucion_evidencias_pkey PRIMARY KEY (atribucion_evidencia_id),
  CONSTRAINT atribucion_evidencias_atribucion_id_fkey FOREIGN KEY (atribucion_id) REFERENCES public.atribuciones(atribucion_id),
  CONSTRAINT atribucion_evidencias_tipo_atribucion_id_fkey FOREIGN KEY (tipo_atribucion_id) REFERENCES public.vocabularios(termino_id)
);
CREATE TABLE public.secciones_publicas (
  seccion_id text NOT NULL,
  label text NOT NULL,
  descripcion text,
  activa boolean NOT NULL DEFAULT true,
  scope_minimo text NOT NULL DEFAULT 'anon'::text CHECK (scope_minimo = ANY (ARRAY['anon'::text, 'authenticated'::text, 'admin_ip'::text])),
  orden integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT secciones_publicas_pkey PRIMARY KEY (seccion_id)
);