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
	/**
	 * Lo que pesa **cada valor** cuando coincide, si no pesan todos lo mismo.
	 *
	 * La modalidad de la evidencia dice cuánto importa que la respuesta caiga dentro de lo previsto;
	 * esto dice cuánto vale acertar con cada valor. La endecha real admite rima consonante, pero su
	 * norma es la asonancia: un «consonante» no la contradice y tampoco puede valerle lo mismo que a
	 * una forma que solo rima en consonante. Sin entrada, el valor pesa lo que la evidencia.
	 */
	modalidadPorValor?: Record<string, ModalidadEvidencia> | null;
	/**
	 * Una condición necesaria, no un indicio: **no suma al cumplirse y resta al romperse**.
	 *
	 * Es el mínimo de extensión de una composición sin regla de longitud. Que un pasaje de treinta
	 * versos llegue a los quince que pide la canción no dice que sea una canción —le pasa a casi
	 * todo—, pero uno de dos versos no puede serlo. Contada como coincidencia entera, la canción le
	 * ganaba a la silva por haber declarado un mínimo que la silva no declara.
	 */
	soloContradice?: boolean;
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
	/** La modalidad de la arquitectura dentro de su forma: una excepcional no gana un empate. */
	arquitecturaModalidad?: ModalidadEvidencia;
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
/**
 * El enunciado de una dimensión, guardado **una vez** y no una por arquitectura.
 *
 * La pregunta y su ayuda son de la dimensión, no de quien la declara: «¿cuántos versos abarca el
 * pasaje?» es la misma la pida el soneto o la silva. Repetidas en cada evidencia viajaban unas
 * novecientas veces —ciento sesenta kilobytes de prosa duplicada en cada carga— para unas veinte
 * dimensiones reales.
 */
export type TextoDimension = {
	pregunta: string;
	ayuda: string;
};

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
	/** Enunciado de cada dimensión, indexado por su clave. */
	textos: Record<string, TextoDimension>;
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

/**
 * **Cuánto se aparta el pasaje de la norma de una forma**, mirándola a ella sola.
 *
 * Es lo contrario de `nivel`, que compara formas entre sí: un pareado puede encajar del todo y quedar
 * por detrás de otra forma que también encaja. Juntas en una sola etiqueta, las dos cosas se
 * confundían: la pantalla llamaba «encaje bajo» a una forma sin ninguna contradicción solo porque
 * otra iba delante.
 *
 * - `pleno`: nada de lo respondido la contradice.
 * - `con_desviacion`: la contradice solo la extensión, o algo que su norma no fija. Es la forma
 *   posible con una laguna, un verso de más o una variante.
 * - `contradice`: el pasaje rompe algo que su norma fija.
 */
export type EncajeForma = 'pleno' | 'con_desviacion' | 'contradice';

export type FormaPuntuada = {
	formaId: string;
	formaSlug: string;
	formaNombre: string;
	formaDefinicion: string | null;
	puntuacion: number;
	/** Cómo queda frente a las demás: se lee como probabilidad relativa, no como encaje. */
	nivel: 'candidata' | 'alto' | 'medio' | 'bajo';
	encaje: EncajeForma;
	arquitecturas: HipotesisPuntuada[];
};
