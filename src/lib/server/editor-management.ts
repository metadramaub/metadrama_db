import { error } from '@sveltejs/kit';
import { requireEditorProfile } from '$lib/server/auth';
import { canManageEditors, normalizeRole } from '$lib/utils/permissions';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';
import { capacidadesImportador, clienteImportador } from '$lib/server/importador-metrico/persistencia';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import type { ManagedEditor } from '$lib/types/editor-management.types';
import type { User } from '@supabase/supabase-js';

export async function requireEditorManager(locals: App.Locals) {
	const profile = await requireEditorProfile({ locals });
	if (!canManageEditors(profile.roleTerm))
		throw error(403, 'Solo administración o IP pueden gestionar editores.');
	return profile;
}

// PostgREST limita cada respuesta; se recorren todas las páginas sin truncar el reparto.
export async function loadAssignmentWorks(locals: App.Locals, soloDetalladas = false) {
	const works = [];
	const reviewers: { obra_id: string; revisor_id: string }[] = [];
	for (let offset = 0; ; offset += 500) {
		let query = locals.supabase
			.from('obras')
			.select('obra_id,titulo,slug,estado,editor_asignado,updated_at,visible_publico')
			.order('obra_id')
			.range(offset, offset + 499);
		if(soloDetalladas) query=query.eq('tipo_ficha','completa');
		const response=await query;
		if (response.error) throw error(500, 'No se pudieron cargar las obras.');
		works.push(...response.data);
		if (response.data.length < 500) break;
	}
	for (let offset = 0; ; offset += 500) {
		const response = await locals.supabase
			.from('obras_revisores')
			.select('obra_id,revisor_id')
			.order('obra_id')
			.order('revisor_id')
			.range(offset, offset + 499);
		if (response.error) throw error(500, 'No se pudieron cargar las revisiones asignadas.');
		reviewers.push(...response.data);
		if (response.data.length < 500) break;
	}
	const byWork = new Map<string, string[]>();
	for (const row of reviewers)
		byWork.set(row.obra_id, [...(byWork.get(row.obra_id) ?? []), row.revisor_id]);
	return works.map((work) => ({ ...work, reviewer_ids: byWork.get(work.obra_id) ?? [] }));
}

export function authInvitationState(
	user: Pick<User, 'email_confirmed_at' | 'last_sign_in_at' | 'invited_at'>
) {
	if (user.email_confirmed_at || user.last_sign_in_at) return 'accepted' as const;
	return user.invited_at ? ('sent' as const) : ('pending' as const);
}

export async function loadManagedEditors(locals: App.Locals) {
	const admin = getSupabaseAdmin();
	const importador = await capacidadesImportador(clienteImportador(locals.supabase));
	const [editorsResponse, roles, works] = await Promise.all([
		admin.from('editores').select('*').order('nombre_completo'),
		loadInternalVocabulario(locals.supabase, ['role_editor']),
		loadAssignmentWorks(locals, importador !== null)
	]);
	if (editorsResponse.error) throw error(500, 'No se pudieron cargar los editores.');
	const users = new Map<string, User>();
	for (let page = 1; ; page++) {
		const response = await admin.auth.admin.listUsers({ page, perPage: 100 });
		if (response.error) throw error(502, 'No se pudo consultar el estado de las invitaciones.');
		for (const user of response.data.users) users.set(user.id, user);
		if (response.data.users.length < 100) break;
	}
	const editors: ManagedEditor[] = editorsResponse.data.map((editor) => {
		const user = users.get(editor.user_id);
		if (!user) throw error(500, 'Un perfil editorial no tiene cuenta de acceso.');
		return {
			...editor,
			roleTerm: normalizeRole(roles.find((role) => role.termino_id === editor.role)?.termino),
			invitationStatus: authInvitationState(user),
			invitedAt: user.invited_at ?? null,
			lastSignInAt: user.last_sign_in_at ?? null,
			editingCount: works.filter((work) => work.editor_asignado === editor.user_id).length,
			reviewingCount: works.filter((work) => work.reviewer_ids.includes(editor.user_id)).length
		};
	});
	return { editors, works };
}
