import { error, redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getObraContext } from '$lib/server/auth';
import { requiereInicioCompleta } from '$lib/importador-metrico/tipo-ficha';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';

export const load: PageServerLoad = async ({locals,params}) => {
	if (!modeloEditorialActivo()) throw error(404, 'Página no disponible.');
	const {obra,profile,assignedEditor} = await getObraContext({locals},params.id);
	if (obra.importacion_id || !requiereInicioCompleta(obra)) throw redirect(303, `/dashboard/obras/${obra.obra_id}`);
	return {obraId:obra.obra_id,titulo:obra.titulo,puedeIniciar:assignedEditor||['admin','ip'].includes(profile.roleTerm)};
};
