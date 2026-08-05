/**
 * Tipos del catálogo público de formas.
 *
 * Son tipos de presentación: describen lo que la página enseña, no cómo está guardado. El
 * servidor los produce desde el catálogo y el componente los pinta, sin que ninguno de los
 * dos dependa del otro.
 */

/** Una entrada del índice. */
export type PublicFormSummary = {
	slug: string;
	nombre: string;
	definicion: string | null;
	/** `forma` o `sin_forma`: los tramos sin forma no son formas comparables. */
	tipoRegistro: string;
	nivelEstructural: string;
	/** `general` o `especifica`; nulo en los tramos sin forma. */
	gradoEspecificacion: string | null;
	arquitecturas: number;
	tradiciones: string[];
	/** Nombres alternativos, para que el buscador los encuentre por ellos. */
	denominaciones: string[];
};

export type PublicScheme = {
	nombre: string;
	notacion: string | null;
	descripcion: string | null;
};

export type PublicSection = {
	nombre: string;
	nota: string | null;
	versosMin: number | null;
	versosMax: number | null;
	repeticionesMin: number | null;
	repeticionesMax: number | null;
	/** Cuando la sección reutiliza el repertorio de otra forma, cuál. */
	reutiliza: string | null;
};

export type PublicChoice = {
	pregunta: string;
	/** `secuencia` o `unidad`: si se responde una vez o en cada unidad. */
	alcance: string;
	seleccionesMin: number;
	seleccionesMax: number;
	opciones: string[];
};

export type PublicTrait = {
	nombre: string;
	valor: string | null;
	modalidad: string | null;
	nota: string | null;
};

export type PublicArchitecture = {
	slug: string;
	nombre: string;
	descripcion: string | null;
	principal: boolean;
	modalidad: string | null;
	unidadMin: number | null;
	unidadMax: number | null;
	esquemasMetricos: PublicScheme[];
	esquemasRima: PublicScheme[];
	secciones: PublicSection[];
	variedades: PublicScheme[];
	preguntas: PublicChoice[];
	rasgos: PublicTrait[];
	denominaciones: string[];
};

/** Lo que una fuente afirma sobre esta forma, con su referencia. */
export type PublicSourceClaim = {
	cita: string;
	resumen: string | null;
	localizador: string | null;
	confianza: string | null;
	/** Sobre qué lo dice: la forma entera o una de sus arquitecturas. */
	sobre: string;
};

export type PublicFormDetail = PublicFormSummary & {
	denominacionesDetalle: { nombre: string; tipo: string }[];
	arquitecturas_: PublicArchitecture[];
	fuentes: PublicSourceClaim[];
};
