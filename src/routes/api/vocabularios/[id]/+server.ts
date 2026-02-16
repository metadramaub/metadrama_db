import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioPatchSchema } from '$lib/utils/validators';

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
		return json({ error: 'not_found', message: 'Termino no encontrado.' }, { status: 404 });
	}
	if (isProtectedVocabularyCategory(current.categoria)) {
		return forbiddenResponse('Esta categoria esta protegida y es de solo lectura.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const { metro_ids, ...vocabularioPayload } = payload;
	if (Object.prototype.hasOwnProperty.call(payload, 'termino_padre_id')) {
		const nextParentId = payload.termino_padre_id ?? null;
		if (nextParentId === current.termino_id) {
			return json(
				{ error: 'validation_error', message: 'Un termino no puede ser padre de si mismo.' },
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
					message: 'El termino padre debe existir y pertenecer a la misma categoria.'
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
					message: 'La relacion padre/hijo propuesta crea un ciclo no permitido.'
				},
				{ status: 400 }
			);
		}
	}

	let data: Record<string, unknown> | null = null;
	if (Object.keys(vocabularioPayload).length > 0) {
		const { data: updatedData, error } = await locals.supabase
			.from('vocabularios')
			.update(vocabularioPayload)
			.eq('termino_id', params.id)
			.select(vocabularySelect)
			.single();
		if (error || !updatedData) {
			return json(
				{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el termino.' },
				{ status: 500 }
			);
		}
		data = updatedData;
	} else {
		const { data: currentData, error } = await locals.supabase
			.from('vocabularios')
			.select(vocabularySelect)
			.eq('termino_id', params.id)
			.single();
		if (error || !currentData) {
			return json(
				{ error: 'db_error', message: error?.message ?? 'No se pudo leer el termino.' },
				{ status: 500 }
			);
		}
		data = currentData;
	}

	let metroIds: string[] = [];
	if (current.categoria === 'estrofa_tipo' && metro_ids !== undefined) {
		const syncResult = await syncEstrofaTipoMetros(locals, params.id, metro_ids ?? []);
		if (!syncResult.ok) {
			return json({ error: 'db_error', message: syncResult.message }, { status: syncResult.status });
		}
		metroIds = syncResult.metroIds;
	}

	return json({ vocabulario: data, metro_ids: metroIds });
};
