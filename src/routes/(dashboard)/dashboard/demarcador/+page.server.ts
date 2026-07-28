import { error, redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManageVocabularios } from '$lib/utils/permissions';

export const load: PageServerLoad = async ({ parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	if (!canManageVocabularios(profile.roleTerm)) {
		throw error(403, 'Solo admin o IP pueden revisar la configuración del demarcador.');
	}

	throw redirect(307, '/dashboard/metrica?tab=validation');
};
