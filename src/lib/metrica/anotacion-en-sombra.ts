/**
 * Tipos de la anotación en sombra (fase 0 de la migración de anotaciones).
 *
 * Viven aquí y no en `$lib/server` porque los consume también la interfaz: el servidor los
 * produce, el componente los pinta, y ninguno de los dos depende del otro.
 */

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
	/** Lo que el catálogo nuevo propone, siguiendo `origen_termino_id`. */
	formaPropuestaId: string | null;
	formaPropuesta: string | null;
	arquitecturaPropuestaId: string | null;
	arquitecturaPropuesta: string | null;
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
