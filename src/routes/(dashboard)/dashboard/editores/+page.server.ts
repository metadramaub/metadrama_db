import type { PageServerLoad } from './$types';
import { requireEditorManager, loadManagedEditors } from '$lib/server/editor-management';

export const load: PageServerLoad = async ({ locals }) => {
	await requireEditorManager(locals);
	const { editors } = await loadManagedEditors(locals);
	return { editors };
};
