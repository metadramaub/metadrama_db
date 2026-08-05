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
	/** Los regímenes de rima que admite alguna de sus arquitecturas. */
	tiposRima: string[];
	/** Nombres alternativos, para que el buscador los encuentre por ellos. */
	denominaciones: string[];
};

export type PublicScheme = {
	nombre: string;
	notacion: string | null;
	descripcion: string | null;
};

/**
 * Qué rima se arrastra de un bloque a otro.
 *
 * Es lo que la notación no puede decir: `[aA]…` y `[-a]…` tienen la misma forma, pero la
 * silva estrena rima en cada pareado y el romance mantiene una sola asonancia. Lo que las
 * separa es este enlace, o su ausencia.
 */
export type PublicRhymeLink = {
	/** Verso del que sale la rima, dentro de su bloque. */
	desde: number;
	/** Verso al que llega. */
	hasta: number;
	/** +1 al bloque siguiente, −1 al anterior, 0 dentro del mismo. */
	desplazamiento: number;
	nota: string | null;
};

export type PublicRhymeScheme = PublicScheme & {
	/** El bloque se repite indefinidamente: la notación lo marca con `[ ]…`. */
	cicla: boolean;
	enlaces: PublicRhymeLink[];
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
	esquemasRima: PublicRhymeScheme[];
	secciones: PublicSection[];
	variedades: PublicScheme[];
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
