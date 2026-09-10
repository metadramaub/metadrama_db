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

/** Dónde se respondió algo dentro de la realización material de la arquitectura. */
export interface PublicFichaRespuestaMetricaContexto {
	eleccion_id: string;
	realizacion_id: string | null;
	realizacion_padre_id: string | null;
	realizacion_orden: number | null;
	realizacion_v_ini: number | null;
	realizacion_v_fin: number | null;
	/** Sección que la realización materializa; no es la sección tratada por la pregunta. */
	realizacion_seccion_id: string | null;
	realizacion_seccion_nombre: string | null;
	realizacion_seccion_tipo: string | null;
	realizacion_seccion_orden: number | null;
	realizacion_seccion_repeticiones_min: number | null;
	realizacion_seccion_repeticiones_max: number | null;
	realizacion_seccion_arquitectura_referenciada_id: string | null;
	observaciones: string | null;
}

/** Contexto adicional cuando la respuesta trata una sección concreta de la arquitectura. */
export interface PublicFichaRespuestaMetricaSeccion extends PublicFichaRespuestaMetricaContexto {
	seccion_id: string | null;
	seccion_nombre: string | null;
	seccion_orden: number | null;
}

/** Una respuesta de esquema de rima, sin desligarla de su realización ni de su sección. */
export interface PublicFichaEsquemaRima extends PublicFichaRespuestaMetricaSeccion {
	esquema_rima_id: string | null;
	nombre: string | null;
	notacion: string | null;
	posicion_unidad: number | null;
}

/** Un rasgo observado en la tirada: la asonancia del romance, la densidad de rima de la silva. */
export interface PublicFichaRasgo extends PublicFichaRespuestaMetricaSeccion {
	rasgo_slug: string;
	rasgo_nombre: string;
	valor_slug: string;
	valor_nombre: string;
}

/** La medida de los versos tal como se respondió, con cuántas estrofas la llevan. */
export interface PublicFichaMetro extends PublicFichaRespuestaMetricaSeccion {
	metro_id: string;
	metro_slug: string;
	metro_nombre: string;
	posicion_unidad: number | null;
}

/** Una variedad que empareja medida y rima dentro de una arquitectura. */
export interface PublicFichaVariedad extends PublicFichaRespuestaMetricaContexto {
	variedad_id: string;
	variedad_slug: string;
	variedad_nombre: string;
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
	forma_nombre: string;
	/** Slug crudo de la forma raíz (clave estable de color, sin etiqueta). */
	forma_slug: string | null;
	tipo_forma: string | null;
	arquitectura_id: string | null;
	arquitectura_slug: string | null;
	arquitectura_nombre: string;
	nivel_estructural: string | null;
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
	esquemas_rima: PublicFichaEsquemaRima[];
	rasgos: PublicFichaRasgo[];
	metros: PublicFichaMetro[];
	variedades: PublicFichaVariedad[];
	desviaciones: PublicFichaDesviacion[];
}

export interface PublicFichaSinopsisMetricaSecuencia {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos: number | null;
	arquitectura_id: string | null;
	arquitectura_nombre: string;
	forma_nombre: string;
	/** Slug crudo de la forma raíz (clave estable de color, sin etiqueta). */
	forma_slug: string | null;
	/** tipo_forma de la forma raíz: 'forma_espanola' | 'forma_italiana'. */
	tipo_forma: string | null;
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
		autor_ficha_orcid_publico: string | null;
		estado_term: string | null;
		visible_publico: boolean | null;
		/** Lo que la obra declara que no tiene: cierra la pregunta en todas sus secuencias. */
		sin_figuras_donaire: boolean | null;
		sin_personajes_sobrenaturales: boolean | null;
		sin_eventos_sobrenaturales: boolean | null;
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
