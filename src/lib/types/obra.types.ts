import type { Tables } from '$lib/types/database.types';

export interface EditorProfile {
	userId: string;
	nombreCompleto: string;
	roleId: string;
	roleTerm: string;
	activo: boolean;
}

export interface DashboardObraCard {
	obraId: string;
	titulo: string;
	estadoTerm: string;
	updatedAt: string | null;
	progreso: number;
}

export interface ObraAccessFlags {
	canRead: boolean;
	canEditContent: boolean;
	canComment: boolean;
	canReview: boolean;
	canChangeState: boolean;
	canManageReviewers: boolean;
	canToggleVisibility: boolean;
	canDeleteObra: boolean;
}

export interface ObraDatosPatch {
	titulo: string | null;
	variantes_titulo: string[];
	genero_id: string | null;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	fuente_fecha: string | null;
	fecha_inicio_metadrama: number | null;
	fecha_fin_metadrama: number | null;
	edicion: string | null;
}

export interface JornadaInput {
	jornada_num: number;
	v_ini: number;
	v_fin: number;
}

export interface CuadroInput {
	jornada_id: string;
	cuadro_num: number;
	v_ini: number;
	v_fin: number;
	certeza_editor: string;
}

export interface SecuenciaInput {
	v_ini: number;
	v_fin: number;
	estrofa_tipo_id: string;
	inaugura_espacio: boolean;
	versos_partidos: boolean;
	evocacion_metrica: boolean;
	evocacion_metrica_texto: string | null;
	intervencion_personajes_femeninos: 'sin_intervencion' | 'exclusiva' | 'compartida';
	intervencion_figuras_donaire: 'sin_intervencion' | 'exclusiva' | 'compartida';
	intervencion_personajes_sobrenaturales: 'sin_intervencion' | 'exclusiva' | 'compartida';
	certeza_editor: string;
	sinopsis: string | null;
}

export interface SecuenciaCaracterizacionRangoInput {
	tipo_caracterizacion_rango_id: string;
	v_ini: number;
	v_fin: number;
	observaciones: string | null;
}

export interface SecuenciaSubtipoEstrofaInput {
	subtipo_estrofa_id: string;
	v_ini: number;
	v_fin: number;
}

export interface CambioEstadoInput {
	estado: string;
	comentario?: string;
}

export const COMENTARIO_SECCIONES = [
	'datos',
	'estructura',
	'secuencias',
	'autoria',
	'observaciones',
	'revision'
] as const;

export type ComentarioSeccion = (typeof COMENTARIO_SECCIONES)[number];

export interface ComentarioInput {
	comentario: string;
	tipo_comentario?:
		| 'general'
		| 'revision'
		| 'tecnico'
		| 'estado'
		| 'nota_propia'
		| 'observacion_publica';
	seccion?: ComentarioSeccion;
	secuencia_id?: string;
	jornada_id?: string;
	cuadro_id?: string;
}

export interface ComentarioPatchInput {
	comentario: string;
	tipo_comentario?: 'general' | 'revision' | 'tecnico' | 'nota_propia' | 'observacion_publica';
}

export interface ComentarioPublicacionPatchInput {
	visible_publico: boolean;
}

export interface ComentarioListQueryInput {
	seccion?: ComentarioSeccion;
	secuencia_id?: string;
	jornada_id?: string;
	cuadro_id?: string;
	limit?: number;
	offset?: number;
}

export interface ComentarioListItem extends Tables<'comentarios_internos'> {
	nombre_editor?: string;
	tipo_comentario_term?:
		| 'general'
		| 'revision'
		| 'tecnico'
		| 'estado'
		| 'nota_propia'
		| 'observacion_publica';
	contexto_label?: string | null;
	secuencia_estrofa_term?: string | null;
	can_edit?: boolean;
	can_delete?: boolean;
	can_publish?: boolean;
	locked?: boolean;
}

export interface AutoriaCatalogItem {
	termino_id: string;
	termino: string;
	etiqueta?: string | null;
}

export interface AutoriaAtribucionAutorPayload {
	autor_id: string;
	orden: number | null;
}

export type AutoriaComposicionTerm = 'individual' | 'colaborada' | 'desconocida';

