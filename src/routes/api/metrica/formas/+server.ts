import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';
import {
	METRIC_CATALOG_REVIEW_STATES,
	METRIC_ENTRY_TYPES,
	METRIC_STRUCTURAL_LEVELS
} from '$lib/metrica/catalogo';

type UntypedSupabaseClient = {
	from: (table: string) => any;
};

const slugSchema = z
	.string()
	.trim()
	.min(1)
	.max(160)
	.regex(/^[\p{L}\p{N}_-]+$/u, 'Usa letras, números, guiones o guiones bajos.');

const formFieldsSchema = z.object({
	slug: slugSchema,
	nombre: z.string().trim().min(1).max(240),
	definicion: z.string().trim().max(30_000).nullable(),
	nivel_estructural: z.enum(METRIC_STRUCTURAL_LEVELS),
	tipo_registro: z.enum(METRIC_ENTRY_TYPES),
	seleccionable: z.boolean(),
	estado_revision: z.enum(METRIC_CATALOG_REVIEW_STATES),
	activo: z.boolean(),
	orden: z.number().int().nullable()
});

const createSchema = formFieldsSchema;
const updateSchema = formFieldsSchema.extend({ forma_id: z.uuid() });

async function requireCatalogManager(locals: App.Locals) {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return { profile, forbidden: true as const };
	}
	return { profile, forbidden: false as const };
}

export const POST: RequestHandler = async ({ locals, request }) => {
	const access = await requireCatalogManager(locals);
	if (access.forbidden) {
		return forbiddenResponse('Solo admin o IP pueden crear formas métricas.');
	}

	const parsed = createSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	if (
		parsed.data.tipo_registro === 'sin_forma' &&
		!parsed.data.seleccionable
	) {
		return json(
			{
				error: 'validation_error',
				message:
					'Un tramo sin forma no tiene grado de especificación y debe seguir siendo seleccionable.'
			},
			{ status: 422 }
		);
	}

	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const { data, error } = await db
		.from('formas_metricas')
		.insert({
			...parsed.data,
			created_by: access.profile.userId,
			updated_by: access.profile.userId
		})
		.select(
			'forma_id,slug,nombre,definicion,nivel_estructural,tipo_registro,seleccionable,estado_revision,activo,orden,origen_termino_id,updated_at'
		)
		.single();

	if (error) {
		const conflict = error.code === '23505';
		return json(
			{
				error: conflict ? 'conflict' : 'db_error',
				message: conflict ? 'Ya existe una forma con ese slug.' : error.message
			},
			{ status: conflict ? 409 : 500 }
		);
	}

	return json({ form: data }, { status: 201 });
};

export const PATCH: RequestHandler = async ({ locals, request }) => {
	const access = await requireCatalogManager(locals);
	if (access.forbidden) {
		return forbiddenResponse('Solo admin o IP pueden modificar formas métricas.');
	}

	const parsed = updateSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	if (
		parsed.data.tipo_registro === 'sin_forma' &&
		!parsed.data.seleccionable
	) {
		return json(
			{
				error: 'validation_error',
				message:
					'Un tramo sin forma no tiene grado de especificación y debe seguir siendo seleccionable.'
			},
			{ status: 422 }
		);
	}

	const { forma_id, ...fields } = parsed.data;
	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const { data, error } = await db
		.from('formas_metricas')
		.update({ ...fields, updated_by: access.profile.userId })
		.eq('forma_id', forma_id)
		.select(
			'forma_id,slug,nombre,definicion,nivel_estructural,tipo_registro,seleccionable,estado_revision,activo,orden,origen_termino_id,updated_at'
		)
		.single();

	if (error) {
		const conflict = error.code === '23505';
		return json(
			{
				error: conflict ? 'conflict' : 'db_error',
				message: conflict ? 'Ya existe una forma con ese slug.' : error.message
			},
			{ status: conflict ? 409 : 500 }
		);
	}

	return json({ form: data });
};
