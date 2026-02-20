import { describe, expect, it } from 'vitest';
import {
	buildHierarchyRows,
	collectAncestorIds,
	filterHierarchyRows,
	type HierarchyInputItem
} from './check-dropdown-hierarchy';

describe('check-dropdown-hierarchy', () => {
	const sample: HierarchyInputItem[] = [
		{ id: 'root-a', label: 'Arte mayor' },
		{ id: 'child-a1', label: 'Octava real', parentId: 'root-a' },
		{ id: 'child-a2', label: 'Lira', parentId: 'root-a' },
		{ id: 'root-b', label: 'Arte menor' }
	];

	it('flattens hierarchy preserving parent-child depth', () => {
		const rows = buildHierarchyRows(sample);
		expect(rows.map((row) => `${row.id}:${row.depth}`)).toEqual([
			'root-a:1',
			'child-a1:2',
			'child-a2:2',
			'root-b:1'
		]);
	});

	it('builds path labels for child rows', () => {
		const rows = buildHierarchyRows(sample);
		const child = rows.find((row) => row.id === 'child-a1');
		expect(child?.pathLabel).toBe('Arte mayor > Octava real');
	});

	it('includes ancestors when filtering by child match', () => {
		const rows = buildHierarchyRows(sample);
		const filtered = filterHierarchyRows(rows, 'Octava');
		expect(filtered.map((row) => row.id)).toEqual(['root-a', 'child-a1']);
	});

	it('handles orphan and cyclic links without breaking', () => {
		const rows = buildHierarchyRows([
			{ id: 'a', label: 'A', parentId: 'b' },
			{ id: 'b', label: 'B', parentId: 'a' },
			{ id: 'orphan', label: 'Orfano', parentId: 'missing' }
		]);

		expect(new Set(rows.map((row) => row.id))).toEqual(new Set(['a', 'b', 'orphan']));
		expect(rows.every((row) => row.depth >= 1)).toBe(true);
	});

	it('returns selected ancestors only', () => {
		const rows = buildHierarchyRows(sample);
		const ancestors = collectAncestorIds(rows, ['child-a2']);
		expect(ancestors.has('root-a')).toBe(true);
		expect(ancestors.has('child-a2')).toBe(false);
	});
});
