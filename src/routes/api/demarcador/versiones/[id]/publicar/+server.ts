import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';

export const POST: RequestHandler = async ({ locals, params }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden publicar el demarcador.');
	}

	const { data, error } = await locals.supabase.rpc('publicar_demarcador_version', {
		p_version_id: params.id
	});

	if (error) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo publicar la versión: ${error.message}`
			},
			{ status: 500 }
		);
	}

	return json({ version: data });
};
