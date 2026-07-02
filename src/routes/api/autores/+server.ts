import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import {
	findSimilarAuthors,
	matchesAuthorSearch,
	getAuthorWorksCountMap,
	normalizeAuthorSearchTerm,
	normalizeAuthorSortName,
	normalizeAuthorVariants,
	normalizeExternalAuthorId
} from '$lib/server/autores';
import { conflictResponse, forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import type { AuthorListItem } from '$lib/types/author.types';
import type { Tables } from '$lib/types/database.types';
import { canCreateAutores } from '$lib/utils/permissions';
import { autorCreateSchema } from '$lib/utils/validators';

export const GET: RequestHandler = async ({ locals, url }) => {
	await requireEditorProfile({ locals });

	const q = url.searchParams.get('q')?.trim() ?? '';
	const normalizedQuery = normalizeAuthorSearchTerm(q);

	const { data, error } = await locals.supabase
		.from('autores')
		.select('*')
		.order('nombre_normalizado', { ascending: true })
		.order('nombre_completo', { ascending: true });
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	const authorRows = (data ?? []) as Tables<'autores'>[];
	const filteredRows = authorRows.filter((row) => matchesAuthorSearch(row, normalizedQuery));
	const countResult = await getAuthorWorksCountMap(
		locals.supabase,
		filteredRows.map((row) => row.autor_id)
	);
	if (countResult.errorMessage) {
		return json({ error: 'db_error', message: countResult.errorMessage }, { status: 500 });
	}

	const authors: AuthorListItem[] = filteredRows.map((row) => ({
		...row,
		works_count: countResult.counts.get(row.autor_id) ?? 0
	}));

	return json({ authors });
};

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canCreateAutores(profile.roleTerm)) {
		return forbiddenResponse('Tu rol no permite crear autores.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = autorCreateSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const nombreCompleto = payload.nombre_completo.trim();
	const nombreNormalizado = normalizeAuthorSortName(payload.nombre_normalizado);
	const variantes = normalizeAuthorVariants(payload.variantes_nombre);

	const duplicateResp = await locals.supabase
		.from('autores')
		.select('autor_id,nombre_completo')
		.eq('nombre_normalizado', nombreNormalizado)
		.limit(1);
	if (duplicateResp.error) {
		return json({ error: 'db_error', message: duplicateResp.error.message }, { status: 500 });
	}
	if ((duplicateResp.data ?? []).length > 0) {
		return conflictResponse('Ya existe un autor con el mismo nombre normalizado.');
	}

	if (!payload.confirm_similar) {
		const similarResp = await locals.supabase
			.from('autores')
			.select('autor_id,nombre_completo,nombre_normalizado,variantes_nombre')
			.order('nombre_normalizado', { ascending: true });
		if (similarResp.error) {
			return json({ error: 'db_error', message: similarResp.error.message }, { status: 500 });
		}

		const similarAuthors = findSimilarAuthors(
			{
				nombre_completo: nombreCompleto,
				nombre_normalizado: nombreNormalizado,
				variantes_nombre: variantes
			},
			(similarResp.data ?? []) as Pick<
				Tables<'autores'>,
				'autor_id' | 'nombre_completo' | 'nombre_normalizado' | 'variantes_nombre'
			>[]
		);

		if (similarAuthors.length > 0) {
			return json(
				{
					error: 'similar_author',
					message: 'Hay autores parecidos en la base de datos. Revisa las coincidencias antes de crear uno nuevo.',
					similarAuthors
				},
				{ status: 409 }
			);
		}
	}

	const { data, error } = await locals.supabase
		.from('autores')
		.insert({
			nombre_completo: nombreCompleto,
			nombre_normalizado: nombreNormalizado,
			variantes_nombre: variantes,
			bnedatos_id: normalizeExternalAuthorId(payload.bnedatos_id),
			viaf_id: normalizeExternalAuthorId(payload.viaf_id),
			wikidata_id: normalizeExternalAuthorId(payload.wikidata_id)
		})
		.select('*')
		.single();

	if (error || !data) {
		if (error?.code === '23505') {
			return conflictResponse('Ya existe un autor con el mismo nombre normalizado.');
		}
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo crear el autor.' },
			{ status: 500 }
		);
	}

	return json({ autor: data, works_count: 0 }, { status: 201 });
};
