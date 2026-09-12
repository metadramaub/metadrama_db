import type {
	AutorListadoItem,
	AutorPublicoPayload,
	AutorResumen
} from '$lib/autores/perfil-autor';
import type { CatalogStructureTramo, CatalogTramo } from '$lib/catalogo/catalog-filters';
import type { PublicObraFichaPayload } from '$lib/types/public-ficha.types';

export type PublicArtifactScope = 'publico' | 'completo';

export type ObraFichaArtifactPayload = {
	schema_version: 1;
	ficha: PublicObraFichaPayload;
};

export type ObrasIndexArtifactItem = {
	obra_id: string;
	slug: string;
	titulo: string;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	fecha_inicio_metadrama: number | null;
	fecha_fin_metadrama: number | null;
	total_versos: number | null;
	genero_id: string | null;
	updated_at: string;
	visible_publico: boolean | null;
	autores: string[];
	tramos: CatalogTramo[];
	jornadas_tramos: CatalogStructureTramo[];
	cuadros_tramos: CatalogStructureTramo[];
	numero_efectivo_formas: number | null;
	densidad_transiciones: number | null;
	n_formas_distintas: number | null;
	formas_presentes: string[];
	metros_presentes: string[];
	tipos_forma_presentes: string[];
	variaciones_presentes: string[];
	subtipos_presentes: string[];
};

export type ObrasIndexArtifactPayload = {
	schema_version: 1;
	alcance: PublicArtifactScope;
	obras: ObrasIndexArtifactItem[];
};

export type AutorFichaArtifactPayload = AutorPublicoPayload & {
	schema_version: 1;
	alcance: PublicArtifactScope;
	resumen: AutorResumen;
};

export type AutoresIndexArtifactPayload = {
	schema_version: 1;
	alcance: PublicArtifactScope;
	autores: Array<AutorListadoItem & { autor_id: string }>;
};

export type ObraAnalysisSequenceFact = {
	id: string;
	i: number;
	f: number;
	n: number;
	j: number | null;
	c: number | null;
	forma: string | null;
	tipo_forma?: string;
	arquitectura: string | null;
	cuadro_continua?: boolean;
	cortes_cuadro: number;
	versos_partidos?: boolean;
	cambio_espacio?: boolean;
	evento_sobrenatural?: boolean;
	intervencion_femenina?: string;
	intervencion_donaire?: string;
	intervencion_sobrenaturales?: string;
	caracterizaciones: unknown[];
	metros: unknown[];
	esquemas: unknown[];
	rasgos: unknown[];
	variedades: unknown[];
	desviaciones: unknown[];
};

export type StatisticalSummary = {
	n: number;
	media: number | null;
	q1: number | null;
	mediana: number | null;
	q3: number | null;
	minimo: number | null;
	maximo: number | null;
};

export type ObraComparativeMetrics = {
	total_versos: number;
	total_secuencias: number;
	n_jornadas: number | null;
	n_formas_distintas: number | null;
	numero_efectivo_formas: number | null;
	densidad_transiciones: number | null;
	longitud_media_secuencia: number | null;
	proporcion_italiana: number | null;
	proporcion_sin_forma: number | null;
};

export type ObraFormProfileEntry = {
	tipo_forma: string | null;
	versos: number;
	secuencias: number;
	proporcion_versos: number | null;
	longitud_media_secuencia: number | null;
};

export type ObraDramaticArticulation = {
	cambios_cuadro_total: number;
	cambios_cuadro_sin_cobertura: number;
	cambios_cuadro_que_parten_secuencia: number;
	cambios_cuadro_con_cambio_secuencia: number;
	cambios_secuencia_misma_forma: number;
	proporcion_cambios_cuadro_con_cambio_secuencia: number | null;
	jornadas: Array<{ jornada: number; abre: string | null; cierra: string | null }>;
};

export type ObraEnunciationEntry = {
	versos: number;
	proporcion_versos: number | null;
	formas: string[];
};

export type ObraPhenomenonEntry = {
	si: number;
	no: number;
	sin_respuesta: number;
	total_respondidas: number;
	proporcion: number | null;
	exclusiva: number;
	compartida: number;
};

export type ObraAnalysisArtifactPayload = {
	schema_version: 2;
	obra_id: string;
	total_secuencias: number;
	total_transiciones: number;
	metricas: ObraComparativeMetrics;
	perfil_formas: Record<string, ObraFormProfileEntry>;
	articulacion: ObraDramaticArticulation;
	enunciacion: Record<string, ObraEnunciationEntry>;
	secuencias: ObraAnalysisSequenceFact[];
	transiciones: Array<{ de: string; a: string; veces: number }>;
	fenomenos: Record<string, ObraPhenomenonEntry>;
};

export type CorpusComparisonWork = {
	obra_id: string;
	slug: string;
	titulo: string;
	fecha_inicio_trad: number | null;
	fecha_fin_trad: number | null;
	fecha_inicio_metadrama: number | null;
	fecha_fin_metadrama: number | null;
	genero_id: string | null;
	visible_publico: boolean;
	autores: string[];
	metricas: ObraComparativeMetrics;
	perfil_formas: Record<string, ObraFormProfileEntry>;
	articulacion: ObraDramaticArticulation;
	enunciacion: Record<string, ObraEnunciationEntry>;
	fenomenos: Record<string, ObraPhenomenonEntry>;
	transiciones: Array<{ de: string; a: string; veces: number }>;
};

export type CorpusFormComparison = {
	forma: string;
	tipo_forma: string | null;
	obras_con_forma: number;
	obras_analizables: number;
	proporcion_obras: number | null;
	versos_totales: number;
	secuencias_totales: number;
	proporcion_versos: StatisticalSummary;
	secuencias_por_obra: StatisticalSummary;
	longitud_media_secuencia: StatisticalSummary;
};

export type CorpusTransitionComparison = {
	de: string;
	a: string;
	obras_con_transicion: number;
	obras_analizables: number;
	proporcion_obras: number | null;
	ocurrencias_totales: number;
	ocurrencias_por_obra: StatisticalSummary;
};

export type CorpusEnunciationComparison = {
	obras_con_anotacion: number;
	obras_analizables: number;
	proporcion_obras: number | null;
	proporcion_versos: StatisticalSummary;
};

export type CorpusExtremeEntry = {
	forma: string;
	jornadas: number;
	obras: number;
};

export type CorpusExtremePairEntry = {
	abre: string;
	cierra: string;
	jornadas: number;
	obras: number;
};

/** Banco de trabajo privado; `alcance` describe el universo, no su visibilidad por RLS. */
export type CorpusComparisonsArtifactPayload = {
	schema_version: 2;
	privado: true;
	alcance: PublicArtifactScope;
	criterio_universo: {
		estado: 'publicado';
		visibilidad: 'visible_publico' | 'todas_las_publicadas';
	};
	obras_analizables: number;
	obras: CorpusComparisonWork[];
	metricas_obra: Record<string, StatisticalSummary>;
	formas: CorpusFormComparison[];
	transiciones: CorpusTransitionComparison[];
	fenomenos: Record<string, StatisticalSummary>;
	enunciacion: Record<string, CorpusEnunciationComparison>;
	extremos_jornada: {
		aperturas: CorpusExtremeEntry[];
		cierres: CorpusExtremeEntry[];
		pares: CorpusExtremePairEntry[];
	};
};
