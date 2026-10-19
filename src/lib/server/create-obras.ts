import { error } from '@sveltejs/kit';
import { loadInternalVocabulario } from './catalogos-internos';
import { normalizeWorkTitle } from '$lib/utils/editor-management';

export async function createObras(
	locals: App.Locals,
	titles: string[],
	editorId: string,
	genreId: string | null = null
) {
	const assigned = await locals.supabase
		.from('editores')
		.select('user_id,activo')
		.eq('user_id', editorId)
		.maybeSingle();
	if (assigned.error) throw error(500, 'No se pudo validar al editor.');
	if (!assigned.data || !assigned.data.activo)
		throw error(422, 'El editor seleccionado no existe o está deshabilitado.');
	const states = await loadInternalVocabulario(locals.supabase, ['estado']);
	const draft = states.find((row) => row.termino.toLowerCase() === 'borrador');
	if (!draft) throw error(500, 'No se encuentra el estado borrador.');
	// Un único INSERT: si falla una obra, no se crea ninguna del lote.
	const response = await locals.supabase
		.from('obras')
		.insert(
			titles.map((title) => ({
				titulo: title.trim(),
				titulo_normalizado: normalizeWorkTitle(title),
				editor_asignado: editorId,
				estado: draft.termino_id,
				genero_id: genreId
			}))
		)
		.select('*');
	if (response.error)
		throw error(500, 'No se pudieron crear las obras. No se ha creado ninguna del lote.');
	return response.data;
}
