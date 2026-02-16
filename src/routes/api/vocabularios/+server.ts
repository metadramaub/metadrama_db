import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioCreateSchema } from '$lib/utils/validators';

const vocabularySelect =
	'termino_id,categoria,termino,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,tipo_forma,activo';

async function syncEstrofaTipoMetros(locals: App.Locals, estrofaTipoId: string, metroIds: string[]) {
	const uniqueMetroIds = [...new Set(metroIds)];
	const { error: deleteError } = await locals.supabase
		.from('estrofa_tipo_metros')
		.delete()
		.eq('estrofa_tipo_id', estrofaTipoId);
	if (deleteError) {
		return { ok: false as const, status: 500, message: deleteError.message };
	}
	if (uniqueMetroIds.length === 0) {
		return { ok: true as const, metroIds: uniqueMetroIds };
	}

	const rows = uniqueMetroIds.map((metroId) => ({
		estrofa_tipo_id: estrofaTipoId,
		metro_id: metroId
	}));
	const { error: insertError } = await locals.supabase.from('estrofa_tipo_metros').insert(rows);
	if (insertError) {
		return { ok: false as const, status: 500, message: insertError.message };
	}
	return { ok: true as const, metroIds: uniqueMetroIds };
}

async function ensureParentInCategory(locals: App.Locals, categoria: string, parentId: string | null) {
	if (!parentId) return { ok: true as const };
	const { data: parent, error } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria')
		.eq('termino_id', parentId)
		.maybeSingle();
	if (error) {
		return { ok: false as const, status: 500, message: error.message };
	}
	if (!parent || parent.categoria !== categoria) {
		return {
			ok: false as const,
			status: 400,
			message: 'El término padre debe existir y pertenecer a la misma categoría.'
		};
	}
	return { ok: true as const };
}

async function resolveNextOrder(locals: App.Locals, categoria: string, parentId: string | null) {
	let query = locals.supabase.from('vocabularios').select('orden').eq('categoria', categoria);
	if (parentId) {
		query = query.eq('termino_padre_id', parentId);
	} else {
		query = query.is('termino_padre_id', null);
	}

	const { data, error } = await query;
	if (error) {
		return { ok: false as const, status: 500, message: error.message };
	}

	const maxOrder = Math.max(
		0,
		...(data ?? []).map((row: { orden: number | null }) => (typeof row.orden === 'number' ? row.orden : 0))
	);
	const nextOrder = (Math.floor(maxOrder / 10) + 1) * 10;
	return { ok: true as const, order: nextOrder };
}

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
		.select(vocabularySelect)
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
		return forbiddenResponse('La categoría indicada está protegida y no admite escritura.');
	}

	const parentCheck = await ensureParentInCategory(locals, payload.categoria, payload.termino_padre_id ?? null);
	if (!parentCheck.ok) {
		return json(
			{
				error: parentCheck.status === 500 ? 'db_error' : 'validation_error',
				message: parentCheck.message
			},
			{ status: parentCheck.status }
		);
	}

	let resolvedOrder = payload.orden ?? null;
	if (resolvedOrder === null) {
		const nextOrderResult = await resolveNextOrder(locals, payload.categoria, payload.termino_padre_id ?? null);
		if (!nextOrderResult.ok) {
			return json({ error: 'db_error', message: nextOrderResult.message }, { status: nextOrderResult.status });
		}
		resolvedOrder = nextOrderResult.order;
	}

	const { data, error } = await locals.supabase
		.from('vocabularios')
		.insert({
			categoria: payload.categoria,
			termino: payload.termino,
			termino_padre_id: payload.termino_padre_id,
			nivel: payload.nivel,
			orden: resolvedOrder,
			definicion: payload.definicion,
			ejemplo: payload.ejemplo,
			bibliografia: payload.bibliografia,
			equivalencias: payload.equivalencias,
			patron_especifico: payload.patron_especifico,
			tipo_forma: payload.tipo_forma,
			activo: payload.activo
		})
		.select(vocabularySelect)
		.single();

	if (error || !data) {
		const status = error?.message?.toLowerCase().includes('duplicate') ? 409 : 500;
		return json(
			{ error: status === 409 ? 'conflict' : 'db_error', message: error?.message ?? 'No se pudo crear el término.' },
			{ status }
		);
	}

	let metroIds: string[] = [];
	if (payload.categoria === 'estrofa_tipo') {
		const syncResult = await syncEstrofaTipoMetros(locals, data.termino_id, payload.metro_ids ?? []);
		if (!syncResult.ok) {
			await locals.supabase.from('vocabularios').delete().eq('termino_id', data.termino_id);
			return json({ error: 'db_error', message: syncResult.message }, { status: syncResult.status });
		}
		metroIds = syncResult.metroIds;
	}

	return json({ vocabulario: data, metro_ids: metroIds }, { status: 201 });
};
