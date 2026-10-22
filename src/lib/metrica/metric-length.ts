import type { MetricLengthRule } from '$lib/metrica/catalogo';
import { structuralAdditionCount, type MetricDeviationRange } from './structural-additions';

export function normativeMetricLength(
	start: number,
	end: number,
	deviations: readonly MetricDeviationRange[] = []
): number {
	return inclusiveMetricLength(start, end) - structuralAdditionCount(start, end, deviations);
}

export function inclusiveMetricLength(start: number, end: number): number {
	if (!Number.isFinite(start) || !Number.isFinite(end) || end < start) return 0;
	return Math.trunc(end) - Math.trunc(start) + 1;
}

/**
 * Los totales que las partes opcionales de la arquitectura pueden añadir al bloque periódico.
 *
 * Una regla sin desplazamientos declarados equivale a `[0]`: la longitud es el ciclo y nada más.
 * El terceto encadenado declara `[0, 4]` porque su serventesio final puede estar o no estar, y esas
 * son dos congruencias distintas —`3n` y `3n+4`— que un solo par de módulo y residuo no expresa.
 */
export function metricLengthOffsets(rule: MetricLengthRule): number[] {
	return rule.desplazamientos?.length ? rule.desplazamientos : [0];
}

export function isMetricLengthCompatible(
	rule: MetricLengthRule | null | undefined,
	start: number,
	end: number,
	/**
	 * Si alguna unidad del pasaje declara una arquitectura distinta de la de su secuencia.
	 *
	 * **Entonces la congruencia no aplica.** La regla de longitud es una guarda para cuando el
	 * editor *deriva* cuántas unidades hay dividiendo el rango; una tirada de décimas con una
	 * aumentada mide `10n + 2` y no cabe en ninguna división exacta, pero es exactamente lo que las
	 * fuentes documentan. Con excepciones, quien gobierna es la cobertura del rango, que el editor
	 * ya calcula y ya enseña.
	 */
	conArquitecturasPropias = false,
	deviations: readonly MetricDeviationRange[] = []
): boolean {
	if (!rule || conArquitecturasPropias) return true;
	const length = normativeMetricLength(start, end, deviations);
	return metricLengthOffsets(rule).some((offset) => {
		const resto = length - offset;
		if (resto < rule.minimo_versos) return false;
		const remainder =
			(((resto - rule.residuo_versos) % rule.modulo_versos) + rule.modulo_versos) %
			rule.modulo_versos;
		return remainder === 0;
	});
}

/**
 * Cómo se llama lo que la regla repite, según de dónde salga la congruencia.
 *
 * **La palabra la pone el dato, no la pantalla.** Cada regla trae ya su `explicacion` escrita
 * —«unidades completas de 5 versos», «ciclos completos de rima de 2 versos»— y el editor decía
 * «ciclos» en los cinco casos: la lira, cuya regla cuenta *unidades*, se leía «2 unidades» en la
 * cabecera y «2 ciclos» tres dedos más abajo. Y «ciclo» ya está tomado en el editor, que llama así
 * al bloque repetible del villancico.
 */
export function metricLengthNoun(origen: MetricLengthRule['origen']): {
	singular: string;
	plural: string;
} {
	switch (origen) {
		case 'ciclo_rima':
			return { singular: 'ciclo de rima', plural: 'ciclos de rima' };
		case 'ciclo_metrico':
			return { singular: 'ciclo métrico', plural: 'ciclos métricos' };
		case 'secciones_fijas':
			return { singular: 'estructura', plural: 'estructuras' };
		case 'secciones_repetibles':
			return { singular: 'bloque', plural: 'bloques' };
		default:
			return { singular: 'unidad', plural: 'unidades' };
	}
}

/**
 * Cuántas veces cabe en el pasaje lo que la regla repite.
 *
 * Una serie no estrófica no tiene «unidades» que materializar, pero **sí sabemos cuántas veces se
 * repite lo que la dibuja**: la endecha real pide ciclos completos de cuatro versos, así que en
 * veintiocho caben siete. El editor ya usaba ese dato para avisar cuando el rango no cuadra;
 * enseñarlo también cuando cuadra es la mitad que faltaba.
 *
 * Devuelve también el `origen`, porque de él sale cómo se llama lo contado: contar sin poder
 * nombrarlo es lo que llevó a decir «ciclos» de todo.
 *
 * Devuelve `null` si no hay regla, si el rango no la cumple —el aviso de error ya lo dice— o si lo
 * que se repite no es un número de veces que contar.
 */
export function metricLengthCycles(
	rule: MetricLengthRule | null | undefined,
	start: number,
	end: number,
	conArquitecturasPropias = false,
	deviations: readonly MetricDeviationRange[] = []
): {
	veces: number;
	modulo: number;
	sobrantes: number;
	origen: MetricLengthRule['origen'];
} | null {
	if (!rule || conArquitecturasPropias) return null;
	if (!isMetricLengthCompatible(rule, start, end, conArquitecturasPropias, deviations)) return null;
	const modulo = rule.modulo_versos;
	if (!Number.isFinite(modulo) || modulo < 2) return null;
	const length = normativeMetricLength(start, end, deviations);
	for (const offset of metricLengthOffsets(rule)) {
		const resto = length - offset;
		if (resto < rule.minimo_versos) continue;
		const remainder = (((resto - rule.residuo_versos) % modulo) + modulo) % modulo;
		if (remainder !== 0) continue;
		const veces = (resto - rule.residuo_versos) / modulo;
		if (veces < 1) continue;
		return { veces, modulo, sobrantes: offset + rule.residuo_versos, origen: rule.origen };
	}
	return null;
}

export function metricLengthError(
	rule: MetricLengthRule | null | undefined,
	start: number,
	end: number,
	configurationName?: string,
	formName?: string,
	conArquitecturasPropias = false,
	deviations: readonly MetricDeviationRange[] = []
): string | null {
	if (!rule || isMetricLengthCompatible(rule, start, end, conArquitecturasPropias, deviations))
		return null;
	const length = inclusiveMetricLength(start, end);
	const additions = structuralAdditionCount(start, end, deviations);
	const adjustment =
		additions > 0
			? ` Descontando ${additions} ${additions === 1 ? 'verso declarado como adición estructural, quedan' : 'versos declarados como adiciones estructurales, quedan'} ${length - additions} para comprobar la norma.`
			: '';
	const selectedName = [formName, configurationName].filter(Boolean).join(' · ');
	const subject = selectedName ? `«${selectedName}» exige` : 'La configuración exige';
	return `La secuencia contiene ${length} ${length === 1 ? 'verso' : 'versos'}.${adjustment} ${subject} ${rule.explicacion}. Revisa el rango y las desviaciones declaradas. Si la fuente presenta una laguna, incluye su posición en el rango y regístrala como desviación, sin reconstruir el texto.`;
}
