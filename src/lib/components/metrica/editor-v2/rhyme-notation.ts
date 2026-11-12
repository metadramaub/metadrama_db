/** Elimina solo separación accidental: la caja de las letras también codifica la medida. */
export function compactRhymeNotation(value: string): string {
	return value.normalize('NFC').replace(/\s+/gu, '');
}

/**
 * Coloca una notación verso a verso sobre las posiciones que describe.
 *
 * `destino` son esas posiciones, en orden de lectura. Casi siempre son seguidas —la notación de una
 * redondilla cubre sus cuatro versos—, pero no en el soneto: sus dos esquemas se guardan en la
 * unidad y cada uno describe solo su sección, los ocho versos de los cuartetos o los seis de los
 * tercetos. Medir la notación contra la unidad entera la descartaba siempre, y el resumen enseñaba
 * en su lugar la rima habitual de la norma, aunque se hubiera elegido otra.
 *
 * Los separadores que la notación trae —`|`, `:` y el espacio de `ABBA ABBA`— marcan un corte antes
 * del verso siguiente. Devuelve `null` si las letras no son tantas como posiciones: una notación
 * que no casa verso a verso no se puede repartir.
 */
export function repartirNotacion(
	notacion: string,
	destino: number[]
): { letras: [number, string][]; cortes: number[] } | null {
	const signos = Array.from(notacion.normalize('NFC').trim());
	const esSeparador = (signo: string) => signo === '|' || signo === ':' || /\s/u.test(signo);
	if (signos.filter((signo) => !esSeparador(signo)).length !== destino.length) return null;

	const letras: [number, string][] = [];
	const cortes: number[] = [];
	let recorrido = 0;
	for (const signo of signos) {
		if (esSeparador(signo)) {
			if (recorrido > 0 && recorrido < destino.length && cortes.at(-1) !== destino[recorrido]) {
				cortes.push(destino[recorrido]);
			}
			continue;
		}
		letras.push([destino[recorrido], signo]);
		recorrido += 1;
	}
	return { letras, cortes };
}

export function normalizeRhymeSymbol(raw: string, syllables: number | null): string {
	const symbol = Array.from(raw.normalize('NFC').replace(/[^A-Za-zÑñ-]/gu, '')).at(-1) ?? '';
	if (!symbol || symbol === '-' || syllables === null) return symbol;
	return syllables <= 8
		? symbol.toLocaleLowerCase('es')
		: symbol.toLocaleUpperCase('es');
}
