import type { PageServerLoad } from './$types';
import { canManageVocabularios } from '$lib/utils/permissions';
import type { Tables } from '$lib/types/database.types';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,termino_padre_id,nivel,orden,patron_especifico,activo')
		.order('categoria')
		.order('orden', { ascending: true });

	const vocabularios = (data ?? []) as Array<
		Pick<
			Tables<'vocabularios'>,
			'termino_id' | 'categoria' | 'termino' | 'termino_padre_id' | 'nivel' | 'orden' | 'patron_especifico' | 'activo'
		>
	>;

	return {
		profile,
		canManage: canManageVocabularios(profile.roleTerm),
		vocabularios
	};
};
