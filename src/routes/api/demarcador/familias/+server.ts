import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';

const configuracionesSchema = z
	.object({
		configuraciones: z
			.array(
				z.object({
					familia_id: z.uuid(),
					politica: z.enum(['familia', 'variantes'])
				})
			)
			.min(1)
			.max(200)
	})
	.superRefine(({ configuraciones }, context) => {
		const ids = new Set<string>();
		for (const [index, configuracion] of configuraciones.entries()) {
			if (ids.has(configuracion.familia_id)) {
				context.addIssue({
					code: 'custom',
					path: ['configuraciones', index, 'familia_id'],
					message: 'Cada familia debe aparecer una sola vez.'
				});
			}
			ids.add(configuracion.familia_id);
		}
	});

export const PATCH: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden revisar las políticas del demarcador.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = configuracionesSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const revisadoEn = new Date().toISOString();
	const rows = parsed.data.configuraciones.map((configuracion) => ({
		...configuracion,
		revisado_por: profile.userId,
		revisado_en: revisadoEn
	}));
	const { data, error } = await locals.supabase
		.from('demarcador_familias_config')
		.upsert(rows, { onConflict: 'familia_id' })
		.select('familia_id,politica,revisado_en');

	if (error) {
		return json(
			{
				error: 'db_error',
				message: `No se pudieron guardar las políticas: ${error.message}`
			},
			{ status: 500 }
		);
	}

	return json({ configuraciones: data ?? [] });
};
