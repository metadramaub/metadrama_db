/** Cómo se colorea un gráfico: en color, o en grises para una publicación impresa. */
export type Paleta = 'color' | 'grises';

/**
 * Lo que se elige en el modal antes de descargar.
 *
 * Es un objeto y no un argumento suelto porque va a crecer: cada opción nueva —el idioma, un
 * tamaño de columna— entra aquí y la recibe cada gráfico sin tocar la firma de ninguno.
 */
export type OpcionesFigura = {
	paleta: Paleta;
};

/** Cómo se pinta una muestra en la leyenda. */
export type MuestraLeyenda = 'bloque' | 'linea' | 'linea-discontinua';

export type ItemLeyenda = {
	etiqueta: string;
	color: string;
	muestra?: MuestraLeyenda;
};

/** Un gráfico que se puede descargar: qué es y qué admite. */
export type FiguraDescargable = {
	/** Título de la figura, el que lleva el archivo arriba. */
	titulo: string;
	/** Sufijo del nombre de archivo, tras el slug de la obra. */
	archivo: string;
	/**
	 * Si se puede imprimir en blanco y negro sin perder lo que dice.
	 *
	 * **No todos pueden**: en el código de barras y en el perfil lo único que distingue una forma
	 * de otra es su color, y en grises doce formas son cinco manchas. Donde el nombre va escrito
	 * al lado de lo que nombra, sí.
	 */
	admiteGrises: boolean;
	/** La leyenda que la figura necesita fuera del gráfico, si necesita alguna. */
	leyenda?: (opciones: OpcionesFigura) => ItemLeyenda[];
};

/** De dónde sale una figura: la obra, su ficha y quién la anotó. */
export type ProcedenciaFigura = {
	obraTitulo: string;
	obraSlug: string;
	/** El editor de la ficha, que es quien firma el análisis. */
	autorFicha: string | null;
	/** Año de la versión de la ficha: el de su última actualización. */
	anio: string;
	/**
	 * Cuándo se modificó la ficha por última vez. Va en el pie como «datos a…»: con ella, quien
	 * tenga delante una copia del gráfico sabe con qué versión de la ficha compararla.
	 */
	actualizada?: string | null;
};
