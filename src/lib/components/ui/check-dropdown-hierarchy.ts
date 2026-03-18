export type HierarchyInputItem = {
	id: string;
	label: string;
	parentId?: string | null;
};

export type HierarchyRow = {
	id: string;
	label: string;
	parentId: string | null;
	depth: number;
	pathLabel: string;
	ancestorIds: string[];
	hasChildren: boolean;
};

function normalizeInput(items: HierarchyInputItem[]) {
	const byId = new Map<string, HierarchyInputItem>();
	const orderedIds: string[] = [];

	for (const item of items) {
		if (!item?.id || byId.has(item.id)) continue;
		byId.set(item.id, item);
		orderedIds.push(item.id);
	}

	return { byId, orderedIds };
}

function resolveParentId(
	item: HierarchyInputItem,
	byId: Map<string, HierarchyInputItem>
): string | null {
	const rawParentId = item.parentId ?? null;
	if (!rawParentId) return null;
	if (rawParentId === item.id) return null;
	if (!byId.has(rawParentId)) return null;
	return rawParentId;
}

export function buildHierarchyRows(items: HierarchyInputItem[]): HierarchyRow[] {
	const { byId, orderedIds } = normalizeInput(items);
	const childrenByParent = new Map<string | null, string[]>();

	for (const id of orderedIds) {
		const item = byId.get(id);
		if (!item) continue;
		const parentId = resolveParentId(item, byId);
		const current = childrenByParent.get(parentId) ?? [];
		current.push(id);
		childrenByParent.set(parentId, current);
	}

	const rows: HierarchyRow[] = [];
	const visited = new Set<string>();
	const visiting = new Set<string>();

	function visit(nodeId: string, ancestorIds: string[]) {
		if (visited.has(nodeId)) return;
		if (visiting.has(nodeId)) return;
		const node = byId.get(nodeId);
		if (!node) return;

		visiting.add(nodeId);
		visited.add(nodeId);

		const labels = ancestorIds
			.map((ancestorId) => byId.get(ancestorId)?.label)
			.filter(Boolean) as string[];
		const pathLabel = [...labels, node.label].join(' > ');

		rows.push({
			id: nodeId,
			label: node.label,
			parentId: resolveParentId(node, byId),
			depth: ancestorIds.length + 1,
			pathLabel,
			ancestorIds,
			hasChildren: (childrenByParent.get(nodeId)?.length ?? 0) > 0
		});

		const children = childrenByParent.get(nodeId) ?? [];
		for (const childId of children) {
			visit(childId, [...ancestorIds, nodeId]);
		}

		visiting.delete(nodeId);
	}

	for (const rootId of childrenByParent.get(null) ?? []) {
		visit(rootId, []);
	}

	for (const id of orderedIds) {
		if (!visited.has(id)) {
			visit(id, []);
		}
	}

	return rows;
}

export function filterHierarchyRows(rows: HierarchyRow[], query: string): HierarchyRow[] {
	const normalized = query.trim().toLowerCase();
	if (!normalized) return rows;

	const includedIds = new Set<string>();

	for (const row of rows) {
		const labelMatch = row.label.toLowerCase().includes(normalized);
		const pathMatch = row.pathLabel.toLowerCase().includes(normalized);
		if (!labelMatch && !pathMatch) continue;

		includedIds.add(row.id);
		for (const ancestorId of row.ancestorIds) {
			includedIds.add(ancestorId);
		}
	}

	return rows.filter((row) => includedIds.has(row.id));
}

export function collectAncestorIds(rows: HierarchyRow[], selectedIds: string[]): Set<string> {
	const byId = new Map(rows.map((row) => [row.id, row]));
	const ancestorIds = new Set<string>();

	for (const selectedId of selectedIds) {
		const row = byId.get(selectedId);
		if (!row) continue;
		for (const ancestorId of row.ancestorIds) {
			ancestorIds.add(ancestorId);
		}
	}

	return ancestorIds;
}
