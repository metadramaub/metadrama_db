import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioPatchSchema } from '$lib/utils/validators';

const vocabularySelect =
	'termino_id,categoria,termino,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,activo';

function wouldCreateCycle(currentId: string, parentMap: Map<string, string | null>) {
	let cursor = parentMap.get(currentId) ?? null;
	const seen = new Set<string>();
	while (cursor) {
		if (cursor === currentId) return true;
		if (seen.has(cursor)) return true;
		seen.add(cursor);
		cursor = parentMap.get(cursor) ?? null;
	}
	return false;
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden editar vocabularios.');
	}

	const { data: current, error: currentError } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino_padre_id')
		.eq('termino_id', params.id)
		.maybeSingle();
	if (currentError) {
		return json({ error: 'db_error', message: currentError.message }, { status: 500 });
	}
	if (!current) {
		return json({ error: 'not_found', message: 'Término no encontrado.' }, { status: 404 });
	}
	if (isProtectedVocabularyCategory(current.categoria)) {
		return forbiddenResponse('Esta categoría está protegida y es de solo lectura.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	if (Object.prototype.hasOwnProperty.call(payload, 'termino_padre_id')) {
		const nextParentId = payload.termino_padre_id ?? null;
		if (nextParentId === current.termino_id) {
			return json(
				{ error: 'validation_error', message: 'Un término no puede ser padre de sí mismo.' },
				{ status: 400 }
			);
		}

		const { data: categoryItems, error: categoryError } = await locals.supabase
			.from('vocabularios')
			.select('termino_id,termino_padre_id')
			.eq('categoria', current.categoria);
		if (categoryError) {
			return json({ error: 'db_error', message: categoryError.message }, { status: 500 });
		}

		const ids = new Set((categoryItems ?? []).map((item) => item.termino_id));
		if (nextParentId && !ids.has(nextParentId)) {
			return json(
				{
					error: 'validation_error',
					message: 'El término padre debe existir y pertenecer a la misma categoría.'
				},
				{ status: 400 }
			);
		}

		const parentMap = new Map((categoryItems ?? []).map((item) => [item.termino_id, item.termino_padre_id]));
		parentMap.set(current.termino_id, nextParentId);
		if (wouldCreateCycle(current.termino_id, parentMap)) {
			return json(
				{
					error: 'validation_error',
					message: 'La relación padre/hijo propuesta crea un ciclo no permitido.'
				},
				{ status: 400 }
			);
		}
	}

	const { data, error } = await locals.supabase
		.from('vocabularios')
		.update(payload)
		.eq('termino_id', params.id)
		.select(vocabularySelect)
		.single();
	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el término.' },
			{ status: 500 }
		);
	}

	return json({ vocabulario: data });
};
