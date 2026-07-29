export type PoliticaFamilia = 'familia' | 'variantes';
export type EtapaDemarcador = 'familias' | 'variantes';
export type ClaveRasgoDemarcador =
	| 'metros'
	| 'rima'
	| 'predominioRima'
	| 'organizacionPareados'
	| 'naturaleza'
	| 'tamanio'
	| 'patron';

export type ValorCatalogado = {
	clave: string;
	etiqueta: string;
};

export type RasgosCandidatoDemarcador = {
	metros: ValorCatalogado[];
	rima: ValorCatalogado | null;
	naturaleza: ValorCatalogado | null;
	tamanio: number | null;
	patron: string | null;
	patronEtiqueta?: string | null;
	/** Predominio observable de versos rimados o sueltos en una serie abierta. */
	predominioRima?: ValorCatalogado | null;
	/** Indica si los pareados organizan sistemáticamente la serie o no. */
	organizacionPareados?: ValorCatalogado | null;
};

export type CandidatoDemarcadorNuevo = {
	id: string;
	slug: string;
	etiqueta: string;
	definicion: string | null;
	familiaId: string;
	familiaSlug: string;
	familiaEtiqueta: string;
	esFamilia: boolean;
	esResidual?: boolean;
	rasgos: RasgosCandidatoDemarcador;
};

export type FamiliaDemarcadorNuevo = {
	id: string;
	slug: string;
	etiqueta: string;
	politica: PoliticaFamilia;
	raiz: CandidatoDemarcadorNuevo;
	variantes: CandidatoDemarcadorNuevo[];
};

export type ArtefactoDemarcadorNuevo = {
	esquema: 1;
	origen?: 'vocabulario_legacy' | 'catalogo_metrico';
	generadoEn: string;
	fuenteActualizadaEn: string | null;
	familias: FamiliaDemarcadorNuevo[];
	/** Salidas editoriales de último recurso; no intervienen en el orden de preguntas. */
	residuales?: CandidatoDemarcadorNuevo[];
	estadisticas: {
		familias: number;
		familiasConVariantes: number;
		variantesDemarcables: number;
		residuales?: number;
	};
};

export type OpcionPreguntaDemarcador = {
	valor: string;
	etiqueta: string;
};

export type PreguntaDemarcadorNueva = {
	id: string;
	etapa: EtapaDemarcador;
	rasgo: ClaveRasgoDemarcador;
	tipo: 'opciones' | 'si_no';
	operador: 'igual' | 'contiene';
	pregunta: string;
	ayuda: string;
	opciones: OpcionPreguntaDemarcador[];
	valorObjetivo: string | null;
	puntuacion: number;
	cobertura: number;
};

export type RespuestaDemarcadorNueva = {
	preguntaId: string;
	pregunta: string;
	etapa: EtapaDemarcador;
	valor: string | 'desconocido';
	etiqueta: string;
};
