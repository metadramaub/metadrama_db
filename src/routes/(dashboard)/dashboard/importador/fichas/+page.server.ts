import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { estadoImportador } from '$lib/server/importador-metrico/acceso';
import {
	clienteImportador,
	listarBasicas,
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
			...(await listarBasicas(clienteImportador(event.locals.supabase), (pagina - 1) * 50))
		};
	} catch (e) {
		throw error(
			e instanceof ErrorImportacion ? e.status : 503,
			'No se pudieron cargar las fichas básicas.'
		);
	}
};
