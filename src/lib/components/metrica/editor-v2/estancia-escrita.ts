/**
 * La estancia escrita de una vez: `abC.abC:c.dD`.
 *
 * Quien ve clara una estancia la escribe como se escribe en los tratados, y el editor la reparte:
 * una letra por verso —minúscula el heptasílabo, mayúscula el endecasílabo—, los dos puntos cierran
 * la fronte, y el punto separa lo que va dentro de cada mitad: los dos pies en la fronte, y el
 * eslabón de la sirima después. Con eso quedan escritas la medida, la rima y la partición, que son
 * las tres cosas que la fila de cada verso pide una a una.
 *
 * Se usa el punto y no la barra vertical porque el catálogo todavía no ha decidido si sus
 * notaciones se cortan con `:` o con `|` (PENDIENTES · B11), y el atajo no debe tomar partido.
 *
 * Lo que no lleva dos puntos no tiene fronte: `abCabCcdD` a secas es una estancia sin partes, y
 * `c.dD` sin fronte delante no se entiende como eslabón y sirima, porque sin fronte el eslabón no
 * tiene qué retomar.
 */

import type { ParteAsignable, Reparto } from './reparto-estancia';

export type EstanciaEscrita = {
	/** Las letras, una por verso, sin separadores. */
	letras: string;
	/** A qué parte va cada verso, por el slug de su sección. */
	reparto: Reparto;
	/** Lo que impide aplicarla, o nada. */
	error: string | null;
};

const LETRA = /^[A-Za-z]$/;

function parteConSlug(partes: ParteAsignable[], slug: string): string | null {
	return partes.find((parte) => String(parte.seccion.slug) === slug)?.id ?? null;
}

/**
 * Lee la estancia escrita y dice a qué parte va cada verso.
 *
 * `partes` son las partes asignables de la estancia; se buscan por el slug de su sección
 * (`fronte`, `primer_pie`, `segundo_pie`, `eslabon`, `sirima`), que es lo que el catálogo fija.
 */
export function leerEstanciaEscrita(
	texto: string,
	partes: ParteAsignable[],
	versosEsperados?: number
): EstanciaEscrita {
	const limpio = texto.replace(/\s+/g, '');
	const fallo = (error: string): EstanciaEscrita => ({ letras: '', reparto: [], error });
	if (!limpio) return fallo('Escribe una letra por verso.');
	if (!/^[A-Za-z.:]+$/.test(limpio)) {
		return fallo('Solo letras, el punto y los dos puntos: `abC.abC:c.dD`.');
	}
	if ((limpio.match(/:/g) ?? []).length > 1) return fallo('Solo puede haber unos dos puntos: cierran la fronte.');

	const reparto: Reparto = [];
	let letras = '';
	const empuja = (tramo: string, parteSlug: string | null) => {
		for (const char of tramo) {
			if (!LETRA.test(char)) continue;
			letras += char;
			reparto.push(parteSlug ? parteConSlug(partes, parteSlug) : null);
		}
	};

	const [antes, despues] = limpio.includes(':') ? limpio.split(':') : [null, limpio];

	if (antes !== null) {
		if (!antes.replace(/\./g, '')) return fallo('La fronte no puede estar vacía.');
		const pies = antes.split('.');
		if (pies.length > 2) return fallo('La fronte tiene dos pies como mucho.');
		if (pies.length === 2) {
			if (!pies[0] || !pies[1]) return fallo('Cada pie de la fronte necesita al menos una letra.');
			empuja(pies[0], 'primer_pie');
			empuja(pies[1], 'segundo_pie');
		} else {
			empuja(pies[0], 'fronte');
		}
		const tramos = despues.split('.').filter((tramo) => tramo.length > 0);
		if (tramos.length > 2) return fallo('Después de la fronte solo caben el eslabón y la sirima.');
		if (tramos.length === 2) {
			if (tramos[0].length !== 1) return fallo('El eslabón es un solo verso: `:c.dD`.');
			empuja(tramos[0], 'eslabon');
			empuja(tramos[1], 'sirima');
		} else if (tramos.length === 1) {
			empuja(tramos[0], 'sirima');
		}
	} else {
		// Sin fronte no hay partición que leer: solo letras.
		empuja(despues, null);
	}

	if (versosEsperados !== undefined && letras.length !== versosEsperados) {
		return fallo(
			`La estancia tiene ${versosEsperados} versos y has escrito ${letras.length} ${letras.length === 1 ? 'letra' : 'letras'}.`
		);
	}
	return { letras, reparto, error: null };
}

