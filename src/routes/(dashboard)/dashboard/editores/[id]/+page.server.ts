import { error } from '@sveltejs/kit';
import { z } from 'zod';
import type { PageServerLoad } from './$types';
import { requireEditorManager, loadManagedEditors } from '$lib/server/editor-management';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';

export const load: PageServerLoad = async ({ locals, params }) => {
	const manager = await requireEditorManager(locals);
	if (!z.string().uuid().safeParse(params.id).success) throw error(404, 'Editor no encontrado.');
	const [{ editors, works }, states] = await Promise.all([
		loadManagedEditors(locals),
		loadInternalVocabulario(locals.supabase, ['estado'])
	]);
	const editor = editors.find((row) => row.user_id === params.id);
	if (!editor) throw error(404, 'Editor no encontrado.');
	return {
		editor,
		canToggleActive: editor.roleTerm === 'editor' && editor.user_id !== manager.userId,
		editorOptions: editors.map(({ user_id, nombre_completo, activo }) => ({
			user_id,
			nombre_completo,
			activo
		})),
		works: works.map((work) => ({
			...work,
			estadoTerm: states.find((row) => row.termino_id === work.estado)?.termino ?? '',
			editorNombre:
				editors.find((row) => row.user_id === work.editor_asignado)?.nombre_completo ??
				'Sin asignar',
			canEditContent: true
		}))
	};
};
