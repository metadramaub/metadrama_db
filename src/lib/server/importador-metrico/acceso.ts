import { error, type RequestEvent } from '@sveltejs/kit';
import { requireEditorProfile } from '$lib/server/auth';
import { capacidadesImportador, clienteImportador, ErrorImportacion } from './persistencia';

/** El ensayo precede a la migración de capacidades individuales. No consulta columnas futuras. */
export async function requireImportadorPreview(event: Pick<RequestEvent, 'locals'>) {
	return (await estadoImportador(event)).profile;
}

export async function estadoImportador(event: Pick<RequestEvent, 'locals'>) {
	const profile = await requireEditorProfile(event);
	let capacidades;
	try {
		capacidades = await capacidadesImportador(clienteImportador(event.locals.supabase));
	} catch (e) {
		throw error(
			e instanceof ErrorImportacion ? e.status : 503,
			'No se pudo comprobar el acceso al importador'
		);
	}
	if (!capacidades) {
		if (profile.roleTerm !== 'admin' && profile.roleTerm !== 'ip')
			throw error(403, 'El importador no está habilitado para esta sesión');
		return { profile, guardadoDisponible: false };
	}
	if (!capacidades.puede_importar)
		throw error(403, 'No tienes permiso para importar fichas básicas');
	return { profile, guardadoDisponible: capacidades.guardado_disponible };
}
