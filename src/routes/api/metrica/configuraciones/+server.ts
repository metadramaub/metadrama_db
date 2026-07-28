import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';
import { METRIC_CATALOG_REVIEW_STATES, METRIC_CONFIGURATION_GRADES } from '$lib/metrica/catalogo';

type UntypedSupabaseClient = {
	from: (table: string) => any;
	rpc: (name: string, args: Record<string, unknown>) => any;
};

const nullablePositiveInteger = z.number().int().positive().nullable();
const slugSchema = z
	.string()
	.trim()
	.min(1)
	.max(160)
	.regex(/^[\p{L}\p{N}_-]+$/u, 'Usa letras, números, guiones o guiones bajos.');

const fieldsSchema = z
	.object({
		forma_id: z.uuid(),
		slug: slugSchema,
		nombre: z.string().trim().min(1).max(240),
		descripcion: z.string().trim().max(30_000).nullable(),
		principal: z.boolean(),
		demarcable: z.boolean(),
		grado: z.enum(METRIC_CONFIGURATION_GRADES),
		tipo_rima_id: z.uuid().nullable(),
		numero_versos: nullablePositiveInteger,
		estado_revision: z.enum(METRIC_CATALOG_REVIEW_STATES),
		activo: z.boolean(),
		orden: z.number().int().nullable()
	});

const createSchema = fieldsSchema;
const updateSchema = fieldsSchema.extend({ configuracion_id: z.uuid() });
const configurationSelect =
	'configuracion_id,forma_id,slug,nombre,descripcion,principal,demarcable,grado,tipo_rima_id,numero_versos,estado_revision,activo,orden,origen_termino_id,updated_at';

async function requireCatalogManager(locals: App.Locals) {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return { profile, forbidden: true as const };
	}
	return { profile, forbidden: false as const };
}

async function markAsPrincipal(
	db: UntypedSupabaseClient,
	configurationId: string,
	shouldBePrincipal: boolean
) {
	if (!shouldBePrincipal) return null;
	const { error } = await db.rpc('marcar_configuracion_metrica_principal', {
		p_configuracion_id: configurationId
	});
	return error;
}

export const POST: RequestHandler = async ({ locals, request }) => {
	const access = await requireCatalogManager(locals);
	if (access.forbidden) {
		return forbiddenResponse('Solo admin o IP pueden crear configuraciones métricas.');
	}

	const parsed = createSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);

	const { principal, ...fields } = parsed.data;
	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const { data: inserted, error: insertError } = await db
		.from('configuraciones_forma')
		.insert({
			...fields,
			principal: false,
			created_by: access.profile.userId,
			updated_by: access.profile.userId
		})
		.select(configurationSelect)
		.single();

	if (insertError) {
		const conflict = insertError.code === '23505';
		return json(
			{
				error: conflict ? 'conflict' : 'db_error',
				message: conflict
					? 'Ya existe una configuración con ese slug dentro de la forma.'
					: insertError.message
			},
			{ status: conflict ? 409 : 500 }
		);
	}

	const principalError = await markAsPrincipal(
		db,
		inserted.configuracion_id,
		principal && fields.activo
	);
	if (principalError) {
		return json(
			{
				error: 'db_error',
				message: `La configuración se creó, pero no pudo marcarse como principal: ${principalError.message}`
			},
			{ status: 500 }
		);
	}

	const { data, error } = await db
		.from('configuraciones_forma')
		.select(configurationSelect)
		.eq('configuracion_id', inserted.configuracion_id)
		.single();

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	return json({ configuration: data }, { status: 201 });
};

export const PATCH: RequestHandler = async ({ locals, request }) => {
	const access = await requireCatalogManager(locals);
	if (access.forbidden) {
		return forbiddenResponse('Solo admin o IP pueden modificar configuraciones métricas.');
	}

	const parsed = updateSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);

	const { configuracion_id, principal, ...fields } = parsed.data;
	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const { error: updateError } = await db
		.from('configuraciones_forma')
		.update({
			...fields,
			principal: false,
			updated_by: access.profile.userId
		})
		.eq('configuracion_id', configuracion_id);

	if (updateError) {
		const conflict = updateError.code === '23505';
		return json(
			{
				error: conflict ? 'conflict' : 'db_error',
				message: conflict
					? 'Ya existe una configuración con ese slug o ya hay otra principal.'
					: updateError.message
			},
			{ status: conflict ? 409 : 500 }
		);
	}

	const principalError = await markAsPrincipal(db, configuracion_id, principal && fields.activo);
	if (principalError) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo cambiar la configuración principal: ${principalError.message}`
			},
			{ status: 500 }
		);
	}

	const { data, error } = await db
		.from('configuraciones_forma')
		.select(configurationSelect)
		.eq('configuracion_id', configuracion_id)
		.single();

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	return json({ configuration: data });
};
