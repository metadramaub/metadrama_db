/**
 * Tipos de la anotación en sombra (fase 0 de la migración de anotaciones).
 *
 * Viven aquí y no en `$lib/server` porque los consume también la interfaz: el servidor los
 * produce, el componente los pinta, y ninguno de los dos depende del otro.
 */

/**
 * Por qué vía el catálogo nuevo llega a una propuesta. Lo calcula la vista
 * `propuesta_metrica_secuencia` y lo replica `npm run migracion:informe`: los dos
 * implementan el mismo sistema de equivalencias y deben decir lo mismo.
 *
 * - `directa` — algo del catálogo reclama el término y de ahí sale la forma.
 * - `rasgo` — lo reclama un valor de rasgo o un metro, que no dicen forma: esa viene del
 *   padre y el término aporta precisión. Es el caso de los romances y su asonancia.
 * - `ascendencia` — no lo reclama nadie, pero sí un ascendiente. Da forma y arquitectura,
 *   **no las respuestas**, que las sigue contestando el editor.
 * - `sin_destino` — nadie lo reclama en toda su línea.
 * - `sin_tipo` — la secuencia no declara forma ninguna.
 */
export type ShadowResolution =
	| 'directa'
	| 'rasgo'
	| 'ascendencia'
	| 'sin_destino'
	| 'sin_tipo';

export const SHADOW_RESOLUTION_LABEL: Record<ShadowResolution, string> = {
	directa: 'Directa',
	rasgo: 'Rasgo propio',
	ascendencia: 'Heredada',
	sin_destino: 'Sin destino',
	sin_tipo: 'Sin forma'
};

/**
 * Una respuesta del formulario que se deduce del término legado: la asonancia de un
 * romance, el esquema de los tercetos de un soneto. La calcula la vista
 * `propuesta_elecciones_secuencia`.
 */
export type ShadowAnswer = {
	grupoEleccionId: string;
	pregunta: string;
	opcionEleccionId: string;
	respuesta: string;
	/** Las de ámbito unidad solo llegan cuando la secuencia es una sola unidad. */
	alcance: 'secuencia' | 'unidad';
};

/** Una obra abierta a la anotación en sombra. */
export type ShadowWork = {
	obraId: string;
	titulo: string;
	nota: string | null;
	/** Secuencias reales que tiene la obra. */
	secuencias: number;
	/** De ellas, cuántas están ya anotadas con el modelo nuevo. */
	anotadas: number;
};

/** Una secuencia real, con lo que dice el modelo viejo y lo que propone el nuevo. */
export type ShadowSequence = {
	secuenciaId: string;
	obraId: string;
	vIni: number;
	vFin: number;
	versos: number;
	/** El término del vocabulario legado, que es lo que dice hoy el modelo viejo. */
	terminoLegado: string | null;
	estrofaTipoId: string | null;
	/** Lo que el catálogo nuevo propone, siguiendo el sistema de equivalencias. */
	formaPropuestaId: string | null;
	formaPropuesta: string | null;
	arquitecturaPropuestaId: string | null;
	arquitecturaPropuesta: string | null;
	/** Por qué vía se llegó a esa propuesta. Una propuesta heredada es menos precisa. */
	via: ShadowResolution;
	/** Lo que el término aporta además de la forma: la asonancia, una variedad, un metro. */
	detalle: string | null;
	/** Término del que se heredó la forma, cuando no la reclama el término mismo. */
	heredadoDe: string | null;
	/** Si la extensión del rango cabe en la arquitectura propuesta. */
	longitudCompatible: boolean | null;
	/** Explicación de la incompatibilidad que debe resolver el editor de la obra. */
	motivoRevision: string | null;
	/** Respuestas que el término legado ya permite dar por el editor. */
	respuestas: ShadowAnswer[];
	/** Cuántos subtipos y caracterizaciones traía la anotación vieja. */
	subtipos: number;
	caracterizaciones: number;
	/** La prueba que ya la anota, si existe. */
	pruebaId: string | null;
	formaAnotadaId: string | null;
	arquitecturaAnotadaId: string | null;
};

/**
 * Una obra candidata. Se eligen por las formas que traen —conviene que haya villancicos,
 * canciones y tercetos encadenados—, así que el selector las enseña.
 */
export type ShadowCandidateWork = {
	obraId: string;
	titulo: string;
	secuencias: number;
	/** Términos legados distintos que aparecen en la obra, los más frecuentes primero. */
	formas: string[];
	/** Secuencias cuyo término legado no tiene correspondencia en el catálogo nuevo. */
	sinCorrespondencia: number;
	abierta: boolean;
};

export type ShadowAnnotationData = {
	works: ShadowWork[];
	sequences: ShadowSequence[];
	candidates: ShadowCandidateWork[];
};

/**
 * Si el modelo nuevo dice lo mismo que el viejo en esta secuencia.
 *
 * `sin_propuesta` no es un desacuerdo: es que el término legado no tiene todavía
 * correspondencia declarada en el catálogo, y eso se arregla en el catálogo, no anotando.
 */
export type ShadowAgreement = 'pendiente' | 'coincide' | 'difiere' | 'sin_propuesta';

export function shadowAgreement(sequence: ShadowSequence): ShadowAgreement {
	if (!sequence.pruebaId) return sequence.formaPropuestaId ? 'pendiente' : 'sin_propuesta';
	if (!sequence.formaPropuestaId) return 'sin_propuesta';
	return sequence.formaAnotadaId === sequence.formaPropuestaId ? 'coincide' : 'difiere';
}
