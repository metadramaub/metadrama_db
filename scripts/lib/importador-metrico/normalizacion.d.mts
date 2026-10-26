export function normalizarExtraccion(
	extraccion: unknown,
	opciones: {
		reglas: unknown;
		catalogo: unknown;
		fuentes?: unknown;
		bibliografia?: unknown;
		decisiones?: unknown[];
	}
): Record<string, unknown>;
export function informeNormalizacion(input: unknown): string;
