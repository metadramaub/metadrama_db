import { z } from 'zod';

const nullableYear = z
	.union([z.number().int().min(1200).max(2100), z.null()])
	.optional()
	.transform((value) => value ?? null);

export const obraDatosPatchSchema = z
	.object({
		titulo: z.string().trim().min(1, 'El título es obligatorio'),
		variantes_titulo: z.array(z.string().trim().min(1)).default([]),
		genero_id: z.string().uuid('Género inválido'),
		fecha_inicio_trad: nullableYear,
		fecha_fin_trad: nullableYear,
		fuente_fecha: z.string().trim().max(2000).nullable().optional().default(null),
		fecha_inicio_metadrama: nullableYear,
		fecha_fin_metadrama: nullableYear,
		edicion: z.string().trim().min(1, 'La edición base es obligatoria')
	})
	.superRefine((data, ctx) => {
		if (
			data.fecha_inicio_trad !== null &&
			data.fecha_fin_trad !== null &&
			data.fecha_inicio_trad > data.fecha_fin_trad
		) {
			ctx.addIssue({
				code: z.ZodIssueCode.custom,
				message: 'La fecha inicial tradicional no puede ser mayor que la final',
				path: ['fecha_inicio_trad']
			});
		}
		if (
			data.fecha_inicio_metadrama !== null &&
			data.fecha_fin_metadrama !== null &&
			data.fecha_inicio_metadrama > data.fecha_fin_metadrama
		) {
			ctx.addIssue({
				code: z.ZodIssueCode.custom,
				message: 'La fecha inicial METADRAMA no puede ser mayor que la final',
				path: ['fecha_inicio_metadrama']
			});
		}
	});

export const jornadaInputSchema = z
	.object({
		jornada_num: z.number().int().positive(),
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive()
	})
	.refine((input) => input.v_ini < input.v_fin, {
		message: 'El verso inicial debe ser menor que el final',
		path: ['v_ini']
	});

export const cuadroInputSchema = z
	.object({
		jornada_id: z.string().uuid(),
		cuadro_num: z.number().int().positive(),
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		descripcion: z.string().trim().nullable().optional().default(null),
		certeza_editor: z.string().uuid()
	})
	.refine((input) => input.v_ini < input.v_fin, {
		message: 'El verso inicial debe ser menor que el final',
		path: ['v_ini']
	});

export const secuenciaInputSchema = z
	.object({
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		estrofa_tipo_id: z.string().uuid('Estrofa requerida'),
		inaugura_espacio: z.boolean().default(false),
		personajes_genero: z.enum(['mixto', 'solo_masculino', 'solo_femenino']),
		personajes_donaire: z.enum(['ausente', 'solo', 'con_otros']),
		personajes_sobrenatural: z.enum(['ausente', 'solo', 'con_otros']),
		estado_revision: z.string().uuid(),
		certeza_editor: z.string().uuid(),
		observaciones: z.string().trim().nullable().optional().default(null),
		notas_internas: z.string().trim().nullable().optional().default(null),
		metro_ids: z.array(z.string().uuid()).min(1, 'Debe seleccionar al menos un metro')
	})
	.refine((input) => input.v_ini < input.v_fin, {
		message: 'El verso inicial debe ser menor que el final',
		path: ['v_ini']
	});

export const estadoInputSchema = z.object({
	estado: z.string().uuid(),
	comentario: z.string().trim().max(2000).optional()
});

export const comentarioInputSchema = z.object({
	comentario: z.string().trim().min(1).max(4000)
});

export const queryFilterSchema = z.object({
	q: z.string().optional(),
	estado: z.string().uuid().optional(),
	editor: z.string().uuid().optional(),
	page: z.coerce.number().int().positive().default(1),
	pageSize: z.coerce.number().int().positive().max(100).default(20)
});

export type ObraDatosPatchInput = z.infer<typeof obraDatosPatchSchema>;
export type JornadaInputParsed = z.infer<typeof jornadaInputSchema>;
export type CuadroInputParsed = z.infer<typeof cuadroInputSchema>;
export type SecuenciaInputParsed = z.infer<typeof secuenciaInputSchema>;
export type EstadoInputParsed = z.infer<typeof estadoInputSchema>;
export type ComentarioInputParsed = z.infer<typeof comentarioInputSchema>;
