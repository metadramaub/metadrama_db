import { error, fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { estadoImportador } from '$lib/server/importador-metrico/acceso';
import {
	clienteImportador,
	listarBasicas,
	eliminarBasica,
	ErrorImportacion
} from '$lib/server/importador-metrico/persistencia';

export const load: PageServerLoad = async (event) => {
	const acceso = await estadoImportador(event);
	if (!acceso.guardadoDisponible)
		throw error(503, 'La consulta de fichas básicas aún no está habilitada.');
	const pagina = Number(event.url.searchParams.get('pagina') ?? '1');
	if (!Number.isSafeInteger(pagina) || pagina < 1 || pagina > 1_000_000)
		throw error(400, 'Página inválida');
	try {
		return {
			pagina,
			puedeEliminar: ['admin','ip'].includes(acceso.profile.roleTerm),
			...(await listarBasicas(clienteImportador(event.locals.supabase), (pagina - 1) * 50))
		};
	} catch (e) {
		throw error(
			e instanceof ErrorImportacion ? e.status : 503,
			'No se pudieron cargar las fichas básicas.'
		);
	}
};

export const actions: Actions = {
	eliminar: async (event) => {
		const acceso = await estadoImportador(event);
		if (!['admin','ip'].includes(acceso.profile.roleTerm)) throw error(403, 'Solo admin o IP pueden eliminar fichas básicas.');
		if (!acceso.guardadoDisponible) throw error(503, 'La gestión de fichas básicas no está disponible.');
		const form = await event.request.formData();
		const importacionId = String(form.get('importacion_id') ?? '');
		const confirmacion = String(form.get('confirmacion') ?? '');
		try {
			await eliminarBasica(clienteImportador(event.locals.supabase), importacionId, confirmacion);
		} catch (e) {
			return fail(e instanceof ErrorImportacion ? e.status : 503, {
				importacion_id: importacionId,
				mensaje: e instanceof ErrorImportacion ? e.message : 'No se pudo eliminar la ficha.'
			});
		}
		throw redirect(303, '/dashboard/importador/fichas' + event.url.search);
	}
};
