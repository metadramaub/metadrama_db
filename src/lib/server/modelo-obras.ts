/** Modelo vigente tras la migración coordinada 20261110200000. */
export function modeloEditorialActivo() {
	return true;
}

export function relacionObras(): 'obras' | 'obras_editoriales' {
	return modeloEditorialActivo() ? 'obras_editoriales' : 'obras';
}

/** Metadatos públicos mínimos, con muro de estado/visibilidad y vista previa por obra. */
export function relacionObrasPublicas(): 'obras' | 'obras_consulta_publica' {
	return modeloEditorialActivo() ? 'obras_consulta_publica' : 'obras';
}
