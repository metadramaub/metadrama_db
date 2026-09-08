// Adapta los datos de la ficha pública (PublicFichaSecuencia) a los tipos de
// presentación genéricos de los componentes métricos reutilizables.
import type { PublicFichaSecuencia } from '$lib/types/public-ficha.types';
import type { MetricBarSegment } from '$lib/components/metrica/metric-display.types';

/**
 * Una secuencia es **un tramo de un color y con el nombre de su forma**.
 *
 * Rotulaba la arquitectura —«Octosilábica consonante» donde debía decir «Quintilla»—, que es el
 * detalle y no la identidad; la arquitectura se lee dentro, al abrir la secuencia. Y dibujaba una
 * raya por estrofa, porque el esquema de rima se responde una vez por unidad y llegaban setenta y
 * ocho entradas en una tirada de redondillas: el reparto de esquemas es un dato de la tirada, no
 * una subdivisión que pintar encima.
 */
export function secuenciaToBarSegment(secuencia: PublicFichaSecuencia): MetricBarSegment {
	return {
		id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		forma: secuencia.estrofa_forma_term,
		colorKey: secuencia.estrofa_forma_slug ?? secuencia.estrofa_forma_term,
		label: secuencia.estrofa_forma_term,
		n_versos: secuencia.n_versos,
		subsegments: []
	};
}

export function secuenciasToBarSegments(
	secuencias: PublicFichaSecuencia[]
): MetricBarSegment[] {
	return secuencias.map(secuenciaToBarSegment);
}