/**
 * Escribe la estancia tal como la leería `leerEstanciaEscrita`, para enseñar lo que hay.
 *
 * Devuelve `null` si el reparto no cabe en la notación —una parte fuera de orden, un hueco entre
 * partes—: entonces no se enseña nada antes que enseñar algo que no es.
 */
export function escribirEstancia(
	letras: string,
	reparto: Reparto,
	partes: ParteAsignable[]
): string | null {
	if (letras.length !== reparto.length) return null;
	const slugDe = new Map(partes.map((parte) => [parte.id, String(parte.seccion.slug)]));
	const tramos: { slug: string | null; texto: string }[] = [];
	for (let index = 0; index < letras.length; index += 1) {
		const slug = reparto[index] ? (slugDe.get(reparto[index]!) ?? null) : null;
		const ultimo = tramos[tramos.length - 1];
		if (ultimo && ultimo.slug === slug) ultimo.texto += letras[index];
		else tramos.push({ slug, texto: letras[index] });
	}
	const orden = ['fronte', 'primer_pie', 'segundo_pie', 'eslabon', 'sirima'];
	const slugs = tramos.map((tramo) => tramo.slug);
	if (slugs.every((slug) => slug === null)) return letras;
	if (slugs.some((slug) => slug === null)) return null;
	const posiciones = slugs.map((slug) => orden.indexOf(slug!));
	if (posiciones.some((p, i) => i > 0 && p <= posiciones[i - 1])) return null;
	const tieneFronte = slugs.some((slug) => slug === 'fronte' || slug === 'primer_pie' || slug === 'segundo_pie');
	if (!tieneFronte) return null;
	let salida = '';
	for (const [index, tramo] of tramos.entries()) {
		const anterior = tramos[index - 1]?.slug ?? null;
		if (index > 0) {
			const cierraFronte =
				(anterior === 'fronte' || anterior === 'primer_pie' || anterior === 'segundo_pie') &&
				tramo.slug !== 'segundo_pie';
			salida += cierraFronte ? ':' : '.';
		}
		salida += tramo.texto;
	}
	return salida;
}

/**
 * El reparto que dibujan unos cortes, con los nombres que pone el orden del catálogo.
 *
 * Es la misma gramática que la estancia escrita, leída desde los cortes: uno, fronte y sirima;
 * dos, fronte, eslabón y sirima si el tramo del medio es un verso, y si no los dos pies y la
 * sirima; tres, pies, eslabón y sirima. Ninguno, sin partes. Más de tres no caben.
 */
export function repartoDeLosCortes(
	versos: number,
	cortes: number[],
	partes: ParteAsignable[]
): Reparto {
	const reparto: Reparto = Array.from({ length: versos }, () => null);
	const limites = [...new Set(cortes)].filter((c) => c >= 0 && c < versos - 1).sort((a, b) => a - b);
	if (limites.length === 0 || limites.length > 3) return reparto;
	const tramos: [number, number][] = [];
	let desde = 0;
	for (const corte of limites) {
		tramos.push([desde, corte]);
		desde = corte + 1;
	}
	tramos.push([desde, versos - 1]);
	let slugs: string[];
	if (tramos.length === 2) slugs = ['fronte', 'sirima'];
	else if (tramos.length === 3) {
		const [medioDesde, medioHasta] = tramos[1];
		slugs = medioHasta === medioDesde ? ['fronte', 'eslabon', 'sirima'] : ['primer_pie', 'segundo_pie', 'sirima'];
	} else slugs = ['primer_pie', 'segundo_pie', 'eslabon', 'sirima'];
	for (const [index, [a, b]] of tramos.entries()) {
		const id = parteConSlug(partes, slugs[index]);
		for (let i = a; i <= b; i += 1) reparto[i] = id;
	}
	return reparto;
}
