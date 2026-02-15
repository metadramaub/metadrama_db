import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';

const vocabularySelect =
	'termino_id,categoria,termino,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,activo';

export const load: PageServerLoad = async ({ locals, params, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const categoria = decodeURIComponent(params.categoria ?? '').trim();

	if (!categoria) {
		throw error(404, 'Categoría no encontrada');
	}

	const { data, error: dbError } = await locals.supabase
		.from('vocabularios')
		.select(vocabularySelect)
		.eq('categoria', categoria)
		.order('orden', { ascending: true })
		.order('termino', { ascending: true });

	if (dbError) {
		throw error(500, `No se pudieron cargar los vocabularios de ${categoria}: ${dbError.message}`);
	}

	if (!data || data.length === 0) {
		throw error(404, `No existe la categoría ${categoria}`);
	}

	const canManage = canManageVocabularios(profile.roleTerm);
	const isProtected = isProtectedVocabularyCategory(categoria);
	const canEdit = canManage && !isProtected;

	return {
		profile,
		categoria,
		canManage,
		isProtected,
		canEdit,
		vocabularios: data
	};
};
