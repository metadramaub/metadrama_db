import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { countUnreadNotifications } from '$lib/server/dashboard';
import {
	capacidadesImportador,
	clienteImportador
} from '$lib/server/importador-metrico/persistencia';

export const GET: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });

	const importador = await capacidadesImportador(clienteImportador(locals.supabase));
	const notificationsUnreadCount = await countUnreadNotifications(
		locals,
		profile,
		7,
		importador !== null
	);

	return json({
		notificationsUnreadCount,
		generatedAt: new Date().toISOString()
	});
};
