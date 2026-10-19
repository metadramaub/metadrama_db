import { error, json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';
import { editorUpdateSchema } from '$lib/utils/editor-management';
import { validationErrorResponse } from '$lib/server/http';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { normalizeRole } from '$lib/utils/permissions';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const actor = await requireEditorManager(locals);
	if (!z.string().uuid().safeParse(params.id).success) throw error(404, 'Editor no encontrado.');
	const parsed = editorUpdateSchema.safeParse(await request.json().catch(() => null));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const admin = getSupabaseAdmin();
	const existing = await admin
		.from('editores')
		.select('user_id,role,activo')
		.eq('user_id', params.id)
		.maybeSingle();
	if (existing.error) throw error(500, 'No se pudo consultar el editor.');
	if (!existing.data) throw error(404, 'Editor no encontrado.');
	if (parsed.data.activo !== (existing.data.activo ?? true)) {
		const roles = await loadInternalVocabulario(locals.supabase, ['role_editor']);
		const role = normalizeRole(roles.find((r) => r.termino_id === existing.data!.role)?.termino);
		if (actor.userId === params.id || role !== 'editor') {
			throw error(403, 'Desde este panel solo se puede habilitar o deshabilitar a otros editores.');
		}
	}
	const updated = await admin
		.from('editores')
		.update(parsed.data)
		.eq('user_id', params.id)
		.select('user_id')
		.single();
	if (updated.error) throw error(500, 'No se pudo guardar el perfil del editor.');
	return json({ editor: updated.data });
};
