import { z } from 'zod';

const nullableYear = z
	.union([z.number().int().min(1200).max(2100), z.null()])
	.optional()
	.transform((value) => value ?? null);

const nullableText = (max: number) =>
	z
		.union([z.string().max(max), z.null(), z.undefined()])
		.transform((value) => {
			if (typeof value !== 'string') return null;
			const trimmed = value.trim();
			return trimmed.length > 0 ? trimmed : null;
		});

const nullableUuid = z
	.union([z.string().uuid(), z.literal(''), z.null(), z.undefined()])
	.transform((value) => {
		if (typeof value !== 'string') return null;
		const trimmed = value.trim();
		return trimmed.length > 0 ? trimmed : null;
	});

const nullableUrl = z
	.string()
	.trim()
	.url('URL invalida')
	.or(z.literal(''))
	.optional()
	.nullable()
	.transform((value) => (value ? value : null));

export const obraDatosPatchSchema = z
	.object({
		titulo: nullableText(2000),
		variantes_titulo: z
			.array(z.string().trim())
			.default([])
			.transform((items) => items.map((item) => item.trim()).filter(Boolean)),
		genero_id: nullableUuid,
		fecha_inicio_trad: nullableYear,
		fecha_fin_trad: nullableYear,
		fuente_fecha: z.string().trim().max(2000).nullable().optional().default(null),
		fecha_inicio_metadrama: nullableYear,
		fecha_fin_metadrama: nullableYear,
		edicion: nullableText(20000)
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
	comentario: z.string().trim().min(1).max(4000),
	tipo_comentario: z
		.enum(['general', 'revision', 'tecnico', 'estado'])
		.optional()
		.default('general'),
	secuencia_id: z.string().uuid().optional(),
	jornada_id: z.string().uuid().optional(),
	cuadro_id: z.string().uuid().optional(),
	rango_id: z.string().uuid().optional()
}).superRefine((data, ctx) => {
	const refs = [data.secuencia_id, data.jornada_id, data.cuadro_id, data.rango_id].filter(Boolean);
	if (refs.length > 1) {
		ctx.addIssue({
			code: z.ZodIssueCode.custom,
			message: 'Solo se puede asociar un contexto por comentario.',
			path: ['secuencia_id']
		});
	}
});

const autorIdsSchema = z
	.array(z.string().uuid())
	.min(1, 'Debe seleccionar al menos un autor')
	.transform((ids) => [...new Set(ids)]);

const autoriaObraCompletaSchema = z.object({
	mode: z.literal('obra_completa'),
	source_mode: z.enum(['obra_completa', 'por_jornadas', 'rango_personalizado']),
	confirm_mode_change: z.boolean().optional().default(false),
	confirm_reassign: z.boolean().optional().default(false),
	url_informe_autoria: nullableUrl,
	autor_ids: autorIdsSchema
});

const autoriaPorJornadasItemSchema = z.object({
	jornada_id: z.string().uuid(),
	autor_ids: autorIdsSchema
});

const autoriaRangoItemSchema = z
	.object({
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		autor_ids: autorIdsSchema
	})
	.refine((input) => input.v_ini < input.v_fin, {
		message: 'El verso inicial debe ser menor que el final',
		path: ['v_ini']
	});

export const autoriaInputSchema = z.discriminatedUnion('mode', [
	autoriaObraCompletaSchema,
	z.object({
		mode: z.literal('por_jornadas'),
		source_mode: z.enum(['obra_completa', 'por_jornadas', 'rango_personalizado']),
		confirm_mode_change: z.boolean().optional().default(false),
		confirm_reassign: z.boolean().optional().default(false),
		url_informe_autoria: nullableUrl,
		items: z.array(autoriaPorJornadasItemSchema).min(1, 'Debe definir al menos una jornada')
	}),
	z.object({
		mode: z.literal('rango_personalizado'),
		source_mode: z.enum(['obra_completa', 'por_jornadas', 'rango_personalizado']),
		confirm_mode_change: z.boolean().optional().default(false),
		confirm_reassign: z.boolean().optional().default(false),
		url_informe_autoria: nullableUrl,
		items: z.array(autoriaRangoItemSchema).min(1, 'Debe definir al menos un rango')
	})
]);

export const analisisInputSchema = z.object({
	analisis_editor: nullableText(60000),
	bibliografia: nullableText(20000)
});

export const visibilidadInputSchema = z.object({
	visible_publico: z.boolean()
});

export const obraCreateSchema = z.object({
	titulo: z.string().trim().min(1, 'El titulo es obligatorio').max(300),
	editor_asignado: z.string().uuid('Editor asignado invalido'),
	genero_id: z.string().uuid().optional().nullable().default(null)
});

export const obraReviewersInputSchema = z.object({
	reviewer_ids: z
		.array(z.string().uuid())
		.default([])
		.transform((ids) => [...new Set(ids)])
});

export const vocabularioCreateSchema = z.object({
	categoria: z.string().trim().min(1).max(80),
	termino: z.string().trim().min(1).max(200),
	termino_padre_id: z.string().uuid().optional().nullable().default(null),
	nivel: z.number().int().optional().nullable().default(null),
	orden: z.number().int().optional().nullable().default(null),
	patron_especifico: z.string().trim().max(2000).optional().nullable().default(null),
	activo: z.boolean().optional().default(true)
});

export const vocabularioPatchSchema = z
	.object({
		termino: z.string().trim().min(1).max(200).optional(),
		termino_padre_id: z.string().uuid().optional().nullable(),
		nivel: z.number().int().optional().nullable(),
		orden: z.number().int().optional().nullable(),
		patron_especifico: z.string().trim().max(2000).optional().nullable(),
		activo: z.boolean().optional()
	})
	.refine((payload) => Object.keys(payload).length > 0, {
		message: 'No hay campos para actualizar'
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
export type AutoriaInputParsed = z.infer<typeof autoriaInputSchema>;
export type AnalisisInputParsed = z.infer<typeof analisisInputSchema>;
export type VisibilidadInputParsed = z.infer<typeof visibilidadInputSchema>;
export type ObraCreateParsed = z.infer<typeof obraCreateSchema>;
export type ObraReviewersInputParsed = z.infer<typeof obraReviewersInputSchema>;
export type VocabularioCreateParsed = z.infer<typeof vocabularioCreateSchema>;
export type VocabularioPatchParsed = z.infer<typeof vocabularioPatchSchema>;
