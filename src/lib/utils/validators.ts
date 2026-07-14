import { z } from 'zod';
import { COMENTARIO_SECCIONES } from '$lib/types/obra.types';

const comentarioTipoInputSchema = z.enum([
	'general',
	'revision',
	'tecnico',
	'estado',
	'nota_propia',
	'observacion_publica'
]);
const comentarioTipoPatchSchema = z.enum([
	'general',
	'revision',
	'tecnico',
	'nota_propia',
	'observacion_publica'
]);

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

const optionalNullableUuidPatch = z
	.union([z.string().uuid(), z.literal(''), z.null()])
	.optional()
	.transform((value) => {
		if (value === undefined) return undefined;
		if (typeof value !== 'string') return null;
		const trimmed = value.trim();
		return trimmed.length > 0 ? trimmed : null;
	});

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
		v_fin: z.number().int().positive()
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
		versos_partidos: z.boolean().default(false),
		evocacion_metrica: z.boolean().default(false),
		evocacion_metrica_texto: nullableText(2000),
		intervencion_personajes_femeninos: z.enum(['sin_intervencion', 'exclusiva', 'compartida']),
		intervencion_figuras_donaire: z.enum(['sin_intervencion', 'exclusiva', 'compartida']),
		intervencion_personajes_sobrenaturales: z.enum(['sin_intervencion', 'exclusiva', 'compartida']),
		sinopsis: z.string().trim().nullable().optional().default(null)
	})
	.strict()
	.transform((input) => ({
		...input,
		evocacion_metrica_texto: input.evocacion_metrica ? input.evocacion_metrica_texto : null
	}))
	.refine((input) => input.v_ini <= input.v_fin, {
		message: 'El verso inicial no puede ser mayor que el final',
		path: ['v_ini']
	});

export const secuenciaCaracterizacionRangoInputSchema = z
	.object({
		tipo_caracterizacion_rango_id: z.string().uuid('Tipo de caracterizacion requerido'),
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		observaciones: z.string().trim().nullable().optional().default(null)
	})
	.refine((input) => input.v_ini <= input.v_fin, {
		message: 'El verso inicial no puede ser mayor que el final',
		path: ['v_ini']
	});

export const secuenciaSubtipoEstrofaInputSchema = z
	.object({
		subtipo_estrofa_id: z.string().uuid('Subtipo de estrofa requerido'),
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive()
	})
	.refine((input) => input.v_ini <= input.v_fin, {
		message: 'El verso inicial no puede ser mayor que el final',
		path: ['v_ini']
	});

export const estadoInputSchema = z.object({
	estado: z.string().uuid(),
	comentario: z.string().trim().max(2000).optional()
});

function validateSingleCommentContext(
	data: {
		seccion?: (typeof COMENTARIO_SECCIONES)[number];
		secuencia_id?: string;
		jornada_id?: string;
		cuadro_id?: string;
	},
	ctx: z.RefinementCtx
) {
	const refs = [data.secuencia_id, data.jornada_id, data.cuadro_id].filter(Boolean);
	if (refs.length > 1) {
		ctx.addIssue({
			code: z.ZodIssueCode.custom,
			message: 'Solo se puede asociar un contexto por comentario.',
			path: ['secuencia_id']
		});
	}
	if (data.seccion && refs.length > 0) {
		ctx.addIssue({
			code: z.ZodIssueCode.custom,
			message: 'La sección no se puede combinar con un contexto específico.',
			path: ['seccion']
		});
	}
}

export const comentarioInputSchema = z
	.object({
		comentario: z.string().trim().min(1).max(4000),
		tipo_comentario: comentarioTipoInputSchema.optional().default('general'),
		seccion: z.enum(COMENTARIO_SECCIONES).optional(),
		secuencia_id: z.string().uuid().optional(),
		jornada_id: z.string().uuid().optional(),
		cuadro_id: z.string().uuid().optional()
	})
	.superRefine(validateSingleCommentContext);

export const comentarioPatchSchema = z.object({
	comentario: z.string().trim().min(1).max(4000),
	tipo_comentario: comentarioTipoPatchSchema.optional()
});

