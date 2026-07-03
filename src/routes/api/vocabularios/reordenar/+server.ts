import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';
import { vocabularioReorderSchema } from '$lib/utils/validators';
import { invalidateInternalCatalogCache } from '$lib/server/catalogos-internos';
import { invalidatePublicadoEstadoCache } from '$lib/server/public-obras';
import { invalidatePublicVocabularioCache } from '$lib/server/vocabulario-publico';

const vocabularySelect =
	'termino_id,categoria,termino,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,tipo_forma,tipo_rima_id,naturaleza_estrofica_id,tamanio_unidad_estrofica,arte_metrico,numero_silabas,activo';

type ExistingVocabularyRow = {
	termino_id: string;
	categoria: string;
	termino: string;
	termino_padre_id: string | null;
	nivel: number | null;
	orden: number | null;
	definicion: string | null;
	ejemplo: string | null;
	bibliografia: string | null;
	equivalencias: string[] | null;
	patron_especifico: string | null;
	tipo_forma: string | null;
	tipo_rima_id: string | null;
	naturaleza_estrofica_id: string | null;
	tamanio_unidad_estrofica: number | null;
	arte_metrico: string | null;
	numero_silabas: number | null;
	activo: boolean | null;
};

function hasCycle(parentMap: Map<string, string | null>) {
	const visited = new Set<string>();
	const visiting = new Set<string>();

	const visit = (id: string): boolean => {
		if (visiting.has(id)) return true;
		if (visited.has(id)) return false;
		visiting.add(id);
		const parent = parentMap.get(id) ?? null;
		if (parent && parentMap.has(parent) && visit(parent)) {
			return true;
		}
		visiting.delete(id);
		visited.add(id);
		return false;
	};

	for (const id of parentMap.keys()) {
		if (visit(id)) return true;
	}
	return false;
}

export const PUT: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden reordenar vocabularios.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = vocabularioReorderSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	if (isProtectedVocabularyCategory(payload.categoria)) {
		return forbiddenResponse('Esta categoría está protegida y es de solo lectura.');
	}

	const { data: existingRows, error: existingError } = await locals.supabase
		.from('vocabularios')
		.select(vocabularySelect)
		.eq('categoria', payload.categoria);
	if (existingError) {
		return json({ error: 'db_error', message: existingError.message }, { status: 500 });
	}

	const existing = (existingRows ?? []) as ExistingVocabularyRow[];
	if (existing.length === 0) {
		return json({ error: 'not_found', message: 'Categoría no encontrada.' }, { status: 404 });
	}

	if (existing.length !== payload.items.length) {
		return json(
			{
				error: 'validation_error',
				message: 'Debes enviar todos los términos de la categoría para reordenar.'
			},
			{ status: 400 }
		);
	}

	const existingById = new Map(existing.map((row) => [row.termino_id, row]));
	for (const item of payload.items) {
		if (!existingById.has(item.termino_id)) {
			return json(
				{ error: 'validation_error', message: 'Se encontraron términos fuera de la categoría indicada.' },
				{ status: 400 }
			);
		}
		if (item.termino_padre_id === item.termino_id) {
			return json(
				{ error: 'validation_error', message: 'Un término no puede ser padre de sí mismo.' },
				{ status: 400 }
			);
		}
		if (item.termino_padre_id && !existingById.has(item.termino_padre_id)) {
			return json(
				{ error: 'validation_error', message: 'Todos los padres deben pertenecer a la misma categoría.' },
				{ status: 400 }
			);
		}
	}

	const parentMap = new Map(payload.items.map((item) => [item.termino_id, item.termino_padre_id]));
	if (hasCycle(parentMap)) {
		return json(
			{ error: 'validation_error', message: 'La jerarquía propuesta contiene ciclos.' },
			{ status: 400 }
		);
	}

	const updates = payload.items.map(async (item) => {
		const { error: updateError } = await locals.supabase
			.from('vocabularios')
			.update({
				termino_padre_id: item.termino_padre_id,
				nivel: item.nivel,
				orden: item.orden
			})
			.eq('termino_id', item.termino_id)
			.eq('categoria', payload.categoria);

		return { terminoId: item.termino_id, error: updateError };
	});

	const updateResults = await Promise.all(updates);
	const firstUpdateError = updateResults.find((result) => result.error);
	if (firstUpdateError?.error) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo actualizar el término ${firstUpdateError.terminoId}: ${firstUpdateError.error.message}`
			},
			{ status: 500 }
		);
	}

	const { data: updatedRows, error: updatedError } = await locals.supabase
		.from('vocabularios')
		.select(vocabularySelect)
		.eq('categoria', payload.categoria)
		.order('orden', { ascending: true });
	if (updatedError) {
		return json({ error: 'db_error', message: updatedError.message }, { status: 500 });
	}

	invalidatePublicVocabularioCache();
	invalidateInternalCatalogCache();
	invalidatePublicadoEstadoCache();
	return json({ vocabularios: updatedRows ?? [] });
};
