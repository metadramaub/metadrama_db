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
 * En una medida posicional completa cada verso necesita respuesta: pareado, estancia, etc.
 * En una selección parcial las respuestas señalan excepciones a la medida dominante: los
 * pies quebrados de la copla de pie quebrado y de la copla real. El catálogo ya distingue
 * ambos casos: las primeras elecciones definen la norma y las segundas permiten elegir un
 * número variable de posiciones sin definirla.
 */
export function isPartialPositionalSelection(
	group: MetricCatalogDomainRow,
	options: MetricCatalogDomainRow[]
): boolean {
	return (
		haveAlternativesByPosition(options) &&
		group.define_norma !== true &&
		Number(group.selecciones_min ?? 0) < Number(group.selecciones_max ?? 1)
	);
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