export const comentarioPublicacionPatchSchema = z.object({
	visible_publico: z.boolean()
});

export const comentarioListQuerySchema = z
	.object({
		seccion: z.enum(COMENTARIO_SECCIONES).optional(),
		secuencia_id: z.string().uuid().optional(),
		jornada_id: z.string().uuid().optional(),
		cuadro_id: z.string().uuid().optional(),
		limit: z.coerce.number().int().positive().max(5000).optional().default(1000),
		offset: z.coerce.number().int().min(0).optional().default(0)
	})
	.superRefine(validateSingleCommentContext);

const autoriaAtribucionAutorSchema = z
	.object({
		autor_id: z.string().uuid(),
		orden: z.coerce.number().int().positive().optional().nullable().default(null)
	})
	.strict();

const autoriaEvidenciaSchema = z
	.object({
		atribucion_evidencia_id: z.string().uuid().optional().nullable().default(null),
		tipo_atribucion_id: z.string().uuid('Tipo de atribucion requerido'),
		fuente_autoria: nullableText(20000)
	})
	.strict();

const autoriaPropuestaSchema = z
	.object({
		atribucion_id: z.string().uuid().optional().nullable().default(null),
		composicion_autoria_id: z.string().uuid('Tipologia de autoria requerida'),
		perfil_metrico: z.boolean().optional().default(false),
		autores: z
			.array(autoriaAtribucionAutorSchema)
			.default([])
			.transform((items) => {
				const seen = new Set<string>();
				const output: Array<{ autor_id: string; orden: number | null }> = [];
				for (const item of items) {
					if (seen.has(item.autor_id)) continue;
					seen.add(item.autor_id);
					output.push(item);
				}
				return output.map((item, index) => ({
					autor_id: item.autor_id,
					orden: item.orden ?? index + 1
				}));
			}),
		evidencias: z
			.array(autoriaEvidenciaSchema)
			.default([])
	})
	.strict();

const grupoAtribucionSchema = z
	.object({
		grupo_atribucion_id: z.string().uuid().optional().nullable().default(null),
		jornada_id: z.string().uuid().optional().nullable().default(null),
		propuestas: z.array(autoriaPropuestaSchema).default([])
	})
	.strict();

export const autoriaInputSchema = z
	.object({
		grupos: z.array(grupoAtribucionSchema).default([])
	})
	.strict();

export const observacionesInputSchema = z
	.object({
		observaciones: nullableText(60000),
		bibliografia: nullableText(20000)
	})
	.strict();

export const visibilidadInputSchema = z.object({
	visible_publico: z.boolean()
});

export const seccionPublicaPatchSchema = z
	.object({
		activa: z.boolean().optional(),
		scope_minimo: z.enum(['anon', 'authenticated', 'admin_ip']).optional()
	})
	.refine((value) => value.activa !== undefined || value.scope_minimo !== undefined, {
		message: 'Indica al menos un campo a actualizar (activa o scope_minimo).'
	});

export const obraCreateSchema = z.object({
	titulo: z.string().trim().min(1, 'El titulo es obligatorio').max(300),
	editor_asignado: z.string().uuid('Editor asignado invalido'),
	genero_id: z.string().uuid().optional().nullable().default(null)
});

export const obraDeleteSchema = z.object({
	confirmText: z
		.string()
		.trim()
		.refine((value) => value === 'ELIMINAR', { message: 'Debes escribir ELIMINAR para confirmar.' })
});

const authorVariantsBaseSchema = z.array(z.string().trim().max(200)).transform((items) => {
	const seen = new Set<string>();
	const output: string[] = [];
	for (const item of items) {
		const trimmed = item.trim();
		if (!trimmed) continue;
		const key = trimmed.normalize('NFD').replaceAll(/\p{M}/gu, '').toLowerCase();
		if (seen.has(key)) continue;
		seen.add(key);
		output.push(trimmed);
	}
	return output;
});

const authorVariantsSchema = authorVariantsBaseSchema.default([]);

const optionalAuthorExternalId = z
	.union([z.string().max(20), z.null(), z.undefined()])
	.transform((value) => {
		if (typeof value !== 'string') return null;
		const trimmed = value.trim();
		return trimmed.length > 0 ? trimmed : null;
	});

