import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { getEditorProfile } from '$lib/server/auth';

export const load: LayoutServerLoad = async ({ locals, url }) => {
	const { session, user } = await locals.safeGetSession();

	if (!session || !user) {
		const redirectTo = encodeURIComponent(url.pathname + url.search);
		throw redirect(303, `/login?redirectTo=${redirectTo}`);
	}

	const profile = await getEditorProfile({ locals }, user.id);

	const { count } = await locals.supabase
		.from('obras')
		.select('obra_id', { count: 'exact', head: true })
		.eq('editor_asignado', profile.userId);

	return {
		session,
		user,
		profile,
		misObrasCount: count ?? 0
	};
};
