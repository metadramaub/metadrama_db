import { relacionObras } from '$lib/server/modelo-obras';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';
import { error } from '@sveltejs/kit';
import { loadInternalVocabulario } from './catalogos-internos';
import { normalizeWorkTitle } from '$lib/utils/editor-management';

export async function createObras(
	locals: App.Locals,
	titles: string[],
	editorId: string | null,
	genreId: string | null = null
) {
	if (!editorId && !modeloEditorialActivo()) throw error(422, 'Selecciona un editor responsable.');
	const assigned = editorId ? await locals.supabase
		.from('editores')
		.select('user_id,activo')
		.eq('user_id', editorId)
		.maybeSingle() : {data: {activo: true}, error: null};
	if (assigned.error) throw error(500, 'No se pudo validar al editor.');
	if (!assigned.data || !assigned.data.activo)
		throw error(422, 'El editor seleccionado no existe o está deshabilitado.');
	const states = await loadInternalVocabulario(locals.supabase, ['estado']);
	const draft = states.find((row) => row.termino.toLowerCase() === 'borrador');
	if (!draft) throw error(500, 'No se encuentra el estado borrador.');
	// Un único INSERT: si falla una obra, no se crea ninguna del lote.
	const response = await locals.supabase
		.from(relacionObras())
		.insert(
			titles.map((title) => ({
				titulo: title.trim(),
				titulo_normalizado: normalizeWorkTitle(title),
				editor_asignado: editorId,
				...(modeloEditorialActivo() ? {tipo_ficha: editorId ? 'completa' : 'sin_ficha'} : {}),
				estado: draft.termino_id,
				genero_id: genreId
			}))
		)
		.select('*');
	if (response.error)
		throw error(500, 'No se pudieron crear las obras. No se ha creado ninguna del lote.');
	return response.data;
}
