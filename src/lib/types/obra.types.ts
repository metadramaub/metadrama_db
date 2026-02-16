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
	descripcion: string | null;
	certeza_editor: string;
}

export interface SecuenciaInput {
	v_ini: number;
	v_fin: number;
	estrofa_tipo_id: string;
	inaugura_espacio: boolean;
	personajes_genero: 'mixto' | 'solo_masculino' | 'solo_femenino';
	personajes_donaire: 'ausente' | 'solo' | 'con_otros';
	personajes_sobrenatural: 'ausente' | 'solo' | 'con_otros';
	certeza_editor: string;
	observaciones: string | null;
}

export interface CambioEstadoInput {
	estado: string;
	comentario?: string;
}

export interface ComentarioInput {
	comentario: string;
	tipo_comentario?: 'general' | 'revision' | 'tecnico' | 'estado';
	secuencia_id?: string;
	jornada_id?: string;
	cuadro_id?: string;
	rango_id?: string;
}

export interface ComentarioPatchInput {
	comentario: string;
	tipo_comentario?: 'general' | 'revision' | 'tecnico';
}

export interface ComentarioListQueryInput {
	secuencia_id?: string;
	jornada_id?: string;
	cuadro_id?: string;
	rango_id?: string;
	limit?: number;
	offset?: number;
}

export interface ComentarioListItem extends Tables<'comentarios_internos'> {
	nombre_editor?: string;
	tipo_comentario_term?: 'general' | 'revision' | 'tecnico' | 'estado';
	contexto_label?: string | null;
	can_edit?: boolean;
	can_delete?: boolean;
	locked?: boolean;
}

export interface AutoriaObraCompletaInput {
	mode: 'obra_completa';
	source_mode: 'obra_completa' | 'por_jornadas' | 'rango_personalizado';
	confirm_mode_change?: boolean;
	confirm_reassign?: boolean;
	url_informe_autoria: string | null;
	autor_ids: string[];
}

export interface AutoriaPorJornadaItemInput {
	jornada_id: string;
	autor_ids: string[];
}

export interface AutoriaPorJornadasInput {
	mode: 'por_jornadas';
	source_mode: 'obra_completa' | 'por_jornadas' | 'rango_personalizado';
	confirm_mode_change?: boolean;
	confirm_reassign?: boolean;
	url_informe_autoria: string | null;
	items: AutoriaPorJornadaItemInput[];
}

export interface AutoriaRangoPersonalizadoItemInput {
	v_ini: number;
	v_fin: number;
	autor_ids: string[];
}

export interface AutoriaRangoPersonalizadoInput {
	mode: 'rango_personalizado';
	source_mode: 'obra_completa' | 'por_jornadas' | 'rango_personalizado';
	confirm_mode_change?: boolean;
	confirm_reassign?: boolean;
	url_informe_autoria: string | null;
	items: AutoriaRangoPersonalizadoItemInput[];
}

export type AutoriaInput =
	| AutoriaObraCompletaInput
	| AutoriaPorJornadasInput
	| AutoriaRangoPersonalizadoInput;

export type AutoriaIntegrityStatus =
	| 'aligned'
	| 'coverage_gap'
	| 'coverage_overlap'
	| 'jornadas_mismatch';

export interface AutoriaIntegrity {
	effective_total_versos: number | null;
	status: AutoriaIntegrityStatus;
	details: string[];
	matches_jornadas_exactly: boolean;
	is_single_full_range: boolean;
	requires_reassign: boolean;
}

export type AutoriaBlockingReason = 'structure_changed' | 'custom_mode_restricted' | null;

export interface AutoriaApiPayload {
	obra: {
		obra_id: string;
		total_versos: number | null;
		autoria: string[] | null;
		url_informe_autoria: string | null;
	};
	rangos: Tables<'rangos'>[];
	rangosAutores: Tables<'rangos_autores'>[];
	autores: Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>>;
	jornadas: Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>;
	mode: 'obra_completa' | 'por_jornadas' | 'rango_personalizado';
	integrity: AutoriaIntegrity;
	can_use_custom_ranges: boolean;
	requires_reassign: boolean;
	blocking_reason: AutoriaBlockingReason;
	default_reassign_mode: 'obra_completa';
	loaded_at: string;
}

export interface AnalisisInput {
	analisis_editor: string | null;
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
