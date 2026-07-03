import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioDeleteSchema, vocabularioPatchSchema } from '$lib/utils/validators';
import { invalidateInternalCatalogCache } from '$lib/server/catalogos-internos';
import { invalidatePublicadoEstadoCache } from '$lib/server/public-obras';
import { invalidatePublicVocabularioCache } from '$lib/server/vocabulario-publico';

const vocabularySelect =
	'termino_id,categoria,termino,etiqueta,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,tipo_forma,tipo_rima_id,naturaleza_estrofica_id,tamanio_unidad_estrofica,arte_metrico,numero_silabas,activo';

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

async function getCurrentTerm(locals: App.Locals, terminoId: string) {
	const { data, error } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,termino_padre_id')
		.eq('termino_id', terminoId)
		.maybeSingle();

	if (error) {
		return {
			ok: false as const,
			status: 500,
			response: json({ error: 'db_error', message: error.message }, { status: 500 })
		};
	}
	if (!data) {
		return {
			ok: false as const,
			status: 404,
			response: json({ error: 'not_found', message: 'Término no encontrado.' }, { status: 404 })
		};
	}
	return { ok: true as const, term: data };
}

function detectDependencyTable(details?: string | null, message?: string | null) {
	const source = `${details ?? ''} ${message ?? ''}`;
	const tableMatch = source.match(/table\s+"([^"]+)"/i);
	return tableMatch?.[1]?.trim() ?? null;
}

function dependencyLabel(tableName: string | null) {
	switch (tableName) {
		case 'secuencias_metricas':
			return 'secuencias métricas';
		case 'estrofa_tipo_metros':
			return 'relaciones estrofa/metro';
		case 'vocabularios':
			return 'términos hijos en esta misma categoría';
		case 'secuencias_caracterizaciones_rango':
			return 'caracterizaciones por rango de secuencias';
		case 'secuencias_subtipos_estrofa':
			return 'subtipos internos de secuencias';
		case 'obras':
			return 'obras';
		case 'cuadros':
			return 'cuadros';
		case 'comentarios_internos':
			return 'comentarios internos';
		default:
			return 'registros relacionados';
	}
}

function buildDependencyMessage(term: string, tableName: string | null) {
	const label = dependencyLabel(tableName);
	return `No se puede eliminar el término "${term}" porque todavía se usa en ${label}. Reasigna o elimina esas referencias y vuelve a intentarlo.`;
}

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden editar vocabularios.');
	}

	const currentResult = await getCurrentTerm(locals, params.id);
	if (!currentResult.ok) {
		return currentResult.response;
	}
	const current = currentResult.term;
	if (isProtectedVocabularyCategory(current.categoria)) {
		return forbiddenResponse('Esta categoría está protegida y es de solo lectura.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const { metro_ids, ...vocabularioPayload } = payload;
	if (Object.prototype.hasOwnProperty.call(vocabularioPayload, 'etiqueta')) {
		// Cadena vacía -> null para que la ficha pública caiga al fallback (termino).
		vocabularioPayload.etiqueta = vocabularioPayload.etiqueta?.trim() ? vocabularioPayload.etiqueta.trim() : null;
	}
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

	let data: Record<string, unknown> | null = null;
	if (Object.keys(vocabularioPayload).length > 0) {
		const { data: updatedData, error } = await locals.supabase
			.from('vocabularios')
			.update(vocabularioPayload)
			.eq('termino_id', params.id)
			.select(vocabularySelect)
			.maybeSingle();
		if (error) {
			return json(
				{ error: 'db_error', message: error?.message ?? 'No se pudo actualizar el término.' },
				{ status: 500 }
			);
		}
		if (!updatedData) {
			return forbiddenResponse('No tienes permiso para editar este término.');
		}
		data = updatedData;
	} else {
		const { data: currentData, error } = await locals.supabase
			.from('vocabularios')
			.select(vocabularySelect)
			.eq('termino_id', params.id)
			.maybeSingle();
		if (error) {
			return json(
				{ error: 'db_error', message: error?.message ?? 'No se pudo leer el término.' },
				{ status: 500 }
			);
		}
		if (!currentData) {
			return forbiddenResponse('No tienes permiso para editar este término.');
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
		const { data: refreshedData, error } = await locals.supabase
			.from('vocabularios')
			.select(vocabularySelect)
			.eq('termino_id', params.id)
			.maybeSingle();
		if (error) {
			return json(
				{ error: 'db_error', message: error?.message ?? 'No se pudo leer el término actualizado.' },
				{ status: 500 }
			);
		}
		if (!refreshedData) {
			return forbiddenResponse('No tienes permiso para editar este término.');
		}
		data = refreshedData;
	}

	// El cambio de etiqueta/jerarquía debe reflejarse en las superficies públicas.
	invalidatePublicVocabularioCache();
	invalidateInternalCatalogCache();
	invalidatePublicadoEstadoCache();
	return json({ vocabulario: data, metro_ids: metroIds });
};

export const DELETE: RequestHandler = async ({ locals, params, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden eliminar vocabularios.');
	}

	const currentResult = await getCurrentTerm(locals, params.id);
	if (!currentResult.ok) {
		return currentResult.response;
	}
	const current = currentResult.term;
	if (isProtectedVocabularyCategory(current.categoria)) {
		return forbiddenResponse('Esta categoría está protegida y es de solo lectura.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioDeleteSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data, error } = await locals.supabase
		.from('vocabularios')
		.delete()
		.eq('termino_id', params.id)
		.select('termino_id')
		.maybeSingle();

	if (error) {
		const status = error.code === '23503' ? 409 : 500;
		const message =
			error.code === '23503'
				? buildDependencyMessage(current.termino, detectDependencyTable(error.details, error.message))
				: 'No se pudo eliminar el término.';
		return json(
			{
				error: 'db_error',
				message,
				details: error.message,
				dependencyTable:
					error.code === '23503'
						? detectDependencyTable(error.details, error.message)
						: null
			},
			{ status }
		);
	}
	if (!data) {
		return forbiddenResponse('No tienes permiso para eliminar este término.');
	}

	invalidatePublicVocabularioCache();
	invalidateInternalCatalogCache();
	invalidatePublicadoEstadoCache();
	return json({ deleted: true, terminoId: params.id });
};
