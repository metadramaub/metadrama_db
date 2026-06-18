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
          certeza_editor: string
          created_at: string
          cuadro_id: string
          cuadro_num: number
          jornada_id: string
          updated_at: string
          v_fin: number
          v_ini: number
        }
        Insert: {
          certeza_editor: string
          created_at?: string
          cuadro_id?: string
          cuadro_num: number
          jornada_id: string
          updated_at?: string
          v_fin: number
          v_ini: number
        }
        Update: {
          certeza_editor?: string
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
            foreignKeyName: "cuadros_certeza_editor_fkey"
            columns: ["certeza_editor"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
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
      secuencias_metricas: {
        Row: {
          certeza_editor: string
          created_at: string
          estrofa_tipo_id: string | null
          evocacion_metrica: boolean
          evocacion_metrica_texto: string | null
          inaugura_espacio: boolean | null
          intervencion_figuras_donaire: string
          intervencion_personajes_femeninos: string
          intervencion_personajes_sobrenaturales: string
          n_versos: number
          obra_id: string
          secuencia_id: string
          sinopsis: string | null
          updated_at: string
          v_fin: number
          v_ini: number
          versos_partidos: boolean
        }
        Insert: {
          certeza_editor: string
          created_at?: string
          estrofa_tipo_id?: string | null
          evocacion_metrica?: boolean
          evocacion_metrica_texto?: string | null
          inaugura_espacio?: boolean | null
          intervencion_figuras_donaire?: string
          intervencion_personajes_femeninos?: string
          intervencion_personajes_sobrenaturales?: string
          n_versos: number
          obra_id: string
          secuencia_id?: string
          sinopsis?: string | null
          updated_at?: string
          v_fin: number
          v_ini: number
          versos_partidos?: boolean
        }
        Update: {
          certeza_editor?: string
          created_at?: string
          estrofa_tipo_id?: string | null
          evocacion_metrica?: boolean
          evocacion_metrica_texto?: string | null
          inaugura_espacio?: boolean | null
          intervencion_figuras_donaire?: string
          intervencion_personajes_femeninos?: string
          intervencion_personajes_sobrenaturales?: string
          n_versos?: number
          obra_id?: string
          secuencia_id?: string
          sinopsis?: string | null
          updated_at?: string
          v_fin?: number
          v_ini?: number
          versos_partidos?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "secuencias_metricas_certeza_editor_fkey"
            columns: ["certeza_editor"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
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
      vocabularios: {
        Row: {
          activo: boolean | null
          bibliografia: string | null
          categoria: string
          created_at: string
          definicion: string | null
          ejemplo: string | null
          equivalencias: string[] | null
          etiqueta: string | null
          nivel: number | null
          orden: number | null
          patron_especifico: string | null
          termino: string
          termino_id: string
          termino_padre_id: string | null
          tipo_forma: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean | null
          bibliografia?: string | null
          categoria: string
          created_at?: string
          definicion?: string | null
          ejemplo?: string | null
          equivalencias?: string[] | null
          etiqueta?: string | null
          nivel?: number | null
          orden?: number | null
          patron_especifico?: string | null
          termino: string
          termino_id?: string
          termino_padre_id?: string | null
          tipo_forma?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean | null
          bibliografia?: string | null
          categoria?: string
          created_at?: string
          definicion?: string | null
          ejemplo?: string | null
          equivalencias?: string[] | null
          etiqueta?: string | null
          nivel?: number | null
          orden?: number | null
          patron_especifico?: string | null
          termino?: string
          termino_id?: string
          termino_padre_id?: string | null
          tipo_forma?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vocabularios_termino_padre_id_fkey"
            columns: ["termino_padre_id"]
            isOneToOne: false
            referencedRelation: "vocabularios"
            referencedColumns: ["termino_id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      auth_is_admin_or_ip: { Args: never; Returns: boolean }
      get_obra_comentarios_publicos: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: Json
      }
      get_obra_ficha_publica: {
        Args: { p_include_hidden?: boolean; p_obra_id: string }
        Returns: Json
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
