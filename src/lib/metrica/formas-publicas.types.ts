/**
 * Tipos del catálogo público de formas.
 *
 * Son tipos de presentación: describen lo que la página enseña, no cómo está guardado. El
 * servidor los produce desde el catálogo y el componente los pinta, sin que ninguno de los
 * dos dependa del otro.
 */

import type { MetricStructuralLevel } from '$lib/metrica/catalogo';

/** Una entrada del índice. */
export type PublicFormSummary = {
	slug: string;
	nombre: string;
	definicion: string | null;
	/** `forma` o `sin_forma`: los tramos sin forma no son formas comparables. */
	tipoRegistro: string;
	nivelEstructural: MetricStructuralLevel;
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

/** Una parte con nombre dentro de un esquema: la fronte de la estancia, la vuelta del zéjel. */
export type PublicSchemePart = {
	nombre: string;
	/** Versos que abarca, contados en orden de lectura desde el 1. */
	desde: number;
	hasta: number;
	nota: string | null;
};

export type PublicRhymeScheme = PublicScheme & {
	/** Identificador estable del esquema; también evita colisiones entre nombres iguales. */
	id: string;
	/** El bloque se repite indefinidamente: la notación lo marca con `[ ]…`. */
	cicla: boolean;
	enlaces: PublicRhymeLink[];
	partes: PublicSchemePart[];
	/**
	 * De qué parte de la forma es esta rima, cuando no es de la unidad entera: «Cuartetos».
	 * El soneto declara la de sus cuartetos en la sección y la de sus tercetos en la unidad,
	 * y las dos tienen que leerse juntas bajo «Rima».
	 */
	deLaSeccion: string | null;
	/** `unidad` o `seccion`: si describe la forma entera o solo una de sus partes. */
	ambito: string | null;
	/**
	 * Nombres que la tradición da a esta disposición y no a la forma entera: «cuarteta» es la
	 * redondilla cruzada, no la redondilla.
	 */
	denominaciones: string[];
};

export type PublicSection = {
	/** Identificador estable: una arquitectura puede repetir nombres como «Mudanza». */
	id: string;
	nombre: string;
	nota: string | null;
	/**
	 * La rima de la sección. Cuando reutiliza el repertorio de otra forma, es la de aquella:
	 * los cuartetos del soneto riman como el cuarteto endecasílabo, y sus dos disposiciones
	 * están declaradas allí, no en el soneto.
	 */
	esquemasRima: PublicRhymeScheme[];
	versosMin: number | null;
	versosMax: number | null;
	repeticionesMin: number | null;
	repeticionesMax: number | null;
	/** Cuando la sección reutiliza el repertorio de otra forma, cuál. */
	reutiliza: string | null;
	/** Secciones contenidas, conservando la jerarquía declarada en el catálogo. */
	hijas: PublicSection[];
};

export type PublicTrait = {
	nombre: string;
	valor: string | null;
	modalidad: string | null;
	nota: string | null;
};

/** Una regla de recurrencia declarada por la arquitectura. */
export type PublicRepetition = {
	tipo: string;
	regla: string;
	modalidad: string | null;
	descripcion: string | null;
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
	repeticiones: PublicRepetition[];
	denominaciones: string[];
};

/** Lo que una fuente afirma sobre esta forma, con su referencia. */
export type PublicSourceClaim = {
	resumen: string | null;
	localizador: string | null;
	confianza: string | null;
	/** Sobre qué lo dice: la forma entera o una de sus arquitecturas. */
	sobre: string;
};

/**
 * Una fuente con todo lo que dice de una forma. Se agrupa porque la referencia bibliográfica
 * completa es larga y una misma monografía suele decir varias cosas: repetirla en cada
 * afirmación ahogaba el texto que importa.
 */
export type PublicSource = {
	cita: string;
	anio: number | null;
	afirmaciones: PublicSourceClaim[];
};

/** Otra forma con la que esta se relaciona, y en qué consiste la relación. */
export type PublicFormRelation = {
	/** Nombre de la otra forma, y su slug para enlazarla. */
	nombre: string;
	slug: string;
	nivelEstructural: MetricStructuralLevel;
	/** `compuesta_por`, `contrasta_con`, `relacionada_con`… tal como lo declara el catálogo. */
	tipo: string;
	nota: string | null;
	/** Si esta forma es el origen de la relación o su destino, que cambia cómo se lee. */
	esOrigen: boolean;
};

export type PublicFormDetail = PublicFormSummary & {
	relaciones: PublicFormRelation[];
	arquitecturas_: PublicArchitecture[];
	fuentes: PublicSource[];
};
