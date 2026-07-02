import type { PageServerLoad } from './$types';
import {
	getAssignedEditorObras,
	getDashboardKpis,
	getPublishedAssignedSummary,
	getRecentActivity
} from '$lib/server/dashboard';

export const load: PageServerLoad = async ({ locals, parent, depends }) => {
	depends('dashboard:home');

	const parentData = await parent();
	const profile = parentData.profile;
	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';

	const [kpis, recentActivity, assignedEditorObras, publishedAssignedSummary] = await Promise.all([
		getDashboardKpis(locals, profile),
		getRecentActivity(locals, profile, 7, 20),
		isAdminOrIp ? Promise.resolve([]) : getAssignedEditorObras(locals, profile),
		isAdminOrIp
			? Promise.resolve({ total: 0, items: [] })
			: getPublishedAssignedSummary(locals, profile)
	]);

	return {
		profile,
		cardsScope: isAdminOrIp ? 'all' : 'mine',
		kpis,
		recentActivity,
		assignedEditorObras,
		publishedAssignedSummary
	};
};
