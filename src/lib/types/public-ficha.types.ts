export interface PublicFichaAutor {
	autor_id: string;
	slug: string;
	nombre_completo: string;
}

export interface PublicFichaAtribucionEvidencia {
	atribucion_evidencia_id: string;
	tipo_atribucion_id: string;
	tipo_atribucion_term: string;
	fuente_autoria: string | null;
}

export interface PublicFichaAtribucionAutoria {
	atribucion_id: string;
	composicion_autoria_id: string;
	composicion_autoria_term: 'individual' | 'colaborada' | 'desconocida';
	autores: PublicFichaAutor[];
	evidencias: PublicFichaAtribucionEvidencia[];
}

export interface PublicFichaGrupoAutoria {
	grupo_atribucion_id: string;
	scope: 'obra' | 'jornada';
	obra_id: string | null;
	jornada_id: string | null;
	jornada_num: number | null;
	nombre: string | null;
	notas: string | null;
	propuestas: PublicFichaAtribucionAutoria[];
}

export interface PublicFichaJornada {
	jornada_id: string;
	jornada_num: number;
	v_ini: number;
	v_fin: number;
}

export interface PublicFichaCuadro {
	cuadro_id: string;
	jornada_id: string;
	cuadro_num: number;
	v_ini: number;
	v_fin: number;
}

export interface PublicFichaCaracterizacionRango {
	caracterizacion_rango_id: string;
	tipo_caracterizacion_rango_id: string;
	tipo_caracterizacion_rango_term: string;
	v_ini: number;
	v_fin: number;
	observaciones: string | null;
}

export interface PublicFichaSubtipoEstrofa {
	subtipo_secuencia_id: string;
	subtipo_estrofa_id: string;
	subtipo_estrofa_term: string;
	v_ini: number;
	v_fin: number;
}

export interface PublicFichaSecuencia {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos: number;
	estrofa_tipo_id: string | null;
	estrofa_tipo_term: string;
	estrofa_forma_term: string;
	/** Slug crudo de la forma raíz (clave estable de color, sin etiqueta). */
	estrofa_forma_slug: string | null;
	estrofa_tipo_forma: string | null;
	inaugura_espacio: boolean | null;
	versos_partidos: boolean;
	evocacion_metrica: boolean;
	evocacion_metrica_texto: string | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
	sinopsis: string | null;
	jornada_id: string | null;
	jornada_num: number | null;
	cuadro_id: string | null;
	cuadro_num: number | null;
	caracterizaciones_rango: PublicFichaCaracterizacionRango[];
	subtipos_estrofa: PublicFichaSubtipoEstrofa[];
}

export interface PublicFichaSinopsisMetricaSecuencia {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos: number | null;
	estrofa_tipo_id: string | null;
	estrofa_tipo_term: string;
	/** Slug crudo de la forma raíz (clave estable de color, sin etiqueta). */
	estrofa_forma_slug: string | null;
	/** tipo_forma de la forma raíz: 'forma_espanola' | 'forma_italiana'. */
	estrofa_tipo_forma: string | null;
	sinopsis: string | null;
}

export interface PublicFichaDistribucionForma {
	forma: string;
	/** Slug crudo de la forma raíz (clave estable de color, sin etiqueta). */
	forma_slug: string | null;
	/** tipo_forma de la forma raíz: 'forma_espanola' | 'forma_italiana'. */
	forma_tipo_forma: string | null;
	versos: number;
	porcentaje: number;
}

export interface PublicFichaComentarioPublico {
	comentario_id: string;
	comentario: string;
	created_at: string | null;
	seccion: string | null;
	secuencia_id: string | null;
	jornada_id: string | null;
	cuadro_id: string | null;
	nombre_editor: string | null;
}

export interface PublicObraFichaPayload {
	obra: {
		obra_id: string;
		slug: string;
		titulo: string;
		variantes_titulo: string[];
		fecha_inicio_trad: number | null;
		fecha_fin_trad: number | null;
		fuente_fecha: string | null;
		genero_term: string | null;
		total_versos: number | null;
		edicion: string | null;
		observaciones: string | null;
		bibliografia: string | null;
		updated_at: string | null;
		autor_ficha_publico: string | null;
		autor_ficha_email_publico: string | null;
		autor_ficha_orcid_publico: string | null;
		estado_term: string | null;
		visible_publico: boolean | null;
	};
	autoria: {
		autores: PublicFichaAutor[];
		grupos: PublicFichaGrupoAutoria[];
	};
	estructura: {
		jornadas: PublicFichaJornada[];
		cuadros: PublicFichaCuadro[];
	};
	metrica: {
		secuencias: PublicFichaSecuencia[];
		distribucion_formas: PublicFichaDistribucionForma[];
	};
	sinopsis_metrica: {
		secuencias: PublicFichaSinopsisMetricaSecuencia[];
	};
	comentarios_publicos: PublicFichaComentarioPublico[];
}

export interface SequenceModalPayload extends PublicFichaSecuencia {}
