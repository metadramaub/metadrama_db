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
	/** Forma métrica base (texto visible, p.ej. la etiqueta de la forma raíz). */
	forma: string;
	/**
	 * Clave estable para el color (slug de la forma raíz). Si se omite, se usa
	 * `forma`. Permite colorear de forma estable aunque cambie la etiqueta.
	 */
	colorKey?: string;
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

/**
 * Una línea del esquema métrico: un pasaje con su forma y lo que se sabe de él.
 *
 * Es la unidad de «esquema métrico de un vistazo», la lista que las ediciones críticas ponen al
 * principio y que aquí sale del dato anotado. `detalle` es lo que distingue una tirada de otra de
 * la misma forma —la asonancia de un romance, el reparto de esquemas de una tirada de redondillas—,
 * y por eso lo compone quien adapta y no este componente.
 */
export interface MetricSchemeEntry {
	id: string;
	v_ini: number;
	v_fin: number;
	n_versos: number;
	forma: string;
	colorKey?: string;
	/** La arquitectura, que es el detalle dentro de la forma. */
	arquitectura?: string | null;
	/** Lo observado en esta tirada, ya redactado: «é-o», «abrazada 46 · cruzada 8». */
	detalle?: string | null;
	jornada?: number | null;
	cuadro?: number | null;
	/** La tirada sigue sonando después del cambio de cuadro. */
	cuadroContinua?: boolean | null;
}

/** Una jornada con sus cuadros, para el esquema de estructura. */
export interface StructureOutlineJornada {
	numero: number;
	v_ini: number;
	v_fin: number;
	cuadros: { numero: number; v_ini: number; v_fin: number }[];
}

/**
 * Una barra del gráfico de evolución: una jornada con lo que hay dentro.
 *
 * El componente no sabe qué es una jornada; recibe una etiqueta y unos valores. Así el mismo
 * gráfico sirve para «por jornadas» en la ficha y para «por obras» en el perfil de autor.
 */
export interface MetricEvolutionSeries {
	etiqueta: string;
	valores: { colorKey: string; versos: number }[];
}

/**
 * Una forma seguida a lo largo de varios momentos, para el gráfico de pendientes.
 *
 * `valores` lleva un número por momento, en el mismo orden. **Un cero es un dato**: quiere decir
 * que la forma no aparece en esa jornada, y que aparezca en la siguiente es de lo que el gráfico
 * viene a informar.
 */
export interface MetricSlopeSeries {
	forma: string;
	colorKey: string;
	valores: (number | null)[];
}

/** Una forma con las tiradas que tiene a lo largo de la obra, para las franjas. */
export interface MetricStripRow {
	forma: string;
	colorKey: string;
	porcentaje: number;
	tiradas: { v_ini: number; v_fin: number }[];
}

/** Una porción de la distribución de formas (para el pie). */
export interface MetricDistributionSlice {
	/** Texto visible de la forma (p.ej. la etiqueta de la forma raíz). */
	forma: string;
	/**
	 * Clave estable para el color (slug de la forma raíz). Si se omite, se usa
	 * `forma`.
	 */
	colorKey?: string;
	versos: number;
	porcentaje: number;
}
