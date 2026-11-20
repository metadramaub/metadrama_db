export const finalesPredominantes = ['agudo', 'esdrujulo'] as const;
export type FinalPredominante = (typeof finalesPredominantes)[number];
export type RecuentoFinalAcentual = Partial<Record<FinalPredominante, number>>;

export const etiquetaFinal: Record<FinalPredominante, string> = {
	agudo: 'Mayoría de finales agudos',
	esdrujulo: 'Mayoría de finales esdrújulos'
};

export function finalPredominante(value: unknown): FinalPredominante | null {
	return value === 'agudo' || value === 'esdrujulo' ? value : null;
}

export function contarFinales(secuencias: readonly { final_acentual_predominante?: FinalPredominante | null }[]) {
	const recuento: RecuentoFinalAcentual = {};
	for (const secuencia of secuencias) {
		const final = secuencia.final_acentual_predominante;
		if (final) recuento[final] = (recuento[final] ?? 0) + 1;
	}
	return recuento;
}