const optionalAuthorExternalIdPatch = z
	.union([z.string().max(20), z.null(), z.undefined()])
	.transform((value) => {
		if (value === undefined) return undefined;
		if (value === null) return null;
		const trimmed = value.trim();
		return trimmed.length > 0 ? trimmed : null;
	});

export const autorCreateSchema = z.object({
	nombre_completo: z.string().trim().min(1, 'El nombre completo es obligatorio').max(200),
	nombre_normalizado: z.string().trim().min(1, 'El nombre normalizado es obligatorio').max(200),
	variantes_nombre: authorVariantsSchema,
	bnedatos_id: optionalAuthorExternalId,
	viaf_id: optionalAuthorExternalId,
	wikidata_id: optionalAuthorExternalId,
	confirm_similar: z.boolean().optional().default(false)
});

export const autorPatchSchema = z
	.object({
		nombre_completo: z.string().trim().min(1, 'El nombre completo es obligatorio').max(200).optional(),
		nombre_normalizado: z
			.string()
			.trim()
			.min(1, 'El nombre normalizado es obligatorio')
			.max(200)
			.optional(),
		variantes_nombre: authorVariantsBaseSchema.optional(),
		bnedatos_id: optionalAuthorExternalIdPatch,
		viaf_id: optionalAuthorExternalIdPatch,
		wikidata_id: optionalAuthorExternalIdPatch
	})
	.refine((payload) => Object.values(payload).some((value) => value !== undefined), {
		message: 'No hay campos para actualizar'
	});

export const autorDeleteSchema = z.object({
	confirmText: z
		.string()
		.trim()
		.refine((value) => value === 'ELIMINAR', { message: 'Debes escribir ELIMINAR para confirmar.' })
});

export const vocabularioDeleteSchema = z.object({
	confirmText: z
		.string()
		.trim()
		.refine((value) => value === 'ELIMINAR', { message: 'Debes escribir ELIMINAR para confirmar.' })
});

const optionalIdentifierInput = z
	.union([z.string(), z.null(), z.undefined()])
	.transform((value) => {
		if (typeof value !== 'string') return undefined;
		const trimmed = value.trim();
		return trimmed.length > 0 ? trimmed : undefined;
	});

const reviewerIdsSchema = z
	.array(z.union([z.string(), z.null(), z.undefined()]))
	.default([])
	.transform((ids) =>
		ids
			.map((value) => (typeof value === 'string' ? value.trim() : ''))
			.filter((value) => value.length > 0)
	)
	.transform((ids) => [...new Set(ids)]);

export const obraAssignmentsInputSchema = z.object({
	editor_asignado: optionalIdentifierInput,
	reviewer_ids: reviewerIdsSchema
});

// Backward compatible schema used by legacy callers during transition.
export const obraReviewersInputSchema = z.object({
	reviewer_ids: reviewerIdsSchema
});

export const vocabularioCreateSchema = z.object({
	categoria: z.string().trim().min(1).max(80),
	termino: z.string().trim().min(1).max(200),
	etiqueta: z.string().trim().max(200).optional().nullable().default(null),
	termino_padre_id: z.string().uuid().optional().nullable().default(null),
	nivel: z.number().int().optional().nullable().default(null),
	orden: z.number().int().optional().nullable().default(null),
	definicion: z.string().trim().max(10000).optional().nullable().default(null),
	ejemplo: z.string().trim().max(4000).optional().nullable().default(null),
	bibliografia: z.string().trim().max(10000).optional().nullable().default(null),
	equivalencias: z.array(z.string().trim().min(1).max(200)).optional().nullable().default(null),
	patron_especifico: z.string().trim().max(2000).optional().nullable().default(null),
	tipo_forma: z
		.enum(['forma_espanola', 'forma_italiana'])
		.optional()
		.nullable()
		.default(null),
	tipo_rima_id: nullableUuid,
	naturaleza_estrofica_id: nullableUuid,
	tamanio_unidad_estrofica: z.number().int().positive().optional().nullable().default(null),
	numero_silabas: z.number().int().positive().optional().nullable().default(null),
	metro_ids: z.array(z.string().uuid()).optional().nullable().default(null),
	activo: z.boolean().optional().default(true)
});

