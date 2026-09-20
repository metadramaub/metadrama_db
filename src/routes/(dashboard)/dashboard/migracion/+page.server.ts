import type { PageServerLoad } from './$types';
import { getFechaDeGeneracion, getInformesVisibles } from '$lib/server/migracion-informes';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const { profile } = await parent();
	const informes = await getInformesVisibles(locals.supabase, profile);
	return { profile, informes, generado: getFechaDeGeneracion() };
};
