import type { MetricLengthRule } from '$lib/metrica/catalogo';

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
	conArquitecturasPropias = false
): boolean {
	if (!rule || conArquitecturasPropias) return true;
	const length = inclusiveMetricLength(start, end);
	return metricLengthOffsets(rule).some((offset) => {
		const resto = length - offset;
		if (resto < rule.minimo_versos) return false;
		const remainder =
			((resto - rule.residuo_versos) % rule.modulo_versos + rule.modulo_versos) %
			rule.modulo_versos;
		return remainder === 0;
	});
}

export function metricLengthError(
	rule: MetricLengthRule | null | undefined,
	start: number,
	end: number,
	configurationName?: string,
	formName?: string,
	conArquitecturasPropias = false
): string | null {
	if (!rule || isMetricLengthCompatible(rule, start, end, conArquitecturasPropias)) return null;
	const length = inclusiveMetricLength(start, end);
	const selectedName = [formName, configurationName].filter(Boolean).join(' · ');
	const subject = selectedName ? `«${selectedName}» exige` : 'La configuración exige';
	return `La secuencia contiene ${length} ${length === 1 ? 'verso' : 'versos'}. ${subject} ${rule.explicacion}. Revisa el rango. Si la fuente presenta una laguna, incorpora el verso que ocupa esa posición y regístrala como desviación.`;
}
