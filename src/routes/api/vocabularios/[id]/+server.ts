import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioPatchSchema } from '$lib/utils/validators';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden editar vocabularios.');
	}

	const { data: current } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria')
		.eq('termino_id', params.id)
		.maybeSingle();
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
	const { data, error } = await locals.supabase
		.from('vocabularios')
		.update(payload)
		.eq('termino_id', params.id)
		.select('termino_id,categoria,termino,termino_padre_id,nivel,orden,patron_especifico,activo')
		.single();
	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el término.' },
			{ status: 500 }
		);
	}

	return json({ vocabulario: data });
};
