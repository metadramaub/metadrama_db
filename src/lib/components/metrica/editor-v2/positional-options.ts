import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

/** Todas las opciones identifican una posición concreta de la unidad. */
export function arePositionalOptions(options: MetricCatalogDomainRow[]): boolean {
	return (
		options.length > 0 &&
		options.every((option) => Number(option.posicion_unidad ?? 0) > 0)
	);
}

/** Hay más de una respuesta posible para al menos una posición. */
export function haveAlternativesByPosition(options: MetricCatalogDomainRow[]): boolean {
	if (!arePositionalOptions(options)) return false;
	const seen = new Set<number>();
	for (const option of options) {
		const position = Number(option.posicion_unidad);
		if (seen.has(position)) return true;
		seen.add(position);
	}
	return false;
}

/**
 * Si la pregunta habla de **algunos** versos de la unidad o de **todos**.
 *
 * De eso depende cómo se dibuja: donde cada verso pide medida —las cuatro liras abiertas, el
 * pareado, la estancia de la canción— tiene sentido la rejilla verso a verso, porque la rejilla
 * *es* la respuesta. Donde solo algunos la piden —los cuatro quiebros de la manriqueña entre sus
 * doce versos, el tercer verso de la seguidilla gitana— la rejilla dibuja ocho renglones que dicen
 * «8 sílabas · FIJO» para llegar a los cuatro que preguntan.
 *
 * **Antes esto se decidía por `selecciones_min < selecciones_max`**, y eso es otra cosa: dice si el
 * número de respuestas puede variar, no a cuántos versos alcanza. La copla manriqueña pide cuatro
 * medidas de cuatro quiebros —`4-4`, sin variación— y por eso caía en la rejilla completa, con sus
 * ocho renglones fijos, que era el caso peor de todos.
 *
 * `versosDeLaUnidad` es la unidad más corta a la que alcanza la respuesta. Sin ese dato no se puede
 * saber si las posiciones que pregunta son todas o son algunas.
 */
export function isPartialPositionalSelection(
	group: MetricCatalogDomainRow,
	options: MetricCatalogDomainRow[],
	versosDeLaUnidad?: number
): boolean {
	if (!haveAlternativesByPosition(options)) return false;
	if (group.define_norma === true) return false;
	const posiciones = new Set(options.map((option) => Number(option.posicion_unidad))).size;
	if (typeof versosDeLaUnidad === 'number' && versosDeLaUnidad > 0) {
		return posiciones < versosDeLaUnidad;
	}
	// Sin saber cuántos versos tiene la unidad, lo único que se puede afirmar es que una pregunta
	// de número variable señala excepciones y no una pauta.
	return Number(group.selecciones_min ?? 0) < Number(group.selecciones_max ?? 1);
}

/** Etiqueta breve para el selector compacto; conserva el nombre si no conoce las sílabas. */
export function shortPositionOptionLabel(
	option: MetricCatalogDomainRow,
	position: number
): string {
	const syllables = Number(option.metro_silabas);
	if (Number.isFinite(syllables) && syllables > 0) return String(syllables);
	const label = String(option.nombre);
	const prefix = `Verso ${position} · `;
	return label.startsWith(prefix) ? label.slice(prefix.length) : label;
}
