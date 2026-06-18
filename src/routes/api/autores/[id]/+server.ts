import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import {
	getAuthorOrFail,
	getAuthorWorks,
	normalizeAuthorSortName,
	normalizeAuthorVariants,
	normalizeExternalAuthorId
} from '$lib/server/autores';
import { conflictResponse, forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { requireEditorProfile } from '$lib/server/auth';
import { canDeleteAutores, canManageAutores } from '$lib/utils/permissions';
import { autorDeleteSchema, autorPatchSchema } from '$lib/utils/validators';

export const GET: RequestHandler = async ({ locals, params }) => {
	await requireEditorProfile({ locals });
	const autor = await getAuthorOrFail(locals.supabase, params.id);

	const worksResult = await getAuthorWorks(locals.supabase, autor.autor_id);
	if (worksResult.errorMessage) {
		return json({ error: 'db_error', message: worksResult.errorMessage }, { status: 500 });
	}

	return json({
		autor,
		works_count: worksResult.count,
		obras: worksResult.items
	});
};

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageAutores(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden editar autores.');
	}

	const current = await getAuthorOrFail(locals.supabase, params.id);
	const body = await request.json().catch(() => ({}));
	const parsed = autorPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const updatePayload: Record<string, unknown> = {};
	let nextNormalizedName: string | null = null;

	if (Object.prototype.hasOwnProperty.call(payload, 'nombre_completo')) {
		const nombreCompleto = payload.nombre_completo!.trim();
		updatePayload.nombre_completo = nombreCompleto;
	}

	if (Object.prototype.hasOwnProperty.call(payload, 'nombre_normalizado')) {
		nextNormalizedName = normalizeAuthorSortName(payload.nombre_normalizado!);
	}

	if (nextNormalizedName !== null) {
		const duplicateResp = await locals.supabase
			.from('autores')
			.select('autor_id')
			.eq('nombre_normalizado', nextNormalizedName)
			.neq('autor_id', current.autor_id)
			.limit(1);
		if (duplicateResp.error) {
			return json({ error: 'db_error', message: duplicateResp.error.message }, { status: 500 });
		}
		if ((duplicateResp.data ?? []).length > 0) {
			return conflictResponse('Ya existe un autor con el mismo nombre normalizado.');
		}
		updatePayload.nombre_normalizado = nextNormalizedName;
	}

	if (Object.prototype.hasOwnProperty.call(payload, 'variantes_nombre')) {
		updatePayload.variantes_nombre = normalizeAuthorVariants(payload.variantes_nombre ?? null);
	}
	if (Object.prototype.hasOwnProperty.call(payload, 'bnedatos_id')) {
		updatePayload.bnedatos_id = normalizeExternalAuthorId(payload.bnedatos_id);
	}
	if (Object.prototype.hasOwnProperty.call(payload, 'viaf_id')) {
		updatePayload.viaf_id = normalizeExternalAuthorId(payload.viaf_id);
	}
	if (Object.prototype.hasOwnProperty.call(payload, 'wikidata_id')) {
		updatePayload.wikidata_id = normalizeExternalAuthorId(payload.wikidata_id);
	}

	const { data, error } = await locals.supabase
		.from('autores')
		.update(updatePayload)
		.eq('autor_id', current.autor_id)
		.select('*')
		.single();
	if (error || !data) {
		if (error?.code === '23505') {
			return conflictResponse('Ya existe un autor con el mismo nombre normalizado.');
		}
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el autor.' },
			{ status: 500 }
		);
	}

	const worksResult = await getAuthorWorks(locals.supabase, data.autor_id);
	if (worksResult.errorMessage) {
		return json({ error: 'db_error', message: worksResult.errorMessage }, { status: 500 });
	}

	return json({
		autor: data,
		works_count: worksResult.count,
		obras: worksResult.items
	});
};

export const DELETE: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canDeleteAutores(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden eliminar autores.');
	}

	const autor = await getAuthorOrFail(locals.supabase, params.id);
	const body = await request.json().catch(() => ({}));
	const parsed = autorDeleteSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const worksResult = await getAuthorWorks(locals.supabase, autor.autor_id);
	if (worksResult.errorMessage) {
		return json({ error: 'db_error', message: worksResult.errorMessage }, { status: 500 });
	}
	if (worksResult.count > 0) {
		return conflictResponse('No se puede eliminar un autor vinculado a una o más obras.');
	}

	const { error } = await locals.supabase.from('autores').delete().eq('autor_id', autor.autor_id);
	if (error) {
		const status = error.code === '23503' ? 409 : 500;
		const message =
			error.code === '23503'
				? 'No se puede eliminar el autor por dependencias activas.'
				: 'No se pudo eliminar el autor.';
		return json({ error: 'db_error', message, details: error.message }, { status });
	}

	return json({ deleted: true, autorId: autor.autor_id });
};
