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

	const version = await locals.supabase
		.from('demarcador_versiones')
		.select('version_id,fuente_tipo')
		.eq('version_id', params.id)
		.maybeSingle();
	if (version.error) {
		return json(
			{ error: 'db_error', message: `No se pudo comprobar la versión: ${version.error.message}` },
			{ status: 500 }
		);
	}
	if (!version.data) {
		return json({ error: 'not_found', message: 'Versión no encontrada.' }, { status: 404 });
	}
	if (version.data.fuente_tipo === 'catalogo_metrico') {
		return json(
			{
				error: 'catalog_preview',
				message:
					'Las versiones del nuevo catálogo son pruebas internas y todavía no se pueden publicar.'
			},
			{ status: 409 }
		);
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
