import { error, redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { getEditorProfile } from '$lib/server/auth';

export const load: LayoutServerLoad = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();

	if (!user) {
		const redirectTo = encodeURIComponent(url.pathname + url.search);
		throw redirect(303, `/login?redirectTo=${redirectTo}`);
	}

	const profile = await getEditorProfile({ locals }, user.id);

	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';
	if (isAdminOrIp) {
		const totalObrasResp = await locals.supabase.from('obras').select('obra_id', { count: 'exact', head: true });
		if (totalObrasResp.error) {
			throw error(500, `No se pudo calcular el total de obras: ${totalObrasResp.error.message}`);
		}
		return {
			user,
			profile,
			misObrasCount: totalObrasResp.count ?? 0
		};
	}

	const [asEditorResp, asReviewerResp] = await Promise.all([
		locals.supabase.from('obras').select('obra_id').eq('editor_asignado', profile.userId),
		locals.supabase.from('obras_revisores').select('obra_id').eq('revisor_id', profile.userId)
	]);
	const assignedIds = new Set<string>();
	for (const row of asEditorResp.data ?? []) {
		assignedIds.add(row.obra_id);
	}
	for (const row of asReviewerResp.data ?? []) {
		assignedIds.add(row.obra_id);
	}

	return {
		user,
		profile,
		misObrasCount: assignedIds.size
	};
};
