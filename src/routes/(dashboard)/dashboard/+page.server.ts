import type { PageServerLoad } from './$types';
import {
	getAssignedEditorObras,
	getDashboardKpis,
	getPublishedAssignedSummary,
	getRecentActivity
} from '$lib/server/dashboard';
import { getInformesVisibles } from '$lib/server/migracion-informes';

export const load: PageServerLoad = async ({ locals, parent, depends }) => {
	depends('dashboard:home');

	const parentData = await parent();
	const profile = parentData.profile;
	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';

	const [kpis, recentActivity, assignedEditorObras, publishedAssignedSummary, informesMigracion] =
		await Promise.all([
			getDashboardKpis(locals, profile),
			getRecentActivity(locals, profile, 7, 20),
			isAdminOrIp ? Promise.resolve([]) : getAssignedEditorObras(locals, profile),
			isAdminOrIp
				? Promise.resolve({ total: 0, items: [] })
				: getPublishedAssignedSummary(locals, profile),
			getInformesVisibles(locals.supabase, profile)
		]);

	return {
		profile,
		cardsScope: isAdminOrIp ? 'all' : 'mine',
		kpis,
		recentActivity,
		assignedEditorObras,
		publishedAssignedSummary,
		// La migración es un trabajo con final: la tarjeta aparece solo mientras a este perfil le
		// quede algún informe que leer, y desaparece sola cuando sus obras estén migradas.
		informesMigracion: informesMigracion.length
	};
};
