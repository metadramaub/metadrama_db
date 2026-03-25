export type DashboardObrasScope = 'mine' | 'all';

export type DashboardObrasScopePlan =
	| {
			mode: 'all';
	  }
	| {
			mode: 'editor_only';
			editorAssignedUserId: string;
	  }
	| {
			mode: 'editor_or_reviewer';
			editorAssignedUserId: string;
			reviewerAssignedIds: string[];
	  };

export function resolveDashboardObrasScopePlan(
	scope: DashboardObrasScope,
	userId: string,
	reviewerAssignedIds: string[]
): DashboardObrasScopePlan {
	if (scope === 'all') {
		return { mode: 'all' };
	}

	const uniqueReviewerAssignedIds = [...new Set(reviewerAssignedIds)];
	if (uniqueReviewerAssignedIds.length === 0) {
		return {
			mode: 'editor_only',
			editorAssignedUserId: userId
		};
	}

	return {
		mode: 'editor_or_reviewer',
		editorAssignedUserId: userId,
		reviewerAssignedIds: uniqueReviewerAssignedIds
	};
}
