export type ModalidadEvidencia = 'definitoria' | 'preferente' | 'admitida' | 'excepcional';
export type ObservabilidadEvidencia = 'directa' | 'especializada' | 'derivada';
export type TipoEvidencia = 'categoria' | 'booleano' | 'numero';
export type ModoDemarcador = 'guiado' | 'hipotesis';

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
	gradoEspecificacion: 'general' | 'especifica' | null;
	arquitecturaId: string;
	arquitecturaSlug: string;
	arquitecturaNombre: string;
	arquitecturaDescripcion: string | null;
	arquitecturaPrincipal: boolean;
	evidencias: EvidenciaNormativa[];
};

export type FormaDemarcable = {
	id: string;
	slug: string;
	nombre: string;
	definicion: string | null;
	gradoEspecificacion: 'general' | 'especifica' | null;
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

export type HipotesisPuntuada = {
	hipotesis: HipotesisMetrica;
	puntuacion: number;
	coincidencias: number;
	contradicciones: number;
	detalles: DetalleCompatibilidad[];
};

export type FormaPuntuada = {
	formaId: string;
	formaSlug: string;
	formaNombre: string;
	formaDefinicion: string | null;
	gradoEspecificacion: 'general' | 'especifica' | null;
	puntuacion: number;
	nivel: 'muy_compatible' | 'compatible' | 'posible' | 'poco_compatible';
	arquitecturas: HipotesisPuntuada[];
};
