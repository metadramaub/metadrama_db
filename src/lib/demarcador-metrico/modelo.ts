import type { Rejilla } from '$lib/metrica/rejilla';

export type ModalidadEvidencia = 'definitoria' | 'habitual' | 'admitida' | 'excepcional';
export type ObservabilidadEvidencia = 'directa' | 'especializada' | 'derivada';
export type TipoEvidencia = 'categoria' | 'booleano' | 'numero';
export type ModoDemarcador = 'guiado' | 'hipotesis';
export type NivelEstructural = 'verso' | 'estrofa' | 'serie' | 'composicion';

export type ValorEvidencia = {
	clave: string;
	etiqueta: string;
};

export type EvidenciaNormativa = {
	dimension: string;
	familiaCognitiva: 'metro' | 'extension' | 'rima' | 'estructura' | 'repeticion' | 'rasgo';
	etiqueta: string;
	pregunta: string;
	ayuda: string;
	tipo: TipoEvidencia;
	valores: ValorEvidencia[];
	minimo: number | null;
	maximo: number | null;
	modulo: number | null;
	residuo: number | null;
	/**
	 * Lo que suman las partes opcionales de la arquitectura, cuando las tiene.
	 *
	 * Vacío o nulo equivale a `[0]`. El terceto encadenado trae `[0, 1]` porque su remate final
	 * puede estar o no, y son dos congruencias —`3n` y `3n+1`— que un solo residuo no expresa.
	 */
	desplazamientos: number[] | null;
	reglaLongitud: string | null;
	modalidad: ModalidadEvidencia;
	observabilidad: ObservabilidadEvidencia;
	coste: number;
	orden: number;
	fuente: 'norma' | 'esquema' | 'seccion' | 'repeticion' | 'rasgo' | 'eleccion';
};

export type HipotesisMetrica = {
	id: string;
	formaId: string;
	formaSlug: string;
	formaNombre: string;
	formaDefinicion: string | null;
	nivelEstructural: NivelEstructural;
	arquitecturaId: string;
	arquitecturaSlug: string;
	arquitecturaNombre: string;
	arquitecturaDescripcion: string | null;
	arquitecturaPrincipal: boolean;
	unidadVersos: number | null;
	presentacion: PresentacionArquitectura;
	evidencias: EvidenciaNormativa[];
};

export type EsquemaVisual = {
	id: string;
	nombre: string | null;
	notacion: string;
	modalidad: ModalidadEvidencia;
};

export type RasgoVisual = {
	nombre: string;
	valor: string;
	descripcion: string | null;
	modalidad: ModalidadEvidencia;
};

export type PresentacionArquitectura = {
	/**
	 * La arquitectura dibujada verso a verso, con la misma rejilla que la ficha del catálogo métrico.
	 * Sustituye a la tira de casillas que el demarcador pintaba por su cuenta, que contaba las
	 * alternativas de una posición como posiciones: la seguidilla gitana, que mide
	 * 6-6-(10/11/12)-6, salía con doce casillas.
	 */
	rejilla: Rejilla | null;
	metro: {
		descripcion: string | null;
	};
	rima: {
		tipo: string | null;
		esquemas: EsquemaVisual[];
	};
	estructura: string | null;
	repeticiones: string[];
	rasgos: RasgoVisual[];
};

export type FormaDemarcable = {
	id: string;
	slug: string;
	nombre: string;
	definicion: string | null;
	nivelEstructural: NivelEstructural;
	arquitecturas: Array<{
		id: string;
		nombre: string;
		descripcion: string | null;
	}>;
};

/**
 * Un par de formas que el catálogo declara confundibles, con lo que las separa dicho en prosa.
 *
 * Sale de `forma_relaciones`, donde el proyecto tiene escrito su propio mapa de confusiones: 17
 * pares `contrasta_con` y 5 `derivada_de`, todos con nota. Es exactamente lo que el recorrido de
 * comprobación necesita y hasta ahora no leía nadie —«en el endecasílabo suelto predominan los
 * versos sin rima; en la silva endecasílaba predominan los rimados»—, así que sirve para dos cosas:
 * para saber contra quién hay que contrastar, y para explicárselo a quien pregunta.
 */
