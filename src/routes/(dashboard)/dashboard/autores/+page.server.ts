import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getAuthorWorksCountMap } from '$lib/server/autores';
import type { AuthorListItem } from '$lib/types/author.types';
import type { Tables } from '$lib/types/database.types';
import { canManageAutores } from '$lib/utils/permissions';

function normalizeSearchTerm(value: string): string {
	return value.normalize('NFD').replaceAll(/\p{M}/gu, '').trim().toLowerCase();
}

function matchesSearch(author: Tables<'autores'>, term: string): boolean {
	if (!term) return true;
	const fullName = normalizeSearchTerm(author.nombre_completo ?? '');
	const normalizedName = normalizeSearchTerm(author.nombre_normalizado ?? '');
	const variants = (author.variantes_nombre ?? []).map((item) => normalizeSearchTerm(item));
	return (
		fullName.includes(term) ||
		normalizedName.includes(term) ||
		variants.some((variant) => variant.includes(term))
	);
}

export const load: PageServerLoad = async ({ locals, parent, url }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const q = url.searchParams.get('q')?.trim() ?? '';
	const normalizedQuery = normalizeSearchTerm(q);

	const { data, error: dbError } = await locals.supabase
		.from('autores')
		.select('*')
		.order('nombre_normalizado', { ascending: true })
		.order('nombre_completo', { ascending: true });

	if (dbError) {
		throw error(500, `No se pudieron cargar los autores: ${dbError.message}`);
	}

	const rows = ((data ?? []) as Tables<'autores'>[]).filter((row) => matchesSearch(row, normalizedQuery));
	const countResult = await getAuthorWorksCountMap(
		locals.supabase,
		rows.map((row) => row.autor_id)
	);
	if (countResult.errorMessage) {
		throw error(500, `No se pudieron cargar las obras por autor: ${countResult.errorMessage}`);
	}

	const authors: AuthorListItem[] = rows.map((row) => ({
		...row,
		works_count: countResult.counts.get(row.autor_id) ?? 0
	}));

	return {
		profile,
		canManageAuthors: canManageAutores(profile.roleTerm),
		filters: { q },
		authors
	};
};