export const vocabularioPatchSchema = z
	.object({
		termino: z.string().trim().min(1).max(200).optional(),
		etiqueta: z.string().trim().max(200).optional().nullable(),
		termino_padre_id: z.string().uuid().optional().nullable(),
		nivel: z.number().int().optional().nullable(),
		orden: z.number().int().optional().nullable(),
		definicion: z.string().trim().max(10000).optional().nullable(),
		ejemplo: z.string().trim().max(4000).optional().nullable(),
		bibliografia: z.string().trim().max(10000).optional().nullable(),
		equivalencias: z.array(z.string().trim().min(1).max(200)).optional().nullable(),
		patron_especifico: z.string().trim().max(2000).optional().nullable(),
		tipo_forma: z.enum(['forma_espanola', 'forma_italiana']).optional().nullable(),
		tipo_rima_id: optionalNullableUuidPatch,
		naturaleza_estrofica_id: optionalNullableUuidPatch,
		tamanio_unidad_estrofica: z.number().int().positive().optional().nullable(),
		numero_silabas: z.number().int().positive().optional().nullable(),
		metro_ids: z.array(z.string().uuid()).optional().nullable(),
		activo: z.boolean().optional()
	})
	.refine((payload) => Object.keys(payload).length > 0, {
		message: 'No hay campos para actualizar'
	});

export const vocabularioReorderSchema = z
	.object({
		categoria: z.string().trim().min(1).max(80),
		items: z
			.array(
				z.object({
					termino_id: z.string().uuid(),
					termino_padre_id: z.string().uuid().nullable(),
					orden: z.number().int().nonnegative(),
					nivel: z.number().int().positive().nullable()
				})
			)
			.min(1)
	})
	.superRefine((payload, ctx) => {
		const seen = new Set<string>();
		for (const item of payload.items) {
			if (seen.has(item.termino_id)) {
				ctx.addIssue({
					code: z.ZodIssueCode.custom,
					path: ['items'],
					message: 'Hay términos duplicados en la reordenación'
				});
				return;
			}
			seen.add(item.termino_id);
		}
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
export type SecuenciaCaracterizacionRangoInputParsed = z.infer<
	typeof secuenciaCaracterizacionRangoInputSchema
>;
export type SecuenciaSubtipoEstrofaInputParsed = z.infer<typeof secuenciaSubtipoEstrofaInputSchema>;
export type EstadoInputParsed = z.infer<typeof estadoInputSchema>;
export type ComentarioInputParsed = z.infer<typeof comentarioInputSchema>;
export type ComentarioPatchParsed = z.infer<typeof comentarioPatchSchema>;
export type ComentarioPublicacionPatchParsed = z.infer<typeof comentarioPublicacionPatchSchema>;
export type ComentarioListQueryParsed = z.infer<typeof comentarioListQuerySchema>;
export type AutoriaInputParsed = z.infer<typeof autoriaInputSchema>;
export type ObservacionesInputParsed = z.infer<typeof observacionesInputSchema>;
export type VisibilidadInputParsed = z.infer<typeof visibilidadInputSchema>;
export type ObraCreateParsed = z.infer<typeof obraCreateSchema>;
export type ObraDeleteParsed = z.infer<typeof obraDeleteSchema>;
export type AutorCreateParsed = z.infer<typeof autorCreateSchema>;
export type AutorPatchParsed = z.infer<typeof autorPatchSchema>;
export type AutorDeleteParsed = z.infer<typeof autorDeleteSchema>;
export type VocabularioDeleteParsed = z.infer<typeof vocabularioDeleteSchema>;
export type ObraAssignmentsInputParsed = z.infer<typeof obraAssignmentsInputSchema>;
export type ObraReviewersInputParsed = z.infer<typeof obraReviewersInputSchema>;
export type VocabularioCreateParsed = z.infer<typeof vocabularioCreateSchema>;
export type VocabularioPatchParsed = z.infer<typeof vocabularioPatchSchema>;
export type VocabularioReorderParsed = z.infer<typeof vocabularioReorderSchema>;
