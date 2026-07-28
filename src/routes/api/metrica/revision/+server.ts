import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';
import { METRIC_MIGRATION_CLASSIFICATIONS } from '$lib/metrica/catalogo';

type UntypedSupabaseClient = {
	rpc: (name: string, args: Record<string, unknown>) => any;
};

const changesSchema = z.object({
	changes: z
		.array(
			z.object({
				termino_id: z.uuid(),
				clasificacion_decidida: z.enum(METRIC_MIGRATION_CLASSIFICATIONS),
				estado_revision: z.enum(['pendiente', 'revisada']),
				notas_ip: z.string().trim().max(10_000).nullable()
			})
		)
		.min(1)
		.max(200)
});

export const PATCH: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden revisar la importación métrica.');
	}

	const parsed = changesSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);

	const ids = new Set<string>();
	for (const change of parsed.data.changes) {
		if (ids.has(change.termino_id)) {
			return json(
				{
					error: 'validation_error',
					message: 'Cada término debe aparecer una sola vez en el guardado.'
				},
				{ status: 422 }
			);
		}
		ids.add(change.termino_id);
	}

	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const { data, error } = await db.rpc('guardar_revision_migracion_metrica', {
		p_cambios: parsed.data.changes
	});

	if (error) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo guardar la revisión: ${error.message}`
			},
			{ status: 500 }
		);
	}

	return json({ saved: data ?? parsed.data.changes.length });
};
