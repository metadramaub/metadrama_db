// Adapta los datos de la ficha pública (PublicFichaSecuencia) a los tipos de
// presentación genéricos de los componentes métricos reutilizables.
import type { PublicFichaSecuencia } from '$lib/types/public-ficha.types';
import type { MetricBarSegment } from '$lib/components/metrica/metric-display.types';

export function secuenciaToBarSegment(secuencia: PublicFichaSecuencia): MetricBarSegment {
	return {
		id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		forma: secuencia.estrofa_forma_term,
		label: secuencia.estrofa_tipo_term,
		n_versos: secuencia.n_versos,
		subsegments: (secuencia.subtipos_estrofa ?? []).map((sub) => ({
			id: sub.subtipo_secuencia_id,
			v_ini: sub.v_ini,
			v_fin: sub.v_fin,
			label: sub.subtipo_estrofa_term
		}))
	};
}

export function secuenciasToBarSegments(
	secuencias: PublicFichaSecuencia[]
): MetricBarSegment[] {
	return secuencias.map(secuenciaToBarSegment);
}