export interface AutoriaEvidenciaPayload {
	atribucion_evidencia_id: string | null;
	tipo_atribucion_id: string;
	tipo_atribucion_term: string | null;
	fuente_autoria: string | null;
}

export interface AutoriaPropuestaPayload {
	atribucion_id: string;
	grupo_atribucion_id: string;
	composicion_autoria_id: string;
	composicion_autoria_term: AutoriaComposicionTerm;
	perfil_metrico?: boolean;
	autores: AutoriaAtribucionAutorPayload[];
	evidencias: AutoriaEvidenciaPayload[];
}

export interface GrupoAtribucionPayload {
	grupo_atribucion_id: string;
	obra_id: string | null;
	jornada_id: string | null;
	jornada_num: number | null;
	propuestas: AutoriaPropuestaPayload[];
}

export interface AutoriaApiPayload {
	obra: {
		obra_id: string;
		total_versos: number | null;
	};
	autores: Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>>;
	jornadas: Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>;
	catalogos: {
		tipos: AutoriaCatalogItem[];
		composiciones: AutoriaCatalogItem[];
	};
	grupos: GrupoAtribucionPayload[];
	loaded_at: string;
}

export interface ObservacionesInput {
	observaciones: string | null;
	bibliografia: string | null;
}

export interface VisibilidadInput {
	visible_publico: boolean;
}

export interface ObraCreateInput {
	titulo: string;
	editor_asignado: string;
	genero_id?: string | null;
}

export interface AssignmentEditorOption {
	user_id: string;
	nombre_completo: string;
	email: string | null;
}

export interface AssignmentReviewerCandidate extends AssignmentEditorOption {
	selected: boolean;
}

export interface AssignedReviewerSummary {
	revisor_id: string;
	nombre_completo: string;
	email: string | null;
	created_at: string | null;
}

export interface ObraAssignmentsInput {
	editor_asignado?: string;
	reviewer_ids: string[];
}

export interface ObraReviewersInput {
	reviewer_ids: string[];
}

export interface ObraAssignmentsResponse {
	canManage: boolean;
	editor_asignado: string | null;
	editorOptions: AssignmentEditorOption[];
	assigned: AssignedReviewerSummary[];
	candidates: AssignmentReviewerCandidate[];
}

export interface VocabularioCreateInput {
	categoria: string;
	termino: string;
	termino_padre_id?: string | null;
	nivel?: number | null;
	orden?: number | null;
	definicion?: string | null;
	ejemplo?: string | null;
	bibliografia?: string | null;
	equivalencias?: string[] | null;
	patron_especifico?: string | null;
	tipo_forma?: 'forma_espanola' | 'forma_italiana' | null;
	tipo_rima?: 'asonante' | 'consonante' | 'sin_rima' | 'mixta' | null;
	naturaleza_estrofica?:
		| 'tirada_continua'
		| 'estrofa_cerrada'
		| 'forma_fija'
		| 'forma_compuesta'
		| 'forma_irregular'
		| null;
	tamanio_unidad_estrofica?: number | null;
	numero_silabas?: number | null;
	metro_ids?: string[] | null;
	activo?: boolean;
}

export interface VocabularioPatchInput {
	termino?: string;
	termino_padre_id?: string | null;
	nivel?: number | null;
	orden?: number | null;
	definicion?: string | null;
	ejemplo?: string | null;
	bibliografia?: string | null;
	equivalencias?: string[] | null;
	patron_especifico?: string | null;
	tipo_forma?: 'forma_espanola' | 'forma_italiana' | null;
	tipo_rima?: 'asonante' | 'consonante' | 'sin_rima' | 'mixta' | null;
	naturaleza_estrofica?:
		| 'tirada_continua'
		| 'estrofa_cerrada'
		| 'forma_fija'
		| 'forma_compuesta'
		| 'forma_irregular'
		| null;
	tamanio_unidad_estrofica?: number | null;
	numero_silabas?: number | null;
	metro_ids?: string[] | null;
	activo?: boolean;
}

export interface VocabularioReorderItemInput {
	termino_id: string;
	termino_padre_id: string | null;
	orden: number;
	nivel: number | null;
}

export interface VocabularioReorderInput {
	categoria: string;
	items: VocabularioReorderItemInput[];
}
