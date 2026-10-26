import { error, type RequestEvent } from '@sveltejs/kit';
import { requireEditorProfile } from '$lib/server/auth';

/** El ensayo precede a la migración de capacidades individuales. No consulta columnas futuras. */
export async function requireImportadorPreview(event: Pick<RequestEvent, 'locals'>) {
	const profile = await requireEditorProfile(event);
	if (profile.roleTerm !== 'admin' && profile.roleTerm !== 'ip') {
		throw error(403, 'El ensayo del importador está disponible para admin/IP');
	}
	return profile;
}