export type RelacionEntreFormas = {
	origenId: string;
	destinoId: string;
	tipo: 'contrasta_con' | 'derivada_de' | 'relacionada_con' | string;
	nota: string | null;
};

export type CatalogoDemarcador = {
	formas: FormaDemarcable[];
	hipotesis: HipotesisMetrica[];
	relaciones: RelacionEntreFormas[];
	advertencias: string[];
};

export type OpcionPregunta = ValorEvidencia;

export type PreguntaDemarcador = {
	id: string;
	dimension: string;
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'];
	pregunta: string;
	ayuda: string;
	tipo: TipoEvidencia;
	opciones: OpcionPregunta[];
	observabilidad: ObservabilidadEvidencia;
	coste: number;
	utilidad: number;
};

export type RespuestaDemarcador = {
	preguntaId: string;
	dimension: string;
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'];
	pregunta: string;
	valor: string | number | 'desconocido';
	etiqueta: string;
};

export type DetalleCompatibilidad = {
	dimension: string;
	etiqueta: string;
	estado: 'coincide' | 'contradice' | 'sin_datos';
	peso: number;
};

export type DesviacionLongitud = {
	observada: number;
	regularAnterior: number | null;
	regularSiguiente: number | null;
	diferenciaMinima: number;
	regla: string | null;
};

export type InterpretacionLongitud = {
	observada: number;
	tipo: 'unidad' | 'repeticion' | 'serie' | 'pasaje';
	unidades: number | null;
	versosPorUnidad: number | null;
	regla: string | null;
};

export type HipotesisPuntuada = {
	hipotesis: HipotesisMetrica;
	puntuacion: number;
	coincidencias: number;
	contradicciones: number;
	interpretacionLongitud: InterpretacionLongitud | null;
	desviacionLongitud: DesviacionLongitud | null;
	detalles: DetalleCompatibilidad[];
};

/**
 * Una dimensión en la que dos normas predicen cosas distintas: lo que de verdad separa dos formas.
 *
 * No es lo mismo que «definitoria». El endecasílabo es definitorio del soneto **y** de la octava
 * real, la lira y el terceto encadenado: confirma la forma sin distinguirla de nada. Lo que
 * distingue dos formas es dónde discrepan, y eso se calcula comparando lo que cada una predice.
 */
export type Discrepancia = {
	dimension: string;
	etiqueta: string;
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'];
	/** `false` cuando la dimensión es derivada: separa, pero no se puede preguntar. */
	observable: boolean;
	respondida: boolean;
};

/**
 * En qué queda una hipótesis puesta a prueba.
 *
 * Los finales de un contraste son tres, y el ranking no es ninguno de ellos: la forma se sostiene,
 * se cae, o no hay manera de decidirlo con lo que se puede ver en el pasaje. El tercero no es un
 * fracaso —es el resultado más honesto cuando dos normas coinciden en todo lo observable— y hasta
 * ahora no existía.
 */
export type VeredictoHipotesis = {
	estado: 'en_curso' | 'sostenida' | 'refutada' | 'indecidible';
	rival: FormaPuntuada | null;
	/** Lo que todavía podría separarla de su rival más próximo, y aún no se ha preguntado. */
	pendientes: Discrepancia[];
	/** Lo que la contradice en algo que su norma fija. */
	contradiceDefinitorias: DetalleCompatibilidad[];
	/** La nota del catálogo sobre ese contraste, cuando el par está declarado. */
	nota: string | null;
};

export type FormaPuntuada = {
	formaId: string;
	formaSlug: string;
	formaNombre: string;
	formaDefinicion: string | null;
	puntuacion: number;
	nivel: 'candidata' | 'alto' | 'medio' | 'bajo';
	arquitecturas: HipotesisPuntuada[];
};
