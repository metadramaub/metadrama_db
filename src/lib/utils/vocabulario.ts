/**
 * Nombre legible de un término de vocabulario para presentación (selectores,
 * catálogo, ficha pública). Usa `etiqueta` si está rellena; si no, cae al slug
 * interno `termino`. Mismo criterio que `coalesce(etiqueta, termino)` en la RPC
 * pública.
 */
export function displayTerm(
	option: { etiqueta?: string | null; termino?: string | null } | null | undefined
): string {
	if (!option) return '';
	const etiqueta = option.etiqueta?.trim();
	if (etiqueta) return etiqueta;
	return option.termino?.trim() ?? '';
}
