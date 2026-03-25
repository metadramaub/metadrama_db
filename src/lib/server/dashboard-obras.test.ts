import { describe, expect, it } from 'vitest';
import { resolveDashboardObrasScopePlan } from './dashboard-obras';

describe('resolveDashboardObrasScopePlan', () => {
	it('returns all mode for scope=all', () => {
		expect(resolveDashboardObrasScopePlan('all', 'user-1', ['obra-1', 'obra-2'])).toEqual({
			mode: 'all'
		});
	});

	it('returns editor_only for scope=mine with no reviewer assignments', () => {
		expect(resolveDashboardObrasScopePlan('mine', 'user-1', [])).toEqual({
			mode: 'editor_only',
			editorAssignedUserId: 'user-1'
		});
	});

	it('returns editor_or_reviewer for scope=mine with reviewer assignments', () => {
		expect(resolveDashboardObrasScopePlan('mine', 'user-1', ['obra-1', 'obra-2'])).toEqual({
			mode: 'editor_or_reviewer',
			editorAssignedUserId: 'user-1',
			reviewerAssignedIds: ['obra-1', 'obra-2']
		});
	});

	it('deduplicates reviewer assignment ids for scope=mine', () => {
		expect(resolveDashboardObrasScopePlan('mine', 'user-1', ['obra-1', 'obra-2', 'obra-1'])).toEqual({
			mode: 'editor_or_reviewer',
			editorAssignedUserId: 'user-1',
			reviewerAssignedIds: ['obra-1', 'obra-2']
		});
	});
});
