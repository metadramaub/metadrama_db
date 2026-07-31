export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      afirmaciones_fuentes_metricas: {
        Row: {
          afirmacion_id: string
          arquitectura_id: string | null
          confianza: string | null
          created_at: string
          created_by: string | null
          esquema_metrico_id: string | null
          esquema_rima_id: string | null
          estado_revision: string
          forma_id: string | null
          fuente_id: string
          localizador: string | null
          rasgo_id: string | null
          resumen: string | null
          tradicion_id: string | null
          updated_at: string
        }
        Insert: {
          afirmacion_id?: string
          arquitectura_id?: string | null
          confianza?: string | null
          created_at?: string
          created_by?: string | null
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          estado_revision?: string
          forma_id?: string | null
          fuente_id: string
          localizador?: string | null
          rasgo_id?: string | null
          resumen?: string | null
          tradicion_id?: string | null
          updated_at?: string
        }
        Update: {
          afirmacion_id?: string
          arquitectura_id?: string | null
          confianza?: string | null
          created_at?: string
          created_by?: string | null
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          estado_revision?: string
          forma_id?: string | null
          fuente_id?: string
          localizador?: string | null
          rasgo_id?: string | null
          resumen?: string | null
          tradicion_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_fuente_id_fkey"
            columns: ["fuente_id"]
            isOneToOne: false
            referencedRelation: "fuentes_metricas"
            referencedColumns: ["fuente_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_rasgo_id_fkey"
            columns: ["rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgos_metricos"
            referencedColumns: ["rasgo_id"]
          },
          {
            foreignKeyName: "afirmaciones_fuentes_metricas_tradicion_id_fkey"
            columns: ["tradicion_id"]
            isOneToOne: false
            referencedRelation: "tradiciones_metricas"
            referencedColumns: ["tradicion_id"]
          },
        ]
      }
      arquitectura_rasgos: {
        Row: {
          arquitectura_id: string
          created_at: string
          modalidad: string
          nota: string | null
          rasgo_id: string
          updated_at: string
          valor_id: string | null
          valor_numero: number | null
          valor_texto: string | null
        }
        Insert: {
          arquitectura_id: string
          created_at?: string
          modalidad?: string
          nota?: string | null
          rasgo_id: string
          updated_at?: string
          valor_id?: string | null
          valor_numero?: number | null
          valor_texto?: string | null
        }
        Update: {
          arquitectura_id?: string
          created_at?: string
          modalidad?: string
          nota?: string | null
          rasgo_id?: string
          updated_at?: string
          valor_id?: string | null
          valor_numero?: number | null
          valor_texto?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "arquitectura_rasgos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "arquitectura_rasgos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "arquitectura_rasgos_rasgo_id_fkey"
            columns: ["rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgos_metricos"
            referencedColumns: ["rasgo_id"]
          },
          {
            foreignKeyName: "arquitectura_rasgos_valor_id_fkey"
            columns: ["valor_id"]
            isOneToOne: false
            referencedRelation: "rasgo_valores"
            referencedColumns: ["valor_id"]
          },
        ]
      }
      arquitecturas_forma: {
        Row: {
          activo: boolean
          arquitectura_id: string
          created_at: string
          created_by: string | null
          demarcable: boolean
          descripcion: string | null
          estado_revision: string
          forma_id: string
          grado: string
          nombre: string
          orden: number | null
          origen_termino_id: string | null
          principal: boolean
          slug: string
          tipo_rima_id: string | null
          unidad_versos_max: number | null
          unidad_versos_min: number | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          activo?: boolean
          arquitectura_id?: string
          created_at?: string
          created_by?: string | null
          demarcable?: boolean
          descripcion?: string | null
          estado_revision?: string
          forma_id: string
          grado?: string
          nombre: string
          orden?: number | null
          origen_termino_id?: string | null
          principal?: boolean
          slug: string
          tipo_rima_id?: string | null
          unidad_versos_max?: number | null
          unidad_versos_min?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          activo?: boolean
          arquitectura_id?: string
          created_at?: string
          created_by?: string | null
          demarcable?: boolean
          descripcion?: string | null
          estado_revision?: string
          forma_id?: string
          grado?: string
          nombre?: string
          orden?: number | null
          origen_termino_id?: string | null
          principal?: boolean
          slug?: string
          tipo_rima_id?: string | null
          unidad_versos_max?: number | null
          unidad_versos_min?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "arquitecturas_forma_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "arquitecturas_forma_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "arquitecturas_forma_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "arquitecturas_forma_tipo_rima_id_fkey"
            columns: ["tipo_rima_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "arquitecturas_forma_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      atribucion_autores: {
        Row: {
          atribucion_id: string
          autor_id: string
          created_at: string
          orden: number | null
          updated_at: string
        }
        Insert: {
          atribucion_id: string
          autor_id: string
          created_at?: string
          orden?: number | null
          updated_at?: string
        }
        Update: {
          atribucion_id?: string
          autor_id?: string
          created_at?: string
          orden?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "atribucion_autores_atribucion_id_fkey"
            columns: ["atribucion_id"]
            isOneToOne: false
            referencedRelation: "atribuciones"
            referencedColumns: ["atribucion_id"]
          },
          {
            foreignKeyName: "atribucion_autores_autor_id_fkey"
            columns: ["autor_id"]
            isOneToOne: false
            referencedRelation: "autores"
            referencedColumns: ["autor_id"]
          },
        ]
      }
      atribucion_evidencias: {
        Row: {
          atribucion_evidencia_id: string
          atribucion_id: string
          created_at: string
          fuente_autoria: string | null
          orden: number | null
          tipo_atribucion_id: string
          updated_at: string
        }
        Insert: {
          atribucion_evidencia_id?: string
          atribucion_id: string
          created_at?: string
          fuente_autoria?: string | null
          orden?: number | null
          tipo_atribucion_id: string
          updated_at?: string
        }
        Update: {
          atribucion_evidencia_id?: string
          atribucion_id?: string
          created_at?: string
          fuente_autoria?: string | null
          orden?: number | null
          tipo_atribucion_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "atribucion_evidencias_atribucion_id_fkey"
            columns: ["atribucion_id"]
            isOneToOne: false
            referencedRelation: "atribuciones"
            referencedColumns: ["atribucion_id"]
          },
          {
            foreignKeyName: "atribucion_evidencias_tipo_atribucion_id_fkey"
            columns: ["tipo_atribucion_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      atribuciones: {
        Row: {
          atribucion_id: string
          composicion_autoria_id: string | null
          created_at: string
          fuente_autoria: string | null
          grupo_atribucion_id: string | null
          jornada_id: string | null
          modalidad_atribucion_id: string
          obra_id: string | null
          perfil_metrico: boolean
          tipo_atribucion_id: string
          updated_at: string
        }
        Insert: {
          atribucion_id?: string
          composicion_autoria_id?: string | null
          created_at?: string
          fuente_autoria?: string | null
          grupo_atribucion_id?: string | null
          jornada_id?: string | null
          modalidad_atribucion_id: string
          obra_id?: string | null
          perfil_metrico?: boolean
          tipo_atribucion_id: string
          updated_at?: string
        }
        Update: {
          atribucion_id?: string
          composicion_autoria_id?: string | null
          created_at?: string
          fuente_autoria?: string | null
          grupo_atribucion_id?: string | null
          jornada_id?: string | null
          modalidad_atribucion_id?: string
          obra_id?: string | null
          perfil_metrico?: boolean
          tipo_atribucion_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "atribuciones_composicion_autoria_id_fkey"
            columns: ["composicion_autoria_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "atribuciones_grupo_atribucion_id_fkey"
            columns: ["grupo_atribucion_id"]
            isOneToOne: false
            referencedRelation: "grupos_atribucion"
            referencedColumns: ["grupo_atribucion_id"]
          },
          {
            foreignKeyName: "atribuciones_jornada_id_fkey"
            columns: ["jornada_id"]
            isOneToOne: false
            referencedRelation: "jornadas"
            referencedColumns: ["jornada_id"]
          },
          {
            foreignKeyName: "atribuciones_modalidad_atribucion_id_fkey"
            columns: ["modalidad_atribucion_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "atribuciones_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
          {
            foreignKeyName: "atribuciones_tipo_atribucion_id_fkey"
            columns: ["tipo_atribucion_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      autores: {
        Row: {
          autor_id: string
          bnedatos_id: string | null
          created_at: string
          nombre_completo: string
          nombre_normalizado: string | null
          slug: string
          updated_at: string
          variantes_nombre: string[] | null
          viaf_id: string | null
          wikidata_id: string | null
        }
        Insert: {
          autor_id?: string
          bnedatos_id?: string | null
          created_at?: string
          nombre_completo: string
          nombre_normalizado?: string | null
          slug?: string
          updated_at?: string
          variantes_nombre?: string[] | null
          viaf_id?: string | null
          wikidata_id?: string | null
        }
        Update: {
          autor_id?: string
          bnedatos_id?: string | null
          created_at?: string
          nombre_completo?: string
          nombre_normalizado?: string | null
          slug?: string
          updated_at?: string
          variantes_nombre?: string[] | null
          viaf_id?: string | null
          wikidata_id?: string | null
        }
        Relationships: []
      }
      autores_resumen: {
        Row: {
          actualizado_en: string
          alcance: string
          autor_id: string
          metrica_sucia: boolean
          n_jornadas_sueltas: number
          n_obras_completas: number
          numero_efectivo_formas_agregado: number | null
          numero_efectivo_formas_medio: number | null
          perfil_formas: Json
          perfil_formas_hijos: Json
          total_versos_autor: number
        }
        Insert: {
          actualizado_en?: string
          alcance: string
          autor_id: string
          metrica_sucia?: boolean
          n_jornadas_sueltas?: number
          n_obras_completas?: number
          numero_efectivo_formas_agregado?: number | null
          numero_efectivo_formas_medio?: number | null
          perfil_formas?: Json
          perfil_formas_hijos?: Json
          total_versos_autor?: number
        }
        Update: {
          actualizado_en?: string
          alcance?: string
          autor_id?: string
          metrica_sucia?: boolean
          n_jornadas_sueltas?: number
          n_obras_completas?: number
          numero_efectivo_formas_agregado?: number | null
          numero_efectivo_formas_medio?: number | null
          perfil_formas?: Json
          perfil_formas_hijos?: Json
          total_versos_autor?: number
        }
        Relationships: [
          {
            foreignKeyName: "autores_resumen_autor_id_fkey"
            columns: ["autor_id"]
            isOneToOne: false
            referencedRelation: "autores"
            referencedColumns: ["autor_id"]
          },
        ]
      }
      catalogo_metrico_estado: {
        Row: {
          actualizado_en: string
          actualizado_por: string | null
          id: boolean
          modelo_version: number
          revision: number
        }
        Insert: {
          actualizado_en?: string
          actualizado_por?: string | null
          id?: boolean
          modelo_version?: number
          revision?: number
        }
        Update: {
          actualizado_en?: string
          actualizado_por?: string | null
          id?: boolean
          modelo_version?: number
          revision?: number
        }
        Relationships: [
          {
            foreignKeyName: "catalogo_metrico_estado_actualizado_por_fkey"
            columns: ["actualizado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      comentarios_internos: {
        Row: {
          comentario: string
          comentario_id: string
          created_at: string
          cuadro_id: string | null
          jornada_id: string | null
          obra_id: string
          publicado_at: string | null
          publicado_por: string | null
          seccion: string | null
          secuencia_id: string | null
          tipo_comentario_id: string
          updated_at: string
          user_id: string
          visible_publico: boolean
        }
        Insert: {
          comentario: string
          comentario_id?: string
          created_at?: string
          cuadro_id?: string | null
          jornada_id?: string | null
          obra_id: string
          publicado_at?: string | null
          publicado_por?: string | null
          seccion?: string | null
          secuencia_id?: string | null
          tipo_comentario_id: string
          updated_at?: string
          user_id: string
          visible_publico?: boolean
        }
        Update: {
          comentario?: string
          comentario_id?: string
          created_at?: string
          cuadro_id?: string | null
          jornada_id?: string | null
          obra_id?: string
          publicado_at?: string | null
          publicado_por?: string | null
          seccion?: string | null
          secuencia_id?: string | null
          tipo_comentario_id?: string
          updated_at?: string
          user_id?: string
          visible_publico?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "comentarios_internos_cuadro_id_fkey"
            columns: ["cuadro_id"]
            isOneToOne: false
            referencedRelation: "cuadros"
            referencedColumns: ["cuadro_id"]
          },
          {
            foreignKeyName: "comentarios_internos_jornada_id_fkey"
            columns: ["jornada_id"]
            isOneToOne: false
            referencedRelation: "jornadas"
            referencedColumns: ["jornada_id"]
          },
          {
            foreignKeyName: "comentarios_internos_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
          {
            foreignKeyName: "comentarios_internos_publicado_por_fkey"
            columns: ["publicado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "comentarios_internos_secuencia_id_fkey"
            columns: ["secuencia_id"]
            isOneToOne: false
            referencedRelation: "secuencias_metricas"
            referencedColumns: ["secuencia_id"]
          },
          {
            foreignKeyName: "comentarios_internos_tipo_comentario_id_fkey"
            columns: ["tipo_comentario_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "comentarios_internos_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "fk_usuario"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      cuadros: {
        Row: {
          created_at: string
          cuadro_id: string
          cuadro_num: number
          jornada_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          created_at?: string
          cuadro_id?: string
          cuadro_num: number
          jornada_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          created_at?: string
          cuadro_id?: string
          cuadro_num?: number
          jornada_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "cuadros_jornada_id_fkey"
            columns: ["jornada_id"]
            isOneToOne: false
            referencedRelation: "jornadas"
            referencedColumns: ["jornada_id"]
          },
        ]
      }
      dashboard_activity_state: {
        Row: {
          created_at: string
          last_seen_at: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          last_seen_at?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          last_seen_at?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "dashboard_activity_state_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      demarcador_familias_config: {
        Row: {
          created_at: string
          familia_id: string
          politica: string
          revisado_en: string
          revisado_por: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          familia_id: string
          politica: string
          revisado_en?: string
          revisado_por?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          familia_id?: string
          politica?: string
          revisado_en?: string
          revisado_por?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "demarcador_familias_config_familia_id_fkey"
            columns: ["familia_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "demarcador_familias_config_revisado_por_fkey"
            columns: ["revisado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      demarcador_versiones: {
        Row: {
          artefacto: Json
          catalogo_revision: number | null
          esquema: number
          estado: string
          fuente_actualizada_en: string | null
          fuente_tipo: string
          generado_en: string
          generado_por: string | null
          huella_fuente: string
          numero: number
          publicado_en: string | null
          publicado_por: string | null
          total_familias: number
          total_familias_variantes: number
          total_variantes_demarcables: number
          updated_at: string
          version_id: string
        }
        Insert: {
          artefacto: Json
          catalogo_revision?: number | null
          esquema?: number
          estado?: string
          fuente_actualizada_en?: string | null
          fuente_tipo?: string
          generado_en?: string
          generado_por?: string | null
          huella_fuente: string
          numero?: number
          publicado_en?: string | null
          publicado_por?: string | null
          total_familias: number
          total_familias_variantes: number
          total_variantes_demarcables: number
          updated_at?: string
          version_id?: string
        }
        Update: {
          artefacto?: Json
          catalogo_revision?: number | null
          esquema?: number
          estado?: string
          fuente_actualizada_en?: string | null
          fuente_tipo?: string
          generado_en?: string
          generado_por?: string | null
          huella_fuente?: string
          numero?: number
          publicado_en?: string | null
          publicado_por?: string | null
          total_familias?: number
          total_familias_variantes?: number
          total_variantes_demarcables?: number
          updated_at?: string
          version_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "demarcador_versiones_generado_por_fkey"
            columns: ["generado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "demarcador_versiones_publicado_por_fkey"
            columns: ["publicado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      denominaciones_metricas: {
        Row: {
          alias_id: string
          arquitectura_id: string | null
          created_at: string
          esquema_metrico_id: string | null
          esquema_rima_id: string | null
          forma_id: string | null
          fuente_id: string | null
          idioma: string | null
          nombre: string
          origen_termino_id: string | null
          preferente: boolean
          repeticion_id: string | null
          seccion_id: string | null
          slug_normalizado: string
          tipo_alias: string
          updated_at: string
          variedad_id: string | null
        }
        Insert: {
          alias_id?: string
          arquitectura_id?: string | null
          created_at?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          forma_id?: string | null
          fuente_id?: string | null
          idioma?: string | null
          nombre: string
          origen_termino_id?: string | null
          preferente?: boolean
          repeticion_id?: string | null
          seccion_id?: string | null
          slug_normalizado: string
          tipo_alias?: string
          updated_at?: string
          variedad_id?: string | null
        }
        Update: {
          alias_id?: string
          arquitectura_id?: string | null
          created_at?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          forma_id?: string | null
          fuente_id?: string | null
          idioma?: string | null
          nombre?: string
          origen_termino_id?: string | null
          preferente?: boolean
          repeticion_id?: string | null
          seccion_id?: string | null
          slug_normalizado?: string
          tipo_alias?: string
          updated_at?: string
          variedad_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "denominaciones_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_fuente_id_fkey"
            columns: ["fuente_id"]
            isOneToOne: false
            referencedRelation: "fuentes_metricas"
            referencedColumns: ["fuente_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_repeticion_id_fkey"
            columns: ["repeticion_id"]
            isOneToOne: false
            referencedRelation: "repeticiones_metricas"
            referencedColumns: ["repeticion_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_seccion_id_fkey"
            columns: ["seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "denominaciones_metricas_variedad_id_fkey"
            columns: ["variedad_id"]
            isOneToOne: false
            referencedRelation: "variedades_arquitectura"
            referencedColumns: ["variedad_id"]
          },
        ]
      }
      desviaciones_editor_metrico: {
        Row: {
          created_at: string
          desviacion_prueba_id: string
          dimension: string
          esquema_rima_observado_id: string | null
          metro_observado_id: string | null
          observaciones: string | null
          realizacion_prueba_id: string | null
          relacion_norma: string
          repeticion_observada_id: string | null
          seccion_observada_id: string | null
          secuencia_prueba_id: string
          updated_at: string
          v_fin: number
          v_ini: number
          valor_rasgo_observado_id: string | null
        }
        Insert: {
          created_at?: string
          desviacion_prueba_id?: string
          dimension: string
          esquema_rima_observado_id?: string | null
          metro_observado_id?: string | null
          observaciones?: string | null
          realizacion_prueba_id?: string | null
          relacion_norma: string
          repeticion_observada_id?: string | null
          seccion_observada_id?: string | null
          secuencia_prueba_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
          valor_rasgo_observado_id?: string | null
        }
        Update: {
          created_at?: string
          desviacion_prueba_id?: string
          dimension?: string
          esquema_rima_observado_id?: string | null
          metro_observado_id?: string | null
          observaciones?: string | null
          realizacion_prueba_id?: string | null
          relacion_norma?: string
          repeticion_observada_id?: string | null
          seccion_observada_id?: string | null
          secuencia_prueba_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
          valor_rasgo_observado_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "desviaciones_editor_metrico_esquema_rima_observado_id_fkey"
            columns: ["esquema_rima_observado_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_metro_observado_id_fkey"
            columns: ["metro_observado_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_realizacion_prueba_id_fkey"
            columns: ["realizacion_prueba_id"]
            isOneToOne: false
            referencedRelation: "realizaciones_editor_metrico"
            referencedColumns: ["realizacion_prueba_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_repeticion_observada_id_fkey"
            columns: ["repeticion_observada_id"]
            isOneToOne: false
            referencedRelation: "repeticiones_metricas"
            referencedColumns: ["repeticion_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_seccion_observada_id_fkey"
            columns: ["seccion_observada_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_secuencia_prueba_id_fkey"
            columns: ["secuencia_prueba_id"]
            isOneToOne: false
            referencedRelation: "secuencias_editor_metrico"
            referencedColumns: ["secuencia_prueba_id"]
          },
          {
            foreignKeyName: "desviaciones_editor_metrico_valor_rasgo_observado_id_fkey"
            columns: ["valor_rasgo_observado_id"]
            isOneToOne: false
            referencedRelation: "rasgo_valores"
            referencedColumns: ["valor_id"]
          },
        ]
      }
      editores: {
        Row: {
          activo: boolean | null
          created_at: string
          email: string
          institucion: string | null
          last_login: string | null
          nombre_completo: string
          orcid: string | null
          role: string
          updated_at: string
          user_id: string
        }
        Insert: {
          activo?: boolean | null
          created_at?: string
          email: string
          institucion?: string | null
          last_login?: string | null
          nombre_completo: string
          orcid?: string | null
          role: string
          updated_at?: string
          user_id: string
        }
        Update: {
          activo?: boolean | null
          created_at?: string
          email?: string
          institucion?: string | null
          last_login?: string | null
          nombre_completo?: string
          orcid?: string | null
          role?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "editores_role_fkey"
            columns: ["role"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      elecciones_editor_metrico: {
        Row: {
          created_at: string
          eleccion_prueba_id: string
          grupo_eleccion_id: string
          observaciones: string | null
          opcion_eleccion_id: string | null
          realizacion_prueba_id: string | null
          secuencia_prueba_id: string
          valor_texto: string | null
        }
        Insert: {
          created_at?: string
          eleccion_prueba_id?: string
          grupo_eleccion_id: string
          observaciones?: string | null
          opcion_eleccion_id?: string | null
          realizacion_prueba_id?: string | null
          secuencia_prueba_id: string
          valor_texto?: string | null
        }
        Update: {
          created_at?: string
          eleccion_prueba_id?: string
          grupo_eleccion_id?: string
          observaciones?: string | null
          opcion_eleccion_id?: string | null
          realizacion_prueba_id?: string | null
          secuencia_prueba_id?: string
          valor_texto?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "elecciones_editor_metrico_grupo_eleccion_id_fkey"
            columns: ["grupo_eleccion_id"]
            isOneToOne: false
            referencedRelation: "grupos_eleccion_metrica"
            referencedColumns: ["grupo_eleccion_id"]
          },
          {
            foreignKeyName: "elecciones_editor_metrico_opcion_eleccion_id_fkey"
            columns: ["opcion_eleccion_id"]
            isOneToOne: false
            referencedRelation: "opciones_eleccion_metrica"
            referencedColumns: ["opcion_eleccion_id"]
          },
          {
            foreignKeyName: "elecciones_editor_metrico_realizacion_prueba_id_fkey"
            columns: ["realizacion_prueba_id"]
            isOneToOne: false
            referencedRelation: "realizaciones_editor_metrico"
            referencedColumns: ["realizacion_prueba_id"]
          },
          {
            foreignKeyName: "elecciones_editor_metrico_secuencia_prueba_id_fkey"
            columns: ["secuencia_prueba_id"]
            isOneToOne: false
            referencedRelation: "secuencias_editor_metrico"
            referencedColumns: ["secuencia_prueba_id"]
          },
        ]
      }
      escenarios_editor_metrico: {
        Row: {
          created_at: string
          created_by: string
          descripcion: string | null
          escenario_id: string
          nombre: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by?: string
          descripcion?: string | null
          escenario_id?: string
          nombre: string
          updated_at?: string
          updated_by?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          descripcion?: string | null
          escenario_id?: string
          nombre?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "escenarios_editor_metrico_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "escenarios_editor_metrico_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      esquema_metrico_opciones: {
        Row: {
          created_at: string
          esquema_metrico_id: string
          metro_id: string
          nota: string | null
          orden: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          esquema_metrico_id: string
          metro_id: string
          nota?: string | null
          orden?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          esquema_metrico_id?: string
          metro_id?: string
          nota?: string | null
          orden?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquema_metrico_opciones_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "esquema_metrico_opciones_metro_id_fkey"
            columns: ["metro_id"]
            isOneToOne: false
            referencedRelation: "metros"
            referencedColumns: ["metro_id"]
          },
        ]
      }
      esquema_metrico_posiciones: {
        Row: {
          alternativa: number
          created_at: string
          esquema_metrico_id: string
          grupo_repeticion: string | null
          metro_id: string
          nota: string | null
          opcional: boolean
          posicion: number
          posicion_id: string
          updated_at: string
        }
        Insert: {
          alternativa?: number
          created_at?: string
          esquema_metrico_id: string
          grupo_repeticion?: string | null
          metro_id: string
          nota?: string | null
          opcional?: boolean
          posicion: number
          posicion_id?: string
          updated_at?: string
        }
        Update: {
          alternativa?: number
          created_at?: string
          esquema_metrico_id?: string
          grupo_repeticion?: string | null
          metro_id?: string
          nota?: string | null
          opcional?: boolean
          posicion?: number
          posicion_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquema_metrico_posiciones_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "esquema_metrico_posiciones_metro_id_fkey"
            columns: ["metro_id"]
            isOneToOne: false
            referencedRelation: "metros"
            referencedColumns: ["metro_id"]
          },
        ]
      }
      esquema_rima_enlaces: {
        Row: {
          bloque_destino: number | null
          bloque_origen: number
          created_at: string
          desplazamiento_bloque: number
          enlace_id: string
          esquema_rima_id: string
          nota: string | null
          obligatorio: boolean
          posicion_destino: number
          posicion_origen: number
          tipo_enlace: string
          ubicacion_destino: string
          ubicacion_origen: string
          updated_at: string
        }
        Insert: {
          bloque_destino?: number | null
          bloque_origen?: number
          created_at?: string
          desplazamiento_bloque?: number
          enlace_id?: string
          esquema_rima_id: string
          nota?: string | null
          obligatorio?: boolean
          posicion_destino: number
          posicion_origen: number
          tipo_enlace?: string
          ubicacion_destino?: string
          ubicacion_origen?: string
          updated_at?: string
        }
        Update: {
          bloque_destino?: number | null
          bloque_origen?: number
          created_at?: string
          desplazamiento_bloque?: number
          enlace_id?: string
          esquema_rima_id?: string
          nota?: string | null
          obligatorio?: boolean
          posicion_destino?: number
          posicion_origen?: number
          tipo_enlace?: string
          ubicacion_destino?: string
          ubicacion_origen?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquema_rima_enlaces_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
        ]
      }
      esquema_rima_posiciones: {
        Row: {
          bloque: number
          clase_rima: string | null
          created_at: string
          esquema_rima_id: string
          nota: string | null
          opcional: boolean
          posicion: number
          posicion_id: string
          seccion: string | null
          suelto: boolean
          ubicacion: string
          updated_at: string
        }
        Insert: {
          bloque?: number
          clase_rima?: string | null
          created_at?: string
          esquema_rima_id: string
          nota?: string | null
          opcional?: boolean
          posicion: number
          posicion_id?: string
          seccion?: string | null
          suelto?: boolean
          ubicacion?: string
          updated_at?: string
        }
        Update: {
          bloque?: number
          clase_rima?: string | null
          created_at?: string
          esquema_rima_id?: string
          nota?: string | null
          opcional?: boolean
          posicion?: number
          posicion_id?: string
          seccion?: string | null
          suelto?: boolean
          ubicacion?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquema_rima_posiciones_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
        ]
      }
      esquema_rima_restricciones: {
        Row: {
          created_at: string
          descripcion: string | null
          esquema_rima_id: string
          obligatoria: boolean
          restriccion_id: string
          tipo: string
          updated_at: string
          valor_numero: number | null
          valor_texto: string | null
        }
        Insert: {
          created_at?: string
          descripcion?: string | null
          esquema_rima_id: string
          obligatoria?: boolean
          restriccion_id?: string
          tipo: string
          updated_at?: string
          valor_numero?: number | null
          valor_texto?: string | null
        }
        Update: {
          created_at?: string
          descripcion?: string | null
          esquema_rima_id?: string
          obligatoria?: boolean
          restriccion_id?: string
          tipo?: string
          updated_at?: string
          valor_numero?: number | null
          valor_texto?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "esquema_rima_restricciones_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
        ]
      }
      esquemas_metricos: {
        Row: {
          ambito: string
          arquitectura_id: string
          created_at: string
          descripcion: string | null
          esquema_metrico_id: string
          estado_revision: string
          nombre: string | null
          tipo: string
          updated_at: string
        }
        Insert: {
          ambito?: string
          arquitectura_id: string
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id?: string
          estado_revision?: string
          nombre?: string | null
          tipo: string
          updated_at?: string
        }
        Update: {
          ambito?: string
          arquitectura_id?: string
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id?: string
          estado_revision?: string
          nombre?: string | null
          tipo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquemas_metricos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "esquemas_metricos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
        ]
      }
      esquemas_rima: {
        Row: {
          ambito: string
          arquitectura_id: string
          comportamiento: string
          created_at: string
          descripcion: string | null
          esquema_rima_id: string
          estado_revision: string
          fijeza: string
          nombre: string | null
          notacion: string | null
          origen_termino_id: string | null
          tipo_rima_id: string | null
          updated_at: string
        }
        Insert: {
          ambito?: string
          arquitectura_id: string
          comportamiento?: string
          created_at?: string
          descripcion?: string | null
          esquema_rima_id?: string
          estado_revision?: string
          fijeza?: string
          nombre?: string | null
          notacion?: string | null
          origen_termino_id?: string | null
          tipo_rima_id?: string | null
          updated_at?: string
        }
        Update: {
          ambito?: string
          arquitectura_id?: string
          comportamiento?: string
          created_at?: string
          descripcion?: string | null
          esquema_rima_id?: string
          estado_revision?: string
          fijeza?: string
          nombre?: string | null
          notacion?: string | null
          origen_termino_id?: string | null
          tipo_rima_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "esquemas_rima_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "esquemas_rima_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "esquemas_rima_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "esquemas_rima_tipo_rima_id_fkey"
            columns: ["tipo_rima_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      estrofa_tipo_metros: {
        Row: {
          created_at: string
          estrofa_tipo_id: string
          metro_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          estrofa_tipo_id: string
          metro_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          estrofa_tipo_id?: string
          metro_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "estrofa_tipo_metros_estrofa_tipo_id_fkey"
            columns: ["estrofa_tipo_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "estrofa_tipo_metros_metro_id_fkey"
            columns: ["metro_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      estructuras_secciones: {
        Row: {
          arquitectura_id: string
          arquitectura_referenciada_id: string | null
          created_at: string
          esquema_metrico_id: string | null
          esquema_rima_id: string | null
          nombre: string | null
          nota: string | null
          orden: number
          repeticiones_max: number | null
          repeticiones_min: number | null
          seccion_id: string
          seccion_padre_id: string | null
          tipo_seccion: string
          updated_at: string
          versos_max: number | null
          versos_min: number | null
        }
        Insert: {
          arquitectura_id: string
          arquitectura_referenciada_id?: string | null
          created_at?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          nombre?: string | null
          nota?: string | null
          orden: number
          repeticiones_max?: number | null
          repeticiones_min?: number | null
          seccion_id?: string
          seccion_padre_id?: string | null
          tipo_seccion: string
          updated_at?: string
          versos_max?: number | null
          versos_min?: number | null
        }
        Update: {
          arquitectura_id?: string
          arquitectura_referenciada_id?: string | null
          created_at?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          nombre?: string | null
          nota?: string | null
          orden?: number
          repeticiones_max?: number | null
          repeticiones_min?: number | null
          seccion_id?: string
          seccion_padre_id?: string | null
          tipo_seccion?: string
          updated_at?: string
          versos_max?: number | null
          versos_min?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "estructuras_secciones_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_arquitectura_referenciada_id_fkey"
            columns: ["arquitectura_referenciada_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_arquitectura_referenciada_id_fkey"
            columns: ["arquitectura_referenciada_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "estructuras_secciones_seccion_padre_id_fkey"
            columns: ["seccion_padre_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
        ]
      }
      forma_relaciones: {
        Row: {
          cantidad_max: number | null
          cantidad_min: number | null
          created_at: string
          estado_revision: string
          forma_destino_id: string
          forma_origen_id: string
          nota: string | null
          orden_composicion: number | null
          relacion_id: string
          tipo_relacion: string
          updated_at: string
        }
        Insert: {
          cantidad_max?: number | null
          cantidad_min?: number | null
          created_at?: string
          estado_revision?: string
          forma_destino_id: string
          forma_origen_id: string
          nota?: string | null
          orden_composicion?: number | null
          relacion_id?: string
          tipo_relacion: string
          updated_at?: string
        }
        Update: {
          cantidad_max?: number | null
          cantidad_min?: number | null
          created_at?: string
          estado_revision?: string
          forma_destino_id?: string
          forma_origen_id?: string
          nota?: string | null
          orden_composicion?: number | null
          relacion_id?: string
          tipo_relacion?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "forma_relaciones_forma_destino_id_fkey"
            columns: ["forma_destino_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "forma_relaciones_forma_origen_id_fkey"
            columns: ["forma_origen_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
        ]
      }
      formas_metricas: {
        Row: {
          activo: boolean
          created_at: string
          created_by: string | null
          definicion: string | null
          estado_revision: string
          forma_id: string
          grado_especificacion: string | null
          nivel_estructural: string
          nombre: string
          orden: number | null
          origen_termino_id: string | null
          seleccionable: boolean
          slug: string
          tipo_registro: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          activo?: boolean
          created_at?: string
          created_by?: string | null
          definicion?: string | null
          estado_revision?: string
          forma_id?: string
          grado_especificacion?: string | null
          nivel_estructural?: string
          nombre: string
          orden?: number | null
          origen_termino_id?: string | null
          seleccionable?: boolean
          slug: string
          tipo_registro?: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          activo?: boolean
          created_at?: string
          created_by?: string | null
          definicion?: string | null
          estado_revision?: string
          forma_id?: string
          grado_especificacion?: string | null
          nivel_estructural?: string
          nombre?: string
          orden?: number | null
          origen_termino_id?: string | null
          seleccionable?: boolean
          slug?: string
          tipo_registro?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "formas_metricas_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "formas_metricas_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "formas_metricas_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      formas_tradiciones: {
        Row: {
          created_at: string
          cronologia: string | null
          forma_id: string
          nota: string | null
          tradicion_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          cronologia?: string | null
          forma_id: string
          nota?: string | null
          tradicion_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          cronologia?: string | null
          forma_id?: string
          nota?: string | null
          tradicion_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "formas_tradiciones_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "formas_tradiciones_tradicion_id_fkey"
            columns: ["tradicion_id"]
            isOneToOne: false
            referencedRelation: "tradiciones_metricas"
            referencedColumns: ["tradicion_id"]
          },
        ]
      }
      fuentes_metricas: {
        Row: {
          anio: number | null
          autoria: string | null
          cita: string | null
          created_at: string
          doi: string | null
          fuente_id: string
          nota: string | null
          publicacion: string | null
          tipo: string | null
          titulo: string
          updated_at: string
          url: string | null
        }
        Insert: {
          anio?: number | null
          autoria?: string | null
          cita?: string | null
          created_at?: string
          doi?: string | null
          fuente_id?: string
          nota?: string | null
          publicacion?: string | null
          tipo?: string | null
          titulo: string
          updated_at?: string
          url?: string | null
        }
        Update: {
          anio?: number | null
          autoria?: string | null
          cita?: string | null
          created_at?: string
          doi?: string | null
          fuente_id?: string
          nota?: string | null
          publicacion?: string | null
          tipo?: string | null
          titulo?: string
          updated_at?: string
          url?: string | null
        }
        Relationships: []
      }
      grupos_atribucion: {
        Row: {
          created_at: string
          grupo_atribucion_id: string
          jornada_id: string | null
          obra_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          grupo_atribucion_id?: string
          jornada_id?: string | null
          obra_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          grupo_atribucion_id?: string
          jornada_id?: string | null
          obra_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "grupos_atribucion_jornada_id_fkey"
            columns: ["jornada_id"]
            isOneToOne: false
            referencedRelation: "jornadas"
            referencedColumns: ["jornada_id"]
          },
          {
            foreignKeyName: "grupos_atribucion_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
        ]
      }
      grupos_eleccion_metrica: {
        Row: {
          activo: boolean
          alcance: string
          arquitectura_id: string
          ayuda_editor: string | null
          created_at: string
          define_norma: boolean
          dimension: string
          estado_revision: string
          grupo_eleccion_id: string
          nombre: string
          orden: number | null
          permite_aplicar_global: boolean
          seccion_id: string | null
          selecciones_max: number
          selecciones_min: number
          slug: string
          tipo_control: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          alcance?: string
          arquitectura_id: string
          ayuda_editor?: string | null
          created_at?: string
          define_norma?: boolean
          dimension: string
          estado_revision?: string
          grupo_eleccion_id?: string
          nombre: string
          orden?: number | null
          permite_aplicar_global?: boolean
          seccion_id?: string | null
          selecciones_max?: number
          selecciones_min?: number
          slug: string
          tipo_control?: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          alcance?: string
          arquitectura_id?: string
          ayuda_editor?: string | null
          created_at?: string
          define_norma?: boolean
          dimension?: string
          estado_revision?: string
          grupo_eleccion_id?: string
          nombre?: string
          orden?: number | null
          permite_aplicar_global?: boolean
          seccion_id?: string | null
          selecciones_max?: number
          selecciones_min?: number
          slug?: string
          tipo_control?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "grupos_eleccion_metrica_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "grupos_eleccion_metrica_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "grupos_eleccion_metrica_seccion_id_fkey"
            columns: ["seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
        ]
      }
      jornadas: {
        Row: {
          created_at: string
          jornada_id: string
          jornada_num: number
          obra_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          created_at?: string
          jornada_id?: string
          jornada_num: number
          obra_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          created_at?: string
          jornada_id?: string
          jornada_num?: number
          obra_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "jornadas_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
        ]
      }
      metro_segmentos: {
        Row: {
          alternativa: number
          created_at: string
          funcion: string | null
          metro_id: string
          nota: string | null
          pausa_posterior: string | null
          posicion: number
          segmento_id: string
          silabas: number
          updated_at: string
        }
        Insert: {
          alternativa?: number
          created_at?: string
          funcion?: string | null
          metro_id: string
          nota?: string | null
          pausa_posterior?: string | null
          posicion: number
          segmento_id?: string
          silabas: number
          updated_at?: string
        }
        Update: {
          alternativa?: number
          created_at?: string
          funcion?: string | null
          metro_id?: string
          nota?: string | null
          pausa_posterior?: string | null
          posicion?: number
          segmento_id?: string
          silabas?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "metro_segmentos_metro_id_fkey"
            columns: ["metro_id"]
            isOneToOne: false
            referencedRelation: "metros"
            referencedColumns: ["metro_id"]
          },
        ]
      }
      metros: {
        Row: {
          activo: boolean
          arte: string | null
          created_at: string
          descripcion: string | null
          estado_revision: string
          metro_id: string
          nombre: string
          orden: number | null
          origen_termino_id: string | null
          silabas: number
          slug: string
          tipo: string
          tipo_cesura: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean
          arte?: string | null
          created_at?: string
          descripcion?: string | null
          estado_revision?: string
          metro_id?: string
          nombre: string
          orden?: number | null
          origen_termino_id?: string | null
          silabas: number
          slug: string
          tipo?: string
          tipo_cesura?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean
          arte?: string | null
          created_at?: string
          descripcion?: string | null
          estado_revision?: string
          metro_id?: string
          nombre?: string
          orden?: number | null
          origen_termino_id?: string | null
          silabas?: number
          slug?: string
          tipo?: string
          tipo_cesura?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "metros_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      migracion_termino_destinos: {
        Row: {
          alias_id: string | null
          arquitectura_id: string | null
          created_at: string
          destino_id: string
          esquema_metrico_id: string | null
          esquema_rima_id: string | null
          forma_id: string | null
          nota: string | null
          rasgo_id: string | null
          termino_id: string
          tipo_operacion: string
          updated_at: string
          valor_rasgo_id: string | null
          variedad_id: string | null
        }
        Insert: {
          alias_id?: string | null
          arquitectura_id?: string | null
          created_at?: string
          destino_id?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          forma_id?: string | null
          nota?: string | null
          rasgo_id?: string | null
          termino_id: string
          tipo_operacion: string
          updated_at?: string
          valor_rasgo_id?: string | null
          variedad_id?: string | null
        }
        Update: {
          alias_id?: string | null
          arquitectura_id?: string | null
          created_at?: string
          destino_id?: string
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          forma_id?: string | null
          nota?: string | null
          rasgo_id?: string | null
          termino_id?: string
          tipo_operacion?: string
          updated_at?: string
          valor_rasgo_id?: string | null
          variedad_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "migracion_termino_destinos_alias_id_fkey"
            columns: ["alias_id"]
            isOneToOne: false
            referencedRelation: "denominaciones_metricas"
            referencedColumns: ["alias_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_combinacion_id_fkey"
            columns: ["variedad_id"]
            isOneToOne: false
            referencedRelation: "variedades_arquitectura"
            referencedColumns: ["variedad_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_rasgo_id_fkey"
            columns: ["rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgos_metricos"
            referencedColumns: ["rasgo_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_termino_id_fkey"
            columns: ["termino_id"]
            isOneToOne: false
            referencedRelation: "migracion_terminos_metricos"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "migracion_termino_destinos_valor_rasgo_id_fkey"
            columns: ["valor_rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgo_valores"
            referencedColumns: ["valor_id"]
          },
        ]
      }
      migracion_terminos_metricos: {
        Row: {
          certeza: string
          clasificacion_decidida: string | null
          clasificacion_propuesta: string
          created_at: string
          estado_revision: string
          notas_ip: string | null
          propuesta: string
          requiere_revision: boolean
          revisado_en: string | null
          revisado_por: string | null
          termino_id: string
          updated_at: string
        }
        Insert: {
          certeza: string
          clasificacion_decidida?: string | null
          clasificacion_propuesta: string
          created_at?: string
          estado_revision?: string
          notas_ip?: string | null
          propuesta: string
          requiere_revision?: boolean
          revisado_en?: string | null
          revisado_por?: string | null
          termino_id: string
          updated_at?: string
        }
        Update: {
          certeza?: string
          clasificacion_decidida?: string | null
          clasificacion_propuesta?: string
          created_at?: string
          estado_revision?: string
          notas_ip?: string | null
          propuesta?: string
          requiere_revision?: boolean
          revisado_en?: string | null
          revisado_por?: string | null
          termino_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "migracion_terminos_metricos_revisado_por_fkey"
            columns: ["revisado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "migracion_terminos_metricos_termino_id_fkey"
            columns: ["termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      obras: {
        Row: {
          autor_ficha_publico: string | null
          bibliografia: string | null
          created_at: string
          edicion: string | null
          editor_asignado: string | null
          estado: string
          fecha_asignacion: string | null
          fecha_cambio_estado: string | null
          fecha_fin_metadrama: number | null
          fecha_fin_trad: number | null
          fecha_inicio_metadrama: number | null
          fecha_inicio_trad: number | null
          fuente_fecha: string | null
          genero_id: string | null
          obra_id: string
          observaciones: string | null
          slug: string
          titulo: string
          titulo_normalizado: string | null
          total_versos: number | null
          updated_at: string
          variantes_titulo: string[] | null
          visible_publico: boolean | null
        }
        Insert: {
          autor_ficha_publico?: string | null
          bibliografia?: string | null
          created_at?: string
          edicion?: string | null
          editor_asignado?: string | null
          estado: string
          fecha_asignacion?: string | null
          fecha_cambio_estado?: string | null
          fecha_fin_metadrama?: number | null
          fecha_fin_trad?: number | null
          fecha_inicio_metadrama?: number | null
          fecha_inicio_trad?: number | null
          fuente_fecha?: string | null
          genero_id?: string | null
          obra_id?: string
          observaciones?: string | null
          slug?: string
          titulo: string
          titulo_normalizado?: string | null
          total_versos?: number | null
          updated_at?: string
          variantes_titulo?: string[] | null
          visible_publico?: boolean | null
        }
        Update: {
          autor_ficha_publico?: string | null
          bibliografia?: string | null
          created_at?: string
          edicion?: string | null
          editor_asignado?: string | null
          estado?: string
          fecha_asignacion?: string | null
          fecha_cambio_estado?: string | null
          fecha_fin_metadrama?: number | null
          fecha_fin_trad?: number | null
          fecha_inicio_metadrama?: number | null
          fecha_inicio_trad?: number | null
          fuente_fecha?: string | null
          genero_id?: string | null
          obra_id?: string
          observaciones?: string | null
          slug?: string
          titulo?: string
          titulo_normalizado?: string | null
          total_versos?: number | null
          updated_at?: string
          variantes_titulo?: string[] | null
          visible_publico?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "obras_editor_asignado_fkey"
            columns: ["editor_asignado"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "obras_estado_fkey"
            columns: ["estado"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "obras_genero_id_fkey"
            columns: ["genero_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      obras_resumen: {
        Row: {
          actualizado_en: string | null
          cuadros_tramos: Json | null
          densidad_transiciones: number | null
          formas_presentes: string[] | null
          intervencion_donaire: string | null
          intervencion_femenina: string | null
          intervencion_sobrenaturales: string | null
          jornadas_tramos: Json | null
          metrica_sucia: boolean
          metros_presentes: string[] | null
          n_formas_distintas: number | null
          n_jornadas: number | null
          n_secuencias: number | null
          numero_efectivo_formas: number | null
          obra_id: string
          p_max: number | null
          pct_cantado: number | null
          perfil_formas: Json | null
          subtipos_presentes: string[] | null
          tiene_cambio_espacio: boolean | null
          tiene_versos_partidos: boolean | null
          tipos_forma_presentes: string[] | null
          total_versos: number | null
          tramos: Json | null
          variaciones_presentes: string[] | null
        }
        Insert: {
          actualizado_en?: string | null
          cuadros_tramos?: Json | null
          densidad_transiciones?: number | null
          formas_presentes?: string[] | null
          intervencion_donaire?: string | null
          intervencion_femenina?: string | null
          intervencion_sobrenaturales?: string | null
          jornadas_tramos?: Json | null
          metrica_sucia?: boolean
          metros_presentes?: string[] | null
          n_formas_distintas?: number | null
          n_jornadas?: number | null
          n_secuencias?: number | null
          numero_efectivo_formas?: number | null
          obra_id: string
          p_max?: number | null
          pct_cantado?: number | null
          perfil_formas?: Json | null
          subtipos_presentes?: string[] | null
          tiene_cambio_espacio?: boolean | null
          tiene_versos_partidos?: boolean | null
          tipos_forma_presentes?: string[] | null
          total_versos?: number | null
          tramos?: Json | null
          variaciones_presentes?: string[] | null
        }
        Update: {
          actualizado_en?: string | null
          cuadros_tramos?: Json | null
          densidad_transiciones?: number | null
          formas_presentes?: string[] | null
          intervencion_donaire?: string | null
          intervencion_femenina?: string | null
          intervencion_sobrenaturales?: string | null
          jornadas_tramos?: Json | null
          metrica_sucia?: boolean
          metros_presentes?: string[] | null
          n_formas_distintas?: number | null
          n_jornadas?: number | null
          n_secuencias?: number | null
          numero_efectivo_formas?: number | null
          obra_id?: string
          p_max?: number | null
          pct_cantado?: number | null
          perfil_formas?: Json | null
          subtipos_presentes?: string[] | null
          tiene_cambio_espacio?: boolean | null
          tiene_versos_partidos?: boolean | null
          tipos_forma_presentes?: string[] | null
          total_versos?: number | null
          tramos?: Json | null
          variaciones_presentes?: string[] | null
        }
        Relationships: [
          {
            foreignKeyName: "obras_resumen_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: true
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
        ]
      }
      obras_revisores: {
        Row: {
          asignado_por: string
          created_at: string
          obra_id: string
          revisor_id: string
          updated_at: string
        }
        Insert: {
          asignado_por: string
          created_at?: string
          obra_id: string
          revisor_id: string
          updated_at?: string
        }
        Update: {
          asignado_por?: string
          created_at?: string
          obra_id?: string
          revisor_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "obras_revisores_asignado_por_fkey"
            columns: ["asignado_por"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "obras_revisores_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
          {
            foreignKeyName: "obras_revisores_revisor_id_fkey"
            columns: ["revisor_id"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      opciones_eleccion_metrica: {
        Row: {
          activo: boolean
          created_at: string
          descripcion: string | null
          esquema_metrico_id: string | null
          esquema_rima_id: string | null
          extension_desde_seccion_id: string | null
          grupo_eleccion_id: string
          materializa_seccion_id: string | null
          metro_id: string | null
          nombre: string
          opcion_eleccion_id: string
          orden: number | null
          posicion_unidad: number | null
          rasgo_id: string | null
          repeticion_id: string | null
          seccion_id: string | null
          slug: string
          updated_at: string
          valor_rasgo_id: string | null
          variedad_id: string | null
        }
        Insert: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          extension_desde_seccion_id?: string | null
          grupo_eleccion_id: string
          materializa_seccion_id?: string | null
          metro_id?: string | null
          nombre: string
          opcion_eleccion_id?: string
          orden?: number | null
          posicion_unidad?: number | null
          rasgo_id?: string | null
          repeticion_id?: string | null
          seccion_id?: string | null
          slug: string
          updated_at?: string
          valor_rasgo_id?: string | null
          variedad_id?: string | null
        }
        Update: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id?: string | null
          esquema_rima_id?: string | null
          extension_desde_seccion_id?: string | null
          grupo_eleccion_id?: string
          materializa_seccion_id?: string | null
          metro_id?: string | null
          nombre?: string
          opcion_eleccion_id?: string
          orden?: number | null
          posicion_unidad?: number | null
          rasgo_id?: string | null
          repeticion_id?: string | null
          seccion_id?: string | null
          slug?: string
          updated_at?: string
          valor_rasgo_id?: string | null
          variedad_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "opciones_eleccion_metrica_combinacion_id_fkey"
            columns: ["variedad_id"]
            isOneToOne: false
            referencedRelation: "variedades_arquitectura"
            referencedColumns: ["variedad_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_extension_desde_seccion_id_fkey"
            columns: ["extension_desde_seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_grupo_eleccion_id_fkey"
            columns: ["grupo_eleccion_id"]
            isOneToOne: false
            referencedRelation: "grupos_eleccion_metrica"
            referencedColumns: ["grupo_eleccion_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_materializa_seccion_id_fkey"
            columns: ["materializa_seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_metro_id_fkey"
            columns: ["metro_id"]
            isOneToOne: false
            referencedRelation: "metros"
            referencedColumns: ["metro_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_rasgo_id_fkey"
            columns: ["rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgos_metricos"
            referencedColumns: ["rasgo_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_repeticion_id_fkey"
            columns: ["repeticion_id"]
            isOneToOne: false
            referencedRelation: "repeticiones_metricas"
            referencedColumns: ["repeticion_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_seccion_id_fkey"
            columns: ["seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "opciones_eleccion_metrica_valor_rasgo_id_fkey"
            columns: ["valor_rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgo_valores"
            referencedColumns: ["valor_id"]
          },
        ]
      }
      proyecto_activo: {
        Row: {
          created_at: string
          id: number
          status: string | null
          timestamp: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: number
          status?: string | null
          timestamp?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: number
          status?: string | null
          timestamp?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      rasgo_valores: {
        Row: {
          activo: boolean
          created_at: string
          descripcion: string | null
          nombre: string
          orden: number | null
          origen_termino_id: string | null
          rasgo_id: string
          slug: string
          updated_at: string
          valor_id: string
        }
        Insert: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          nombre: string
          orden?: number | null
          origen_termino_id?: string | null
          rasgo_id: string
          slug: string
          updated_at?: string
          valor_id?: string
        }
        Update: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          nombre?: string
          orden?: number | null
          origen_termino_id?: string | null
          rasgo_id?: string
          slug?: string
          updated_at?: string
          valor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "rasgo_valores_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "rasgo_valores_rasgo_id_fkey"
            columns: ["rasgo_id"]
            isOneToOne: false
            referencedRelation: "rasgos_metricos"
            referencedColumns: ["rasgo_id"]
          },
        ]
      }
      rasgos_metricos: {
        Row: {
          activo: boolean
          created_at: string
          demarcable: boolean
          descripcion: string | null
          estado_revision: string
          nombre: string
          observabilidad: string
          rasgo_id: string
          slug: string
          tipo_valor: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          created_at?: string
          demarcable?: boolean
          descripcion?: string | null
          estado_revision?: string
          nombre: string
          observabilidad?: string
          rasgo_id?: string
          slug: string
          tipo_valor?: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          created_at?: string
          demarcable?: boolean
          descripcion?: string | null
          estado_revision?: string
          nombre?: string
          observabilidad?: string
          rasgo_id?: string
          slug?: string
          tipo_valor?: string
          updated_at?: string
        }
        Relationships: []
      }
      realizaciones_editor_metrico: {
        Row: {
          created_at: string
          etiqueta: string | null
          observaciones: string | null
          orden: number
          realizacion_padre_id: string | null
          realizacion_prueba_id: string
          seccion_id: string | null
          secuencia_prueba_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          created_at?: string
          etiqueta?: string | null
          observaciones?: string | null
          orden: number
          realizacion_padre_id?: string | null
          realizacion_prueba_id: string
          seccion_id?: string | null
          secuencia_prueba_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          created_at?: string
          etiqueta?: string | null
          observaciones?: string | null
          orden?: number
          realizacion_padre_id?: string | null
          realizacion_prueba_id?: string
          seccion_id?: string | null
          secuencia_prueba_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "realizaciones_editor_metrico_realizacion_padre_id_fkey"
            columns: ["realizacion_padre_id"]
            isOneToOne: false
            referencedRelation: "realizaciones_editor_metrico"
            referencedColumns: ["realizacion_prueba_id"]
          },
          {
            foreignKeyName: "realizaciones_editor_metrico_seccion_id_fkey"
            columns: ["seccion_id"]
            isOneToOne: false
            referencedRelation: "estructuras_secciones"
            referencedColumns: ["seccion_id"]
          },
          {
            foreignKeyName: "realizaciones_editor_metrico_secuencia_prueba_id_fkey"
            columns: ["secuencia_prueba_id"]
            isOneToOne: false
            referencedRelation: "secuencias_editor_metrico"
            referencedColumns: ["secuencia_prueba_id"]
          },
        ]
      }
      repeticion_posiciones: {
        Row: {
          bloque: number
          bloque_origen: number | null
          condicion: string | null
          created_at: string
          etiqueta_funcional: string | null
          posicion: number
          posicion_id: string
          posicion_origen: number | null
          repeticion_id: string
          updated_at: string
        }
        Insert: {
          bloque?: number
          bloque_origen?: number | null
          condicion?: string | null
          created_at?: string
          etiqueta_funcional?: string | null
          posicion: number
          posicion_id?: string
          posicion_origen?: number | null
          repeticion_id: string
          updated_at?: string
        }
        Update: {
          bloque?: number
          bloque_origen?: number | null
          condicion?: string | null
          created_at?: string
          etiqueta_funcional?: string | null
          posicion?: number
          posicion_id?: string
          posicion_origen?: number | null
          repeticion_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "repeticion_posiciones_repeticion_id_fkey"
            columns: ["repeticion_id"]
            isOneToOne: false
            referencedRelation: "repeticiones_metricas"
            referencedColumns: ["repeticion_id"]
          },
        ]
      }
      repeticiones_metricas: {
        Row: {
          ambito: string
          arquitectura_id: string
          created_at: string
          descripcion: string | null
          estado_revision: string
          fijeza: string
          regla: string
          repeticion_id: string
          tipo: string
          updated_at: string
        }
        Insert: {
          ambito?: string
          arquitectura_id: string
          created_at?: string
          descripcion?: string | null
          estado_revision?: string
          fijeza?: string
          regla: string
          repeticion_id?: string
          tipo: string
          updated_at?: string
        }
        Update: {
          ambito?: string
          arquitectura_id?: string
          created_at?: string
          descripcion?: string | null
          estado_revision?: string
          fijeza?: string
          regla?: string
          repeticion_id?: string
          tipo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "repeticiones_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "repeticiones_metricas_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
        ]
      }
      secciones_publicas: {
        Row: {
          activa: boolean
          descripcion: string | null
          label: string
          orden: number
          scope_minimo: string
          seccion_id: string
          updated_at: string
        }
        Insert: {
          activa?: boolean
          descripcion?: string | null
          label: string
          orden?: number
          scope_minimo?: string
          seccion_id: string
          updated_at?: string
        }
        Update: {
          activa?: boolean
          descripcion?: string | null
          label?: string
          orden?: number
          scope_minimo?: string
          seccion_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      secuencias_caracterizaciones_rango: {
        Row: {
          caracterizacion_rango_id: string
          created_at: string
          observaciones: string | null
          secuencia_id: string
          tipo_caracterizacion_rango_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          caracterizacion_rango_id?: string
          created_at?: string
          observaciones?: string | null
          secuencia_id: string
          tipo_caracterizacion_rango_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          caracterizacion_rango_id?: string
          created_at?: string
          observaciones?: string | null
          secuencia_id?: string
          tipo_caracterizacion_rango_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "secuencias_caracterizaciones_rango_secuencia_id_fkey"
            columns: ["secuencia_id"]
            isOneToOne: false
            referencedRelation: "secuencias_metricas"
            referencedColumns: ["secuencia_id"]
          },
          {
            foreignKeyName: "secuencias_caracterizaciones_rango_tipo_caracterizacion_rango_i"
            columns: ["tipo_caracterizacion_rango_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      secuencias_editor_metrico: {
        Row: {
          arquitectura_id: string | null
          created_at: string
          created_by: string
          escenario_id: string
          forma_id: string
          observaciones: string | null
          orden: number
          secuencia_prueba_id: string
          updated_at: string
          updated_by: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          arquitectura_id?: string | null
          created_at?: string
          created_by?: string
          escenario_id: string
          forma_id: string
          observaciones?: string | null
          orden?: number
          secuencia_prueba_id?: string
          updated_at?: string
          updated_by?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          arquitectura_id?: string | null
          created_at?: string
          created_by?: string
          escenario_id?: string
          forma_id?: string
          observaciones?: string | null
          orden?: number
          secuencia_prueba_id?: string
          updated_at?: string
          updated_by?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "secuencias_editor_metrico_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "secuencias_editor_metrico_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "secuencias_editor_metrico_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "secuencias_editor_metrico_escenario_id_fkey"
            columns: ["escenario_id"]
            isOneToOne: false
            referencedRelation: "escenarios_editor_metrico"
            referencedColumns: ["escenario_id"]
          },
          {
            foreignKeyName: "secuencias_editor_metrico_forma_id_fkey"
            columns: ["forma_id"]
            isOneToOne: false
            referencedRelation: "formas_metricas"
            referencedColumns: ["forma_id"]
          },
          {
            foreignKeyName: "secuencias_editor_metrico_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      secuencias_metricas: {
        Row: {
          created_at: string
          estrofa_tipo_id: string | null
          evocacion_metrica: boolean | null
          evocacion_metrica_texto: string | null
          inaugura_espacio: boolean | null
          intervencion_figuras_donaire: string | null
          intervencion_personajes_femeninos: string | null
          intervencion_personajes_sobrenaturales: string | null
          n_versos: number
          obra_id: string
          secuencia_id: string
          sinopsis: string | null
          updated_at: string
          v_fin: number
          v_ini: number
          versos_partidos: boolean | null
        }
        Insert: {
          created_at?: string
          estrofa_tipo_id?: string | null
          evocacion_metrica?: boolean | null
          evocacion_metrica_texto?: string | null
          inaugura_espacio?: boolean | null
          intervencion_figuras_donaire?: string | null
          intervencion_personajes_femeninos?: string | null
          intervencion_personajes_sobrenaturales?: string | null
          n_versos: number
          obra_id: string
          secuencia_id?: string
          sinopsis?: string | null
          updated_at?: string
          v_fin: number
          v_ini: number
          versos_partidos?: boolean | null
        }
        Update: {
          created_at?: string
          estrofa_tipo_id?: string | null
          evocacion_metrica?: boolean | null
          evocacion_metrica_texto?: string | null
          inaugura_espacio?: boolean | null
          intervencion_figuras_donaire?: string | null
          intervencion_personajes_femeninos?: string | null
          intervencion_personajes_sobrenaturales?: string | null
          n_versos?: number
          obra_id?: string
          secuencia_id?: string
          sinopsis?: string | null
          updated_at?: string
          v_fin?: number
          v_ini?: number
          versos_partidos?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "secuencias_metricas_estrofa_tipo_id_fkey"
            columns: ["estrofa_tipo_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "secuencias_metricas_obra_id_fkey"
            columns: ["obra_id"]
            isOneToOne: false
            referencedRelation: "obras"
            referencedColumns: ["obra_id"]
          },
        ]
      }
      secuencias_subtipos_estrofa: {
        Row: {
          created_at: string
          secuencia_id: string
          subtipo_estrofa_id: string
          subtipo_secuencia_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          created_at?: string
          secuencia_id: string
          subtipo_estrofa_id: string
          subtipo_secuencia_id?: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          created_at?: string
          secuencia_id?: string
          subtipo_estrofa_id?: string
          subtipo_secuencia_id?: string
          updated_at?: string
          v_fin?: number
          v_ini?: number
        }
        Relationships: [
          {
            foreignKeyName: "secuencias_subtipos_estrofa_secuencia_id_fkey"
            columns: ["secuencia_id"]
            isOneToOne: false
            referencedRelation: "secuencias_metricas"
            referencedColumns: ["secuencia_id"]
          },
          {
            foreignKeyName: "secuencias_subtipos_estrofa_subtipo_estrofa_id_fkey"
            columns: ["subtipo_estrofa_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      tradiciones_metricas: {
        Row: {
          activo: boolean
          ambito_geografico: string | null
          created_at: string
          created_by: string | null
          descripcion: string | null
          estado_revision: string
          nombre: string
          orden: number | null
          periodo_desde: number | null
          periodo_hasta: number | null
          slug: string
          tradicion_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          activo?: boolean
          ambito_geografico?: string | null
          created_at?: string
          created_by?: string | null
          descripcion?: string | null
          estado_revision?: string
          nombre: string
          orden?: number | null
          periodo_desde?: number | null
          periodo_hasta?: number | null
          slug: string
          tradicion_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          activo?: boolean
          ambito_geografico?: string | null
          created_at?: string
          created_by?: string | null
          descripcion?: string | null
          estado_revision?: string
          nombre?: string
          orden?: number | null
          periodo_desde?: number | null
          periodo_hasta?: number | null
          slug?: string
          tradicion_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tradiciones_metricas_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "tradiciones_metricas_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "editores"
            referencedColumns: ["user_id"]
          },
        ]
      }
      variedades_arquitectura: {
        Row: {
          activo: boolean
          arquitectura_id: string
          created_at: string
          descripcion: string | null
          esquema_metrico_id: string
          esquema_rima_id: string
          estado_revision: string
          nombre: string
          orden: number | null
          origen_termino_id: string | null
          preferente: boolean
          slug: string
          updated_at: string
          variedad_id: string
        }
        Insert: {
          activo?: boolean
          arquitectura_id: string
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id: string
          esquema_rima_id: string
          estado_revision?: string
          nombre: string
          orden?: number | null
          origen_termino_id?: string | null
          preferente?: boolean
          slug: string
          updated_at?: string
          variedad_id?: string
        }
        Update: {
          activo?: boolean
          arquitectura_id?: string
          created_at?: string
          descripcion?: string | null
          esquema_metrico_id?: string
          esquema_rima_id?: string
          estado_revision?: string
          nombre?: string
          orden?: number | null
          origen_termino_id?: string | null
          preferente?: boolean
          slug?: string
          updated_at?: string
          variedad_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "variedades_arquitectura_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_forma"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "variedades_arquitectura_arquitectura_id_fkey"
            columns: ["arquitectura_id"]
            isOneToOne: false
            referencedRelation: "arquitecturas_reglas_longitud"
            referencedColumns: ["arquitectura_id"]
          },
          {
            foreignKeyName: "variedades_arquitectura_esquema_metrico_id_fkey"
            columns: ["esquema_metrico_id"]
            isOneToOne: false
            referencedRelation: "esquemas_metricos"
            referencedColumns: ["esquema_metrico_id"]
          },
          {
            foreignKeyName: "variedades_arquitectura_esquema_rima_id_fkey"
            columns: ["esquema_rima_id"]
            isOneToOne: false
            referencedRelation: "esquemas_rima"
            referencedColumns: ["esquema_rima_id"]
          },
          {
            foreignKeyName: "variedades_arquitectura_origen_termino_id_fkey"
            columns: ["origen_termino_id"]
            isOneToOne: true
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
      vocabularios: {
        Row: {
          activo: boolean | null
          arte_metrico: string | null
          bibliografia: string | null
          categoria: string
          created_at: string
          definicion: string | null
          ejemplo: string | null
          equivalencias: string[] | null
          etiqueta: string | null
          naturaleza_estrofica_id: string | null
          nivel: number | null
          numero_silabas: number | null
          orden: number | null
          patron_especifico: string | null
          tamanio_unidad_estrofica: number | null
          termino: string
          termino_id: string
          termino_padre_id: string | null
          tipo_forma: string | null
          tipo_rima_id: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean | null
          arte_metrico?: string | null
          bibliografia?: string | null
          categoria: string
          created_at?: string
          definicion?: string | null
          ejemplo?: string | null
          equivalencias?: string[] | null
          etiqueta?: string | null
          naturaleza_estrofica_id?: string | null
          nivel?: number | null
          numero_silabas?: number | null
          orden?: number | null
          patron_especifico?: string | null
          tamanio_unidad_estrofica?: number | null
          termino: string
          termino_id?: string
          termino_padre_id?: string | null
          tipo_forma?: string | null
          tipo_rima_id?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean | null
          arte_metrico?: string | null
          bibliografia?: string | null
          categoria?: string
          created_at?: string
          definicion?: string | null
          ejemplo?: string | null
          equivalencias?: string[] | null
          etiqueta?: string | null
          naturaleza_estrofica_id?: string | null
          nivel?: number | null
          numero_silabas?: number | null
          orden?: number | null
          patron_especifico?: string | null
          tamanio_unidad_estrofica?: number | null
          termino?: string
          termino_id?: string
          termino_padre_id?: string | null
          tipo_forma?: string | null
          tipo_rima_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vocabularios_naturaleza_estrofica_id_fkey"
            columns: ["naturaleza_estrofica_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "vocabularios_termino_padre_id_fkey"
            columns: ["termino_padre_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
          {
            foreignKeyName: "vocabularios_tipo_rima_id_fkey"
            columns: ["tipo_rima_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
    }
    Views: {
      arquitecturas_reglas_longitud: {
        Row: {
          arquitectura_id: string | null
          arquitectura_nombre: string | null
          explicacion: string | null
          minimo_versos: number | null
          modulo_versos: number | null
          origen: string | null
          residuo_versos: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      auth_is_admin_or_ip: { Args: never; Returns: boolean }
      can_view_obra_ficha_publica: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: boolean
      }
      get_autor_publico: { Args: { p_slug: string }; Returns: Json }
      get_autores_listado_publico: { Args: never; Returns: Json }
      get_obra_comentarios_publicos: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: Json
      }
      get_obra_ficha_publica: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: Json
      }
      get_obra_ficha_publica_base_without_slugs: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: Json
      }
      guardar_revision_migracion_metrica: {
        Args: { p_cambios: Json }
        Returns: number
      }
      guardar_secuencia_editor_metrico_prueba: {
        Args: { p_datos: Json }
        Returns: string
      }
      marcar_arquitectura_metrica_principal: {
        Args: { p_arquitectura_id: string }
        Returns: undefined
      }
      mark_public_data_dirty_for_autor: {
        Args: { p_autor_id: string }
        Returns: undefined
      }
      mark_public_data_dirty_for_obra: {
        Args: { p_obra_id: string }
        Returns: undefined
      }
      metadrama_slugify: { Args: { value: string }; Returns: string }
      next_autores_slug: {
        Args: { base: string; current_autor_id: string }
        Returns: string
      }
      next_obras_slug: {
        Args: { base: string; current_obra_id: string }
        Returns: string
      }
      numero_efectivo_from_perfil: { Args: { p_perfil: Json }; Returns: number }
      obra_publica_visible: { Args: { p_obra_id: string }; Returns: boolean }
      obra_publicada_asignada: {
        Args: { p_obra_id: string; p_user: string }
        Returns: boolean
      }
      perfil_formas_hijos_rango: {
        Args: { p_obra_id: string; p_v_fin?: number; p_v_ini?: number }
        Returns: Json
      }
      perfil_formas_rango: {
        Args: { p_obra_id: string; p_v_fin: number; p_v_ini: number }
        Returns: Json
      }
      perfil_metrico_unidades: {
        Args: never
        Returns: {
          autor_id: string
          jornada_id: string
          jornada_v_fin: number
          jornada_v_ini: number
          obra_id: string
          scope: string
        }[]
      }
      publicar_demarcador_version: {
        Args: { p_version_id: string }
        Returns: {
          artefacto: Json
          catalogo_revision: number | null
          esquema: number
          estado: string
          fuente_actualizada_en: string | null
          fuente_tipo: string
          generado_en: string
          generado_por: string | null
          huella_fuente: string
          numero: number
          publicado_en: string | null
          publicado_por: string | null
          total_familias: number
          total_familias_variantes: number
          total_variantes_demarcables: number
          updated_at: string
          version_id: string
        }
        SetofOptions: {
          from: "*"
          to: "demarcador_versiones"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      recompute_all: { Args: never; Returns: undefined }
      recompute_autor_resumen: {
        Args: { p_autor_id: string }
        Returns: undefined
      }
      recompute_obra_resumen: {
        Args: { p_obra_id: string }
        Returns: undefined
      }
      recompute_obra_resumen_estructura: {
        Args: { p_obra_id: string }
        Returns: undefined
      }
      recompute_obra_resumen_metricas: {
        Args: { p_obra_id: string }
        Returns: undefined
      }
      recompute_obra_y_autores: {
        Args: { p_obra_id: string }
        Returns: undefined
      }
      recompute_vocabulario_arte_metrico: {
        Args: { p_estrofa_tipo_id: string }
        Returns: undefined
      }
      regla_longitud_arquitectura_metrica: {
        Args: { p_arquitectura_id: string }
        Returns: {
          explicacion: string
          minimo_versos: number
          modulo_versos: number
          origen: string
          residuo_versos: number
        }[]
      }
      resolve_obra_id_for_atribucion: {
        Args: { p_atribucion_id: string }
        Returns: string
      }
      resolve_obra_id_for_grupo_atribucion: {
        Args: { p_jornada_id: string; p_obra_id: string }
        Returns: string
      }
      validar_estructura_secuencia_editor_metrico: {
        Args: { p_secuencia_id: string }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
