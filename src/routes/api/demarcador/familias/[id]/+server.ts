import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';

const politicaSchema = z.object({
	politica: z.enum(['familia', 'variantes'])
});

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden revisar la política del demarcador.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = politicaSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const revisadoEn = new Date().toISOString();
	const { data, error } = await locals.supabase
		.from('demarcador_familias_config')
		.upsert(
			{
				familia_id: params.id,
				politica: parsed.data.politica,
				revisado_por: profile.userId,
				revisado_en: revisadoEn
			},
			{ onConflict: 'familia_id' }
		)
		.select('familia_id,politica,revisado_en')
		.single();

	if (error) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo guardar la política de esta familia: ${error.message}`
			},
			{ status: 500 }
		);
	}

	return json({ configuracion: data });
};
