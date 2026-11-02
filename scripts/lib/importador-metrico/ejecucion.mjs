import { z } from 'zod';

const dato = z.string().trim().min(1).max(2000).nullable();
/** Declaración del servicio o del importador; no certifica la identidad del modelo. */
export const camposEjecucionSchema = {
	modo: dato.optional(),
	plan: dato.optional(),
	parametros: dato.optional()
};
export const ejecucionSchema = z.object({
	generador: dato,
	modelo: dato,
	...camposEjecucionSchema,
	prompt_version: dato
}).strict();
