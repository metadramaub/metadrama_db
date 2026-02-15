import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getAuthorOrFail, getAuthorWorks } from '$lib/server/autores';
import { canDeleteAutores, canManageAutores } from '$lib/utils/permissions';

export const load: PageServerLoad = async ({ locals, parent, params }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	const autor = await getAuthorOrFail(locals.supabase, params.id);
	const worksResult = await getAuthorWorks(locals.supabase, autor.autor_id);
	if (worksResult.errorMessage) {
		throw error(500, `No se pudieron cargar las obras del autor: ${worksResult.errorMessage}`);
	}

	return {
		profile,
		autor,
		worksCount: worksResult.count,
		obras: worksResult.items,
		canManageAuthor: canManageAutores(profile.roleTerm),
		canDeleteAuthor: canDeleteAutores(profile.roleTerm)
	};
};
