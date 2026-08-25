/**
 * Cómo se ordena y se busca el catálogo público de formas.
 *
 * Vive fuera de la página porque es lo único de esa pantalla que se puede equivocar en silencio: un
 * orden mal hecho se lee como una lista cualquiera, y un buscador que devuelve la forma buscada en
 * el puesto once parece que no la tiene.
 */

import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';

export type OrdenFormas = 'alfabetico' | 'versos' | 'nivel';

export const ORDENES_DE_FORMAS: { valor: OrdenFormas; etiqueta: string }[] = [
	{ valor: 'alfabetico', etiqueta: 'Alfabético' },
	{ valor: 'versos', etiqueta: 'Por número de versos' },
	{ valor: 'nivel', etiqueta: 'Por tipo de estructura' }
];

/** De lo más corto a lo más largo: el verso suelto, la estrofa, la serie, la composición. */
const RANGO_NIVEL: Record<string, number> = {
	verso: 0,
	estrofa: 1,
	serie: 2,
	composicion: 3
};

/** Sin tildes y en minúscula, para que «endecha» encuentre «Endecha» y «décima» encuentre «decima». */
export function normalizarBusqueda(texto: string): string {
	return texto
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLocaleLowerCase('es');
}

/**
 * Dónde ha coincidido el término, de mejor a peor. Cuanto menor, más arriba.
 *
 * **El nombre y los otros nombres van primero.** Buscar «lira» tiene que dar la lira antes que las
 * formas cuya definición la menciona —lira, sexteto-lira, septeto-lira y las cuatro aliradas la
 * nombran—, y antes el nombre exacto que el que solo empieza igual. Lo que aparece en la definición
 * sigue saliendo, pero detrás: se busca en todo y se ordena por dónde se ha encontrado.
 */
export function relevanciaDeForma(forma: PublicFormSummary, termino: string): number {
	if (!termino) return 0;
	const nombres = [forma.nombre, ...forma.denominaciones].map(normalizarBusqueda);
	if (nombres.some((nombre) => nombre === termino)) return 0;
	if (nombres.some((nombre) => nombre.startsWith(termino))) return 1;
	if (nombres.some((nombre) => nombre.includes(termino))) return 2;
	return 3;
}

/**
 * El comparador del listado.
 *
 * La relevancia manda sobre el orden elegido: quien escribe un término quiere lo que ha escrito
 * arriba, no la primera por orden de todo lo que coincida en cualquier parte. El orden elegido
 * desempata, y el alfabético desempata siempre al final.
 */
export function compararFormas(
	a: PublicFormSummary,
	b: PublicFormSummary,
	opciones: { orden: OrdenFormas; termino?: string }
): number {
	const termino = opciones.termino ?? '';
	if (termino) {
		const diferencia = relevanciaDeForma(a, termino) - relevanciaDeForma(b, termino);
		if (diferencia !== 0) return diferencia;
	}
	if (opciones.orden === 'versos') {
		// Una serie no tiene número de versos. No vale tratarla como si midiera cero: va al final.
		const versosA = a.unidadVersos ?? Number.POSITIVE_INFINITY;
		const versosB = b.unidadVersos ?? Number.POSITIVE_INFINITY;
		if (versosA !== versosB) return versosA - versosB;
	}
	if (opciones.orden === 'nivel') {
		const nivelA = RANGO_NIVEL[a.nivelEstructural] ?? 99;
		const nivelB = RANGO_NIVEL[b.nivelEstructural] ?? 99;
		if (nivelA !== nivelB) return nivelA - nivelB;
	}
	return a.nombre.localeCompare(b.nombre, 'es');
}

/** Si una forma responde al término, mire donde mire. El orden lo decide la relevancia. */
export function laFormaCoincide(forma: PublicFormSummary, termino: string): boolean {
	if (!termino) return true;
	return [forma.nombre, forma.definicion ?? '', ...forma.denominaciones].some((campo) =>
		normalizarBusqueda(campo).includes(termino)
	);
}
