export type PerfilFormas = Record<string, number>;

export type TramoSecuencial = {
	i: number;
	f: number;
	s: string;
	t?: string | null;
};

function normalizePerfil(perfil: PerfilFormas): Map<string, number> {
	const entries = Object.entries(perfil).filter(([, versos]) => Number.isFinite(versos) && versos > 0);
	const total = entries.reduce((sum, [, versos]) => sum + versos, 0);
	if (total <= 0) return new Map();
	return new Map(entries.map(([forma, versos]) => [forma, versos / total]));
}

function log2(value: number): number {
	return Math.log(value) / Math.log(2);
}

function kullbackLeibler(p: Map<string, number>, m: Map<string, number>, formas: Set<string>): number {
	let sum = 0;
	for (const forma of formas) {
		const pv = p.get(forma) ?? 0;
		const mv = m.get(forma) ?? 0;
		if (pv > 0 && mv > 0) {
			sum += pv * log2(pv / mv);
		}
	}
	return sum;
}

/**
 * Distancia composicional PROVISIONAL.
 * En el futuro debe sustituirse por transporte óptimo sobre una matriz formas_distancia.
 */
export function distanciaComposicional(perfilA: PerfilFormas, perfilB: PerfilFormas): number {
	const a = normalizePerfil(perfilA);
	const b = normalizePerfil(perfilB);
	if (a.size === 0 && b.size === 0) return 0;
	if (a.size === 0 || b.size === 0) return 1;

	const formas = new Set([...a.keys(), ...b.keys()]);
	const m = new Map<string, number>();
	for (const forma of formas) {
		m.set(forma, ((a.get(forma) ?? 0) + (b.get(forma) ?? 0)) / 2);
	}

	const value = (kullbackLeibler(a, m, formas) + kullbackLeibler(b, m, formas)) / 2;
	return Math.min(1, Math.max(0, value));
}

export function discretizaTramos(
	tramos: TramoSecuencial[],
	// PROVISIONAL: este tamaño de discretización debe quedar calibrable desde la UI.
	versosPorSimbolo = 25
): string[] {
	const step = Number.isFinite(versosPorSimbolo) && versosPorSimbolo > 0 ? versosPorSimbolo : 25;
	const symbols: string[] = [];
	for (const tramo of tramos) {
		if (!tramo.s) continue;
		const versos = Math.max(0, (tramo.f ?? 0) - (tramo.i ?? 0) + 1);
		const repetitions = Math.max(1, Math.round(versos / step));
		for (let i = 0; i < repetitions; i += 1) {
			symbols.push(tramo.s);
		}
	}
	return symbols;
}

function levenshtein(a: string[], b: string[]): number {
	if (a.length === 0) return b.length;
	if (b.length === 0) return a.length;

	let previous = Array.from({ length: b.length + 1 }, (_, index) => index);
	let current = new Array<number>(b.length + 1);

	for (let i = 1; i <= a.length; i += 1) {
		current[0] = i;
		for (let j = 1; j <= b.length; j += 1) {
			// PROVISIONAL: sustitución uniforme; en el futuro debe ponderarse con formas_distancia.
			const substitutionCost = a[i - 1] === b[j - 1] ? 0 : 1;
			current[j] = Math.min(
				previous[j] + 1,
				current[j - 1] + 1,
				previous[j - 1] + substitutionCost
			);
		}
		[previous, current] = [current, previous];
	}

	return previous[b.length];
}

export function distanciaSecuencial(
	tramosA: TramoSecuencial[],
	tramosB: TramoSecuencial[],
	versosPorSimbolo = 25
): number {
	const a = discretizaTramos(tramosA, versosPorSimbolo);
	const b = discretizaTramos(tramosB, versosPorSimbolo);
	const maxLength = Math.max(a.length, b.length);
	if (maxLength === 0) return 0;
	return levenshtein(a, b) / maxLength;
}
