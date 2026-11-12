/** Presentación del ensayo de importación. Ninguno de estos tipos autoriza un guardado. */
export type IncidenciaImportador = { codigo: string; ruta: string; mensaje: string };
export type DestinoMetrico = { forma_slug: string; arquitectura_slug: string | null };
export type MetadatosEditables = {
	titulo: string;
	autor_nombre: string;
	genero: string;
	edicion_base: string;
	fecha_inicio: string;
	fecha_fin: string;
	inicio_inclusivo?: string;
	fin_inclusivo?: string;
	fecha_aproximada?: string;
	fuente_fecha: string;
	fundamento_autoria: string;
	ia_generador?: string;
	ia_modelo?: string;
	ia_modo?: string;
	ia_plan?: string;
	ia_parametros?: string;
};
export type SegmentoMinimo = {
	ref: string;
	v_ini: number;
	v_fin: number;
	segmentacion: 'provisional' | 'confirmada';
	origen: {
		tramo_ref: string;
		denominacion_literal: string | null;
		fuente_id: string | null;
		pagina: number | null;
		notas_ref: string[];
		tramos_ref?: string[];
	};
	identificacion: DestinoMetrico | null;
	candidatas: DestinoMetrico[];
	regla_id: string | null;
	nota: string | null;
	detalles_fuente: Record<string, unknown>[];
	desviaciones: Record<string, unknown>[];
	caracterizaciones?: (
		| {termino: 'prosa'; v_ini: number; v_fin: number; tramo_ref: string; literal: string}
		| {termino: 'cantado'; v_ini: number; v_fin: number; tramo_ref: string; nota_ref: string; literal: string}
	)[];
};
export type FichaMinima = {
	esquema: 'versologia-ficha-minima/0.2';
	obra_ref: string;
	metadatos: Omit<
		MetadatosEditables,
		'fecha_inicio' | 'fecha_fin' | 'fuente_fecha' | 'fundamento_autoria' |
		'inicio_inclusivo' | 'fin_inclusivo' | 'fecha_aproximada' |
		'ia_generador' | 'ia_modelo' | 'ia_modo' | 'ia_plan' | 'ia_parametros'
	> & {
		fecha_inicio: number | null;
		fecha_fin: number | null;
		inicio_inclusivo?: boolean;
		fin_inclusivo?: boolean;
		fecha_aproximada?: boolean;
		variantes_titulo?: string[];
		propuestas_autoria?: Record<string, unknown>[];
		fuente_fecha: string | null;
		fundamento_autoria: string | null;
		observaciones: string[];
	};
	jornadas: { numero: number; v_ini: number; v_fin: number; rotulo_literal: string | null }[];
	segmentos: SegmentoMinimo[];
	numeracion?: { tipo: 'por_jornada'; desplazamientos: { jornada: number; desplazamiento: number }[] };
	comprobacion?: {
		avisos_longitud: { segmento_ref: string; v_ini: number; v_fin: number; mensaje: string }[];
	};
	procedencia: {
		reglas_version: string;
		catalogo_revision: number;
		extraccion_sha256: string;
		entradas_sha256: Record<string, string>;
		ejecucion?: {
			generador: string | null;
			modelo: string | null;
			modo?: string | null;
			plan?: string | null;
			parametros?: string | null;
			prompt_version: string | null;
		};
	};
};
export type ResumenMinimo = {
	denominador: string;
	extension: number;
	jornadas: number;
	bloques: number;
	segmentacion_confirmada: boolean;
	forma_identificada: number;
	arquitectura_identificada: number;
	forma_pendiente: number;
	con_candidatas: number;
	sin_identificacion: number;
	perfil_formas: { forma_slug: string; versos: number; proporcion_sobre_total: number }[];
};
export type BorradorFichaMinima = Omit<FichaMinima, 'metadatos'> & {
	metadatos: Omit<FichaMinima['metadatos'], 'fecha_inicio' | 'fecha_fin'> & {
		fecha_inicio: number | null;
		fecha_fin: number | null;
	};
};
export type NotaFuenteImportador = {
	id: string;
	texto_literal: string;
	v_ini?: number | null;
	v_fin?: number | null;
	tramos_ref?: string[];
};
export type FilaVistaPrevia = SegmentoMinimo & {
	longitud?: { estado: 'compatible' | 'revisar' | 'sin_regla' | 'sin_identificar'; mensaje: string | null };
	notas_fuente?: NotaFuenteImportador[];
	jornada: number | null;
	extension: number;
	forma_nombre: string | null;
	candidatas_nombres: string[];
};
export type ResultadoVistaPrevia = {
	persistido: boolean;
	confirmacion: { obra_id: string; importacion_id: string } | null;
	formato: string | null;
	metadatos: MetadatosEditables;
	datos: BorradorFichaMinima | null;
	pendientes_metadatos?: IncidenciaImportador[];
	resumen: ResumenMinimo | null;
	filas: FilaVistaPrevia[];
	errores: IncidenciaImportador[];
	avisos: IncidenciaImportador[];
};
