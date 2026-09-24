import type { MetricBarSegment } from './metric-display.types';
import { normalizeFormaKey } from '$lib/utils/metric-colors';

/**
 * Formas cuyas subdivisiones no se dibujan: en una tirada de quintillas el desglose interno es
 * tan menudo que confunde, y se sobreentiende que va dividida en quintillas.
 *
 * Lo comparten el código de barras de pantalla y su figura descargable: si una dibujara las
 * divisiones y la otra no, serían dos gráficos.
 */
const SUBSEGMENTOS_OCULTOS = new Set(['quintilla']);

/** Las subdivisiones que se dibujan de un segmento: todas menos la que abre, que es su borde. */
export function subsegmentosVisibles(segmento: MetricBarSegment) {
	if (SUBSEGMENTOS_OCULTOS.has(normalizeFormaKey(segmento.colorKey ?? segmento.forma))) return [];
	return (segmento.subsegments ?? []).filter((sub) => sub.v_ini > segmento.v_ini);
}
