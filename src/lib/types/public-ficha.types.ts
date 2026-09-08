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

/**
 * Un esquema de rima de la tirada, con cuántas estrofas lo llevan.
 *
 * No es un rango: el esquema se responde una vez por estrofa, así que lo que dice algo es el
 * reparto —«abrazada 64, cruzada 14»— y no dónde cae cada una.
 */
export interface PublicFichaSubtipoEstrofa {
	subtipo_estrofa_id: string;
	subtipo_estrofa_term: string;
	notacion: string | null;
	unidades: number;
}

/** Un rasgo observado en la tirada: la asonancia del romance, la densidad de rima de la silva. */
export interface PublicFichaRasgo {
	rasgo_slug: string;
	rasgo_term: string;
	valor_slug: string;
	valor_term: string;
}

/** La medida de los versos tal como se respondió, con cuántas estrofas la llevan. */
export interface PublicFichaMetro {
	metro_slug: string;
	metro_term: string;
	unidades: number;
}

/** Lo que se aparta de la norma: la laguna, el verso corto, la rima fuera del repertorio. */
export interface PublicFichaDesviacion {
	dimension: string;
	relacion_norma: string;
	v_ini: number;
	v_fin: number;
	observaciones: string | null;
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
	versos_partidos: boolean | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
	evento_sobrenatural: boolean | null;
	sinopsis: string | null;
	jornada_id: string | null;
	jornada_num: number | null;
	cuadro_id: string | null;
	cuadro_num: number | null;
	/** La tirada sigue sonando después del cambio de cuadro. */
	cuadro_continua: boolean | null;
	caracterizaciones_rango: PublicFichaCaracterizacionRango[];
	subtipos_estrofa: PublicFichaSubtipoEstrofa[];
	rasgos: PublicFichaRasgo[];
	metros: PublicFichaMetro[];
	desviaciones: PublicFichaDesviacion[];
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
