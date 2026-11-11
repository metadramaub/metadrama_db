import { error, redirect } from '@sveltejs/kit';
import { getObraContext } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { esFichaBasica, esObraSinFicha, requiereInicioCompleta } from '$lib/importador-metrico/tipo-ficha';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id);
	if (profile.roleTerm !== 'admin' && profile.roleTerm !== 'ip') throw error(403, 'Acceso reservado a admin e IP.');
	if (!esFichaBasica(obra) && !esObraSinFicha(obra) && !requiereInicioCompleta(obra)) {
		throw redirect(303, '/dashboard/obras/' + obra.obra_id);
	}
	const generoOptions = await loadInternalVocabulario(locals.supabase, ['genero']);
	return { obra, generoOptions, roleTerm: profile.roleTerm };
};
