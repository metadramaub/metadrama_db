/**
 * Tipos del catálogo público de formas.
 *
 * Son tipos de presentación: describen lo que la página enseña, no cómo está guardado. El
 * servidor los produce desde el catálogo y el componente los pinta, sin que ninguno de los
 * dos dependa del otro.
 */

import type { MetricStructuralLevel } from '$lib/metrica/catalogo';
import type { PerfilDeArquitectura, Rejilla } from '$lib/metrica/rejilla';

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
	/** `definitoria`, `habitual`, `admitida` o `excepcional`. Es lo que dice cuál esperar. */
	modalidad?: string | null;
};

/**
 * Una medida que la norma no coloca: el repertorio del que la realización elige.
 *
 * Son dos casos distintos que se leían con la misma frase: en la silva elige **cada verso**
 * —`uniforme: false`—, mientras que otros repertorios eligen una medida uniforme dentro del
 * nivel al que se aplican. El `rol` separa la medida dominante de la que la quiebra.
 */
export type PublicMetreRepertoire = {
	silabas: string;
	rol: string | null;
};

export type PublicMetricScheme = PublicScheme & {
	/** `ciclo`, `secuencia` o `conjunto`. */
	tipoSecuencia: string | null;
	/** La medida elegida vale para todo el pasaje y no verso a verso. */
	uniforme: boolean;
	repertorio: PublicMetreRepertoire[];
	/** La parte a la que se aplica, cuando no es la unidad entera. */
	deLaSeccion: string | null;
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
	/** Bloque del esquema al que pertenece: los dos cuartetos de `ABBA ABBA` son dos partes. */
	bloque: number;
	/** Versos que abarca, contados en orden de lectura desde el 1. */
	desde: number;
	hasta: number;
	nota: string | null;
};

/**
 * Una restricción de un esquema abierto: lo que acota la disposición sin fijarla. Es la norma
 * de los esquemas que no tienen posiciones que enseñar.
 */
export type PublicRhymeRestriction = {
	/** Ya redactada para leerse: la componen el tipo y su valor. */
	texto: string;
	/** Si la norma la exige o solo la admite. */
};

export type PublicRhymeScheme = PublicScheme & {
	/** Identificador estable del esquema; también evita colisiones entre nombres iguales. */
	id: string;
	/** El bloque se repite indefinidamente: la notación lo marca con `[ ]…`. */
	cicla: boolean;
	enlaces: PublicRhymeLink[];
	partes: PublicSchemePart[];
	/** Vacío en los esquemas cerrados: su norma son sus posiciones. */
	restricciones: PublicRhymeRestriction[];
	/**
	 * De qué parte de la forma es esta rima, cuando no es de la unidad entera: «Cuartetos».
	 * El soneto declara la de sus cuartetos en la sección y la de sus tercetos en la unidad,
	 * y las dos tienen que leerse juntas bajo «Rima».
	 */
	deLaSeccion: string | null;
	/** `unidad` o `seccion`: si describe la forma entera o solo una de sus partes. */
	/** La parte de la que es el esquema. Nulo cuando es de la unidad entera. */
	seccionId: string | null;
	/**
	 * Nombres que la tradición da a esta disposición y no a la forma entera: «cuarteta» es la
	 * redondilla cruzada, no la redondilla.
	 */
	denominaciones: string[];
	/** Sin posiciones que enseñar: lo que declara es que la disposición no está fijada. */
	abierto: boolean;
	/**
	 * Consonante, asonante o sin rima **de esta disposición**. El catálogo lo declara en dos
	 * niveles y no siempre coinciden: el villancico admite `abba` consonante y `-a-a` asonantada,
	 * así que su arquitectura no puede reducirse a un solo régimen y este es el que manda.
	 */
	tipoRima: string | null;
	/** Posiciones que permiten dibujar la disposición aunque la arquitectura entera sea abierta. */
	figura: { clase: string | null; suelto: boolean }[];
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
	/** La primera aparición concreta establece el patrón que repetirán las siguientes. */
	primeraRealizacionDefinePatron: boolean;
	/** Los otros nombres de la parte: el eslabón de la estancia es también la «chiave». */
	denominaciones: string[];
	/**
	 * La forma cuyo repertorio de rima reutiliza esta parte, con su enlace: los cuartetos del
	 * soneto riman como el cuarteto endecasílabo, y la ficha debe poder llevar allí.
	 */
	reutiliza: { nombre: string; slug: string | null } | null;
	/** Secciones contenidas, conservando la jerarquía declarada en el catálogo. */
	hijas: PublicSection[];
};

export type PublicTrait = {
	nombre: string;
	valor: string | null;
	modalidad: string | null;
	nota: string | null;
	/** Cuántas posiciones puede ocupar como mucho: la copla real admite hasta dos quebrados. */
	posicionesMax: number | null;
};

/**
 * Los rasgos de una arquitectura, repartidos por **cómo se leen**, que es lo que los separa y no
 * se veía: la ficha los ponía los tres bajo «Rasgos que admite».
 *
 * - `declarados`: la arquitectura lo afirma y nadie lo pregunta. Es norma —la densidad total del
 *   sexteto, el pie quebrado de la sextilla—, no algo que quede por observar.
 * - `excluyentes`: un mismo rasgo con varios valores y una sola respuesta admitida. La silva
 *   libre es de densidad `Total` **o** `Mayoritaria`, y en dos líneas seguidas parecía que era
 *   las dos.
 * - `opcionales`: un sí o un no que puede quedarse sin responder, como el final esdrújulo.
 */
