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

export interface ObraDatosPatch {
	titulo: string;
	variantes_titulo: string[];
	genero_id: string;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	fuente_fecha: string | null;
	fecha_inicio_metadrama: number | null;
	fecha_fin_metadrama: number | null;
	edicion: string;
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
	estado_revision: string;
	certeza_editor: string;
	observaciones: string | null;
	notas_internas: string | null;
}

export interface CambioEstadoInput {
	estado: string;
	comentario?: string;
}

export interface ComentarioInput {
	comentario: string;
}

export interface SecuenciaWithMetros extends Tables<'secuencias_metricas'> {
	metros: Tables<'vocabularios'>[];
}
