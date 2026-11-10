/** Modelo vigente tras la migración coordinada 20261110200000. */
export function modeloEditorialActivo() {
	return true;
}

export function relacionObras(): 'obras_editoriales' {
	return 'obras_editoriales';
}

/** Metadatos públicos mínimos, con muro de estado/visibilidad y vista previa por obra. */
export function relacionObrasPublicas(): 'obras_consulta_publica' {
	return 'obras_consulta_publica';
}
