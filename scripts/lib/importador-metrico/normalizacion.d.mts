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
export class ErrorExtraccion extends Error {
	incidencias: { codigo: string; ruta: string; mensaje: string }[];
	constructor(incidencias: { codigo: string; ruta: string; mensaje: string }[]);
}
