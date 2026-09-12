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
	arquitectura: string | null;
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

export type ObraAnalysisArtifactPayload = {
	schema_version: 1;
	obra_id: string;
	total_secuencias: number;
	total_transiciones: number;
	secuencias: ObraAnalysisSequenceFact[];
	transiciones: Array<{ de: string; a: string; veces: number }>;
	fenomenos: Record<
		string,
		{
			si: number;
			no: number;
			sin_respuesta: number;
			total_respondidas: number;
			proporcion: number | null;
			exclusiva: number;
			compartida: number;
		}
	>;
};

export type CorpusComparisonsArtifactPayload = {
	schema_version: 1;
	alcance: PublicArtifactScope;
	obras_analizables: number;
	transiciones: Array<{
		de: string;
		a: string;
		obras_con_transicion: number;
		obras_analizables: number;
		proporcion_obras: number | null;
		ocurrencias_totales: number;
		media_ocurrencias: number | null;
		q1_ocurrencias: number | null;
		mediana_ocurrencias: number | null;
		q3_ocurrencias: number | null;
		maximo_ocurrencias: number | null;
	}>;
	fenomenos: Record<
		string,
		{
			obras_analizables: number;
			media: number | null;
			q1: number | null;
			mediana: number | null;
			q3: number | null;
			minimo: number | null;
			maximo: number | null;
		}
	>;
};
