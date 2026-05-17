import { COMENTARIO_SECCIONES, type ComentarioSeccion } from '$lib/types/obra.types';

export type CommentTargetContext = {
	comentario_id?: string | null;
	seccion?: ComentarioSeccion | string | null;
	secuencia_id?: string | null;
	jornada_id?: string | null;
	cuadro_id?: string | null;
};

const validCommentSections = new Set<string>(COMENTARIO_SECCIONES);

function normalizeSection(section: string | null | undefined): ComentarioSeccion | null {
	if (!section) return null;
	const normalized = section.trim().toLowerCase();
	if (!validCommentSections.has(normalized)) return null;
	return normalized as ComentarioSeccion;
}

export function buildCommentTargetUrl(obraId: string, comment: CommentTargetContext): string {
	const params = new URLSearchParams();
	const section = normalizeSection(comment.seccion);

	if (comment.secuencia_id) {
		params.set('tab', 'secuencias');
		params.set('focusSecuenciaId', comment.secuencia_id);
	} else if (comment.jornada_id) {
		params.set('tab', 'estructura');
		params.set('focusJornadaId', comment.jornada_id);
	} else if (comment.cuadro_id) {
		params.set('tab', 'estructura');
		params.set('focusCuadroId', comment.cuadro_id);
	} else if (section) {
		params.set('tab', section);
	} else {
		params.set('tab', 'revision');
	}

	if (comment.comentario_id) {
		params.set('focusComentarioId', comment.comentario_id);
	}

	return `/dashboard/obras/${encodeURIComponent(obraId)}?${params.toString()}`;
}