export type PublicTraits = {
	declarados: PublicTrait[];
	/** Posibilidades reconocidas que no caracterizan todas las realizaciones. */
	permitidos: PublicTrait[];
	excluyentes: {
		nombre: string;
		nota: string | null;
		valores: PublicTrait[];
		opcional: boolean;
	}[];
	opcionales: PublicTrait[];
};

/**
 * Cómo se concreta una dimensión al realizar la arquitectura.
 *
 * La ficha conserva estos datos estructurados para derivar su grado de determinación. No son
 * contenido editorial: proceden de los grupos que consume también el registrador.
 */
export type PublicChoiceGroup = {
	dimension: string;
	alcance: string | null;
	/** Parte que concreta la elección; nula cuando pertenece a la unidad entera. */
	seccion: string | null;
	tipoControl: string | null;
	seleccionesMin: number;
	seleccionesMax: number;
	defineNorma: boolean;
	opciones: number;
};

/**
 * Una recurrencia declarada por la arquitectura.
 *
 * Son de dos clases y no se leen igual: la de la sextina es **norma de la forma** —las palabras
 * finales vuelven—, y las del villancico son **las respuestas de una pregunta** —el estribillo
 * vuelve entero, en parte o no vuelve—. Lo que las separa es si materializan una sección.
 */
export type PublicRepetition = {
	slug: string;
	tipo: string;
	nombre: string;
	modalidad: string | null;
	descripcion: string | null;
	/** Si es una alternativa entre las que el editor elige y no una propiedad de la forma. */
	esAlternativa: boolean;
};

/** Una variedad empareja una medida con una rima: las siete del sexteto-lira. */
export type PublicVariety = {
	nombre: string;
	descripcion: string | null;
	modalidad: string | null;
	/** La medida que emparejan, ya dibujada: `7-11-7-11-7-11`. */
	medida: string | null;
	/** La disposición de rima que emparejan: `ababcc`. */
	rima: string | null;
	/**
	 * La variedad dibujada verso a verso, con su medida y su rima alineadas.
	 *
	 * Es donde se resuelve la caja de las clases: el esquema no puede llevarla porque lo comparten
	 * variedades de medidas distintas, y la caja marca el arte del verso.
	 */
	rejilla: Rejilla | null;
};

export type PublicArchitecture = {
	slug: string;
	nombre: string;
	descripcion: string | null;
	principal: boolean;
	modalidad: string | null;
	/**
	 * Consonante, asonante, sin rima… **de esta arquitectura**, que no siempre es el de la forma:
	 * el pareado hace las dos. La ficha no lo enseñaba en ninguna, aunque es lo primero que hay
	 * que saber de una rima.
	 *
	 * **Se declara siempre, en el nivel que le corresponde**: en la arquitectura cuando su régimen
	 * es uno, y en cada disposición cuando varía dentro de ella —el villancico admite `abba`
	 * consonante y `-a-a` asonantada, y ahí reducirlo a un valor sería falsearlo—. La ficha lee
	 * el nivel en que esté; lo que no hace es inventarse el de arriba a partir del de abajo,
	 * porque eso taparía que falta declararlo.
	 */
	tipoRima: string | null;
	/** El régimen vive en cada disposición porque dentro de la arquitectura varía. */
	tipoRimaPorDisposicion: boolean;
	/** No está declarado en ningún nivel: falta el dato y la ficha debe decirlo. */
	tipoRimaSinDeclarar: boolean;
	/**
	 * Si la arquitectura dice **de algún modo** cómo se comporta su rima.
	 *
	 * Dejar la disposición abierta no es un defecto: es lo que hace una forma general, y la
	 * sextilla lo es —sus fuentes enumeran disposiciones y cierran la lista con un «etcétera»—.
	 * El defecto es no decir nada por ninguna vía, y hay tres: las restricciones de un esquema
	 * abierto, unos esquemas concretos de los que se calcula, o la densidad de rima declarada
	 * como rasgo. Y una cuarta que las cubre todas: declarar el régimen `sin_rima`, porque
	 * entonces no hay disposición que fijar —lo de la sextina son palabras finales permutadas—. El criterio se fijó el 10 de agosto de 2026 y se aplicó al auditor; la ficha
	 * seguía mirando solo la primera, y por eso pintaba en rojo arquitecturas que sí lo dicen.
	 */
	declaraNormaDeRima: boolean;
	unidadMin: number | null;
	unidadMax: number | null;
	/** Cuál de los siete moldes es, derivado del catálogo. Decide qué zonas se enseñan. */
	perfil: PerfilDeArquitectura;
	/**
	 * La arquitectura dibujada verso a verso. Nula cuando la norma no fija posiciones, que es
	 * una respuesta legítima: la silva no tiene rejilla que enseñar.
	 */
	rejilla: Rejilla | null;
	esquemasMetricos: PublicMetricScheme[];
	esquemasRima: PublicRhymeScheme[];
	secciones: PublicSection[];
	variedades: PublicVariety[];
	/**
	 * Cuando la arquitectura se elige por variedad, medida y rima **no son dos preguntas**: son
	 * las dos caras de una. El sexteto-lira es el único caso del catálogo, y separarlas obligaba
	 * a cruzar de memoria cinco medidas con tres disposiciones para reconstruir siete parejas.
	 */
	eligeVariedad: boolean;
	rasgos: PublicTraits;
	repeticiones: PublicRepetition[];
	elecciones: PublicChoiceGroup[];
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
