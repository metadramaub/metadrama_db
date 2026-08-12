/** Elimina solo separación accidental: la caja de las letras también codifica la medida. */
export function compactRhymeNotation(value: string): string {
	return value.normalize('NFC').replace(/\s+/gu, '');
}

export function normalizeRhymeSymbol(raw: string, syllables: number | null): string {
	const symbol = Array.from(raw.normalize('NFC').replace(/[^A-Za-zÑñ-]/gu, '')).at(-1) ?? '';
	if (!symbol || symbol === '-' || syllables === null) return symbol;
	return syllables <= 8
		? symbol.toLocaleLowerCase('es')
		: symbol.toLocaleUpperCase('es');
}
