import type {
	FichaMinima,
	IncidenciaImportador,
	ResumenMinimo
} from '../../../src/lib/importador-metrico/types';
export function prepararFichaMinima(
	normalizada: unknown,
	opciones?: { genero?: string; metadatos?: Record<string, unknown> }
): FichaMinima;
export function validarFichaMinima(
	input: unknown,
	opciones?: { catalogo?: unknown }
): { datos: FichaMinima | null; errores: IncidenciaImportador[]; avisos: IncidenciaImportador[] };
export function resumirFichaMinima(input: unknown): ResumenMinimo;
export function serializarCanonico(input: unknown): string;
export function huellaFichaMinima(input: unknown): string;
export const fichaMinimaSchema: import('zod').ZodType<FichaMinima>;
export function crearCopiaConfirmada(
	input: unknown,
	contexto: unknown,
	opciones?: { catalogo?: unknown }
): unknown;
