import type { PageServerLoad } from './$types';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'laboratorio');
	return {};
};
