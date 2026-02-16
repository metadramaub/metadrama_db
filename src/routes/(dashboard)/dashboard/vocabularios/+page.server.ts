import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';

type VocabularyCategorySummary = {
	categoria: string;
	total: number;
	rootCount: number;
	childCount: number;
	isProtected: boolean;
	editable: boolean;
};

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const canManage = canManageVocabularios(profile.roleTerm);

	const { data, error: dbError } = await locals.supabase
		.from('vocabularios')
		.select('categoria,termino_id,termino_padre_id');

	if (dbError) {
		throw error(500, `No se pudieron cargar las categorías de vocabulario: ${dbError.message}`);
	}

	const grouped = new Map<string, { total: number; rootCount: number; childCount: number }>();
	for (const row of data ?? []) {
		const key = row.categoria;
		const current = grouped.get(key) ?? { total: 0, rootCount: 0, childCount: 0 };
		current.total += 1;
		if (row.termino_padre_id) {
			current.childCount += 1;
		} else {
			current.rootCount += 1;
		}
		grouped.set(key, current);
	}

	const categories: VocabularyCategorySummary[] = [...grouped.entries()]
		.map(([categoria, stats]) => {
			const isProtected = isProtectedVocabularyCategory(categoria);
			return {
				categoria,
				total: stats.total,
				rootCount: stats.rootCount,
				childCount: stats.childCount,
				isProtected,
				editable: canManage && !isProtected
			};
		})
		.sort((a, b) => a.categoria.localeCompare(b.categoria, 'es'));

	return {
		profile,
		canManage,
		categories
	};
};
