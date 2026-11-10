import { env } from '$env/dynamic/private';

/** Activar solo con la migración coordinada. El despliegue actual conserva su relación. */
export function modeloEditorialActivo() {
	return env.OBRAS_EDITORIALES_V2 === 'true';
}

export function relacionObras(): 'obras' | 'obras_editoriales' {
	return modeloEditorialActivo() ? 'obras_editoriales' : 'obras';
}

/** Metadatos públicos mínimos, con muro de estado/visibilidad y vista previa por obra. */
export function relacionObrasPublicas(): 'obras' | 'obras_consulta_publica' {
	return modeloEditorialActivo() ? 'obras_consulta_publica' : 'obras';
}
