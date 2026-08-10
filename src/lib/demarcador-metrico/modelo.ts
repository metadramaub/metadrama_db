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
	metro: {
		descripcion: string | null;
		esquemas: string[][];
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

export type CatalogoDemarcador = {
	formas: FormaDemarcable[];
	hipotesis: HipotesisMetrica[];
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

export type FormaPuntuada = {
	formaId: string;
	formaSlug: string;
	formaNombre: string;
	formaDefinicion: string | null;
	puntuacion: number;
	nivel: 'muy_compatible' | 'compatible' | 'posible' | 'poco_compatible';
	arquitecturas: HipotesisPuntuada[];
};
