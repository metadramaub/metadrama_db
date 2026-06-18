// Tipos de PRESENTACIÓN para los componentes métricos reutilizables (barcode, pie).
// Deliberadamente genéricos: no dependen de PublicFichaSecuencia ni de ninguna
// página concreta, para poder usarlos en ficha, catálogo y ficha de autor.
// Cada consumidor adapta sus datos a estas formas mínimas.

/** Un segmento métrico dibujable en el código de barras. */
export interface MetricBarSegment {
	/** Identificador único (para keys y para el callback de apertura). */
	id: string;
	v_ini: number;
	v_fin: number;
	/** Forma métrica base, usada para el color. */
	forma: string;
	/** Etiqueta legible (p.ej. el tipo de estrofa) para tooltip/aria. */
	label: string;
	/** Nº de versos, opcional (tooltip). */
	n_versos?: number;
	/** Sub-segmentos opcionales (p.ej. subtipos de estrofa dentro de la secuencia). */
	subsegments?: MetricBarSubsegment[];
}

/** Un sub-segmento dentro de un segmento (p.ej. un subtipo de estrofa). */
export interface MetricBarSubsegment {
	id: string;
	v_ini: number;
	v_fin: number;
	label: string;
}

/** Una porción de la distribución de formas (para el pie). */
export interface MetricDistributionSlice {
	forma: string;
	versos: number;
	porcentaje: number;
}
