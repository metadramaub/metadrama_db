import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioCreateSchema } from '$lib/utils/validators';

export const GET: RequestHandler = async ({ locals, url }) => {
	await requireEditorProfile({ locals });
	const categoriasParam = url.searchParams.get('categorias');
	const includeInactive = url.searchParams.get('includeInactive') === 'true';
	const categorias = categoriasParam
		? categoriasParam
				.split(',')
				.map((item) => item.trim())
				.filter(Boolean)
		: null;

	let query = locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,termino_padre_id,nivel,orden,patron_especifico,activo')
		.order('categoria')
		.order('orden', { ascending: true });

	if (!includeInactive) {
		query = query.eq('activo', true);
	}

	if (categorias && categorias.length > 0) {
		query = query.in('categoria', categorias);
	}

	const { data, error } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	return json({ vocabularios: data ?? [] });
};

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden crear vocabularios.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioCreateSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	if (isProtectedVocabularyCategory(payload.categoria)) {
		return forbiddenResponse('La categoria indicada esta protegida y no admite escritura.');
	}

	const { data, error } = await locals.supabase
		.from('vocabularios')
		.insert({
			categoria: payload.categoria,
			termino: payload.termino,
			termino_padre_id: payload.termino_padre_id,
			nivel: payload.nivel,
			orden: payload.orden,
			patron_especifico: payload.patron_especifico,
			activo: payload.activo
		})
		.select('termino_id,categoria,termino,termino_padre_id,nivel,orden,patron_especifico,activo')
		.single();

	if (error || !data) {
		const status = error?.message?.toLowerCase().includes('duplicate') ? 409 : 500;
		return json(
			{ error: status === 409 ? 'conflict' : 'db_error', message: error?.message ?? 'No se pudo crear el termino.' },
			{ status }
		);
	}

	return json({ vocabulario: data }, { status: 201 });
};
