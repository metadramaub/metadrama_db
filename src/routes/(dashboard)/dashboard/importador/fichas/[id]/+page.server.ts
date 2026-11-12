import { redirect } from '@sveltejs/kit';
import { cargarFichaBasica } from '$lib/server/importador-metrico/ficha-basica';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async (event) => {
	const ficha = await cargarFichaBasica(event, event.params.id);
	throw redirect(303, '/dashboard/obras/' + ficha.obraId + '?tab=basica');
};
