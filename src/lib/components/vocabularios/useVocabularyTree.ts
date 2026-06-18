export type VocabularyItem = {
	termino_id: string;
	categoria: string;
	termino: string;
	etiqueta: string | null;
	termino_padre_id: string | null;
	nivel: number | null;
	orden: number | null;
	definicion: string | null;
	ejemplo: string | null;
	bibliografia: string | null;
	equivalencias: string[] | null;
	patron_especifico: string | null;
	tipo_forma: string | null;
	activo: boolean | null;
};

export type FlattenedVocabularyNode = {
	item: VocabularyItem;
	depth: number;
};

export type VocabularyDropPlacement = 'top' | 'mid' | 'bottom' | 'root-start' | 'root-end';
const MAX_VOCAB_TREE_DEPTH = 2;

function sortSiblings(items: VocabularyItem[]): VocabularyItem[] {
	return [...items].sort((a, b) => {
		const orderA = typeof a.orden === 'number' ? a.orden : Number.MAX_SAFE_INTEGER;
		const orderB = typeof b.orden === 'number' ? b.orden : Number.MAX_SAFE_INTEGER;
		if (orderA !== orderB) return orderA - orderB;
		return a.termino.localeCompare(b.termino, 'es');
	});
}

function siblingsOf(items: VocabularyItem[], parentId: string | null): VocabularyItem[] {
	return sortSiblings(items.filter((item) => (item.termino_padre_id ?? null) === parentId));
}

function treeStructureSignature(items: VocabularyItem[]): string {
	return JSON.stringify(
		normalizeTree(items)
			.map((item) => ({
				termino_id: item.termino_id,
				termino_padre_id: item.termino_padre_id,
				orden: item.orden ?? 0,
				nivel: item.nivel ?? 1
			}))
			.sort((a, b) => a.termino_id.localeCompare(b.termino_id))
	);
}

function maxTreeDepth(items: VocabularyItem[]): number {
	let maxDepth = 0;
	for (const row of flattenVocabularyTree(items)) {
		if (row.depth > maxDepth) maxDepth = row.depth;
	}
	return maxDepth;
}

function assignOrders(items: VocabularyItem[], parentId: string | null): VocabularyItem[] {
	const siblings = siblingsOf(items, parentId);
	const orderById = new Map<string, number>();
	siblings.forEach((item, index) => {
		orderById.set(item.termino_id, (index + 1) * 10);
	});
	return items.map((item) =>
		orderById.has(item.termino_id)
			? {
					...item,
					orden: orderById.get(item.termino_id) ?? item.orden
				}
			: item
	);
}

export function flattenVocabularyTree(items: VocabularyItem[]): FlattenedVocabularyNode[] {
	const byParent = new Map<string | null, VocabularyItem[]>();
	for (const item of items) {
		const parentId = item.termino_padre_id ?? null;
		const current = byParent.get(parentId) ?? [];
		current.push(item);
		byParent.set(parentId, current);
	}
	for (const [parentId, children] of byParent.entries()) {
		byParent.set(parentId, sortSiblings(children));
	}

	const flattened: FlattenedVocabularyNode[] = [];
	const visited = new Set<string>();

	const visit = (parentId: string | null, depth: number) => {
		for (const child of byParent.get(parentId) ?? []) {
			if (visited.has(child.termino_id)) continue;
			visited.add(child.termino_id);
			flattened.push({ item: child, depth });
			visit(child.termino_id, depth + 1);
		}
	};

	visit(null, 1);

	for (const item of sortSiblings(items)) {
		if (visited.has(item.termino_id)) continue;
		flattened.push({ item, depth: 1 });
	}

	return flattened;
}

export function computePath(items: VocabularyItem[], terminoId: string | null): string[] {
	if (!terminoId) return [];
	const byId = new Map(items.map((item) => [item.termino_id, item]));
	const path: string[] = [];
	const seen = new Set<string>();
	let cursor = terminoId;
	while (cursor) {
		const current = byId.get(cursor);
		if (!current || seen.has(cursor)) break;
		path.push(current.termino);
		seen.add(cursor);
		cursor = current.termino_padre_id ?? '';
	}
	return path.reverse();
}

export function isDescendant(items: VocabularyItem[], ancestorId: string, candidateDescendantId: string): boolean {
	const byId = new Map(items.map((item) => [item.termino_id, item]));
	const seen = new Set<string>();
	let cursor: string | null = candidateDescendantId;
	while (cursor) {
		if (cursor === ancestorId) return true;
		if (seen.has(cursor)) return false;
		seen.add(cursor);
		cursor = byId.get(cursor)?.termino_padre_id ?? null;
	}
	return false;
}

export function normalizeTree(items: VocabularyItem[]): VocabularyItem[] {
	let next = [...items];
	const parentIds = new Set<string | null>([null]);
	for (const item of items) {
		parentIds.add(item.termino_id);
		if (item.termino_padre_id) parentIds.add(item.termino_padre_id);
	}
	for (const parentId of parentIds) {
		next = assignOrders(next, parentId);
	}

	const byParent = new Map<string | null, VocabularyItem[]>();
	for (const item of next) {
		const parentId = item.termino_padre_id ?? null;
		const current = byParent.get(parentId) ?? [];
		current.push(item);
		byParent.set(parentId, sortSiblings(current));
	}

	const levelById = new Map<string, number>();
	const visiting = new Set<string>();

	const visit = (id: string, fallbackLevel: number): number => {
		if (levelById.has(id)) return levelById.get(id) ?? fallbackLevel;
		if (visiting.has(id)) return fallbackLevel;
		visiting.add(id);
		const node = next.find((item) => item.termino_id === id);
		if (!node) {
			visiting.delete(id);
			return fallbackLevel;
		}
		let level = 1;
		if (node.termino_padre_id) {
			level = visit(node.termino_padre_id, 1) + 1;
		}
		levelById.set(id, level);
		visiting.delete(id);
		return level;
	};

	for (const item of next) {
		visit(item.termino_id, 1);
	}

	return next.map((item) => ({
		...item,
		nivel: levelById.get(item.termino_id) ?? 1
	}));
}

export function moveVocabularyItem(
	items: VocabularyItem[],
	draggedId: string,
	targetParentId: string | null,
	targetIndex: number
): VocabularyItem[] {
	const dragged = items.find((item) => item.termino_id === draggedId);
	if (!dragged) return items;
	if (targetParentId === draggedId) return items;
	if (targetParentId && isDescendant(items, draggedId, targetParentId)) return items;

	const sourceParentId = dragged.termino_padre_id ?? null;
	let next = items.map((item) =>
		item.termino_id === draggedId
			? {
					...item,
					termino_padre_id: targetParentId
				}
			: item
	);

	const sourceSiblings = siblingsOf(next, sourceParentId).filter((item) => item.termino_id !== draggedId);
	const targetSiblings = siblingsOf(next, targetParentId).filter((item) => item.termino_id !== draggedId);
	const insertAt = Math.max(0, Math.min(targetIndex, targetSiblings.length));
	const moved = next.find((item) => item.termino_id === draggedId);
	if (!moved) return items;
	const reorderedTargetSiblings = [
		...targetSiblings.slice(0, insertAt),
		moved,
		...targetSiblings.slice(insertAt)
	];

	const orderById = new Map<string, number>();
	sourceSiblings.forEach((item, index) => orderById.set(item.termino_id, (index + 1) * 10));
	reorderedTargetSiblings.forEach((item, index) => orderById.set(item.termino_id, (index + 1) * 10));

	next = next.map((item) =>
		orderById.has(item.termino_id)
			? {
					...item,
					orden: orderById.get(item.termino_id) ?? item.orden
				}
			: item
	);

	return normalizeTree(next);
}

export function moveVocabularyByDropIntent(
	items: VocabularyItem[],
	draggedId: string,
	targetId: string | null,
	placement: VocabularyDropPlacement
): VocabularyItem[] {
	const dragged = items.find((item) => item.termino_id === draggedId);
	if (!dragged) return items;

	const beforeSignature = treeStructureSignature(items);

	let next: VocabularyItem[] = items;
	if (placement === 'root-start' || placement === 'root-end') {
		const roots = siblingsOf(items, null).filter((item) => item.termino_id !== draggedId);
		const rootIndex = placement === 'root-start' ? 0 : roots.length;
		next = moveVocabularyItem(items, draggedId, null, rootIndex);
	} else {
		if (!targetId) return items;
		const target = items.find((item) => item.termino_id === targetId);
		if (!target) return items;
		if (target.termino_id === draggedId) return items;

		if (placement === 'mid') {
			if (isDescendant(items, draggedId, target.termino_id)) return items;
			const children = siblingsOf(items, target.termino_id).filter((item) => item.termino_id !== draggedId);
			next = moveVocabularyItem(items, draggedId, target.termino_id, children.length);
		} else {
			const parentId = target.termino_padre_id ?? null;
			const siblings = siblingsOf(items, parentId).filter((item) => item.termino_id !== draggedId);
			const targetIndex = siblings.findIndex((item) => item.termino_id === target.termino_id);
			if (targetIndex < 0) return items;
			const insertIndex = placement === 'top' ? targetIndex : targetIndex + 1;
			next = moveVocabularyItem(items, draggedId, parentId, insertIndex);
		}
	}

	if (treeStructureSignature(next) === beforeSignature) {
		return items;
	}
	if (maxTreeDepth(next) > MAX_VOCAB_TREE_DEPTH) {
		return items;
	}
	return next;
}

export function moveSibling(items: VocabularyItem[], terminoId: string, delta: -1 | 1): VocabularyItem[] {
	const item = items.find((row) => row.termino_id === terminoId);
	if (!item) return items;
	const parentId = item.termino_padre_id ?? null;
	const siblings = siblingsOf(items, parentId);
	const index = siblings.findIndex((row) => row.termino_id === terminoId);
	if (index < 0) return items;
	const targetIndex = index + delta;
	if (targetIndex < 0 || targetIndex >= siblings.length) return items;
	return moveVocabularyItem(items, terminoId, parentId, targetIndex);
}

export function buildReorderPayload(items: VocabularyItem[], categoria: string) {
	return normalizeTree(items)
		.filter((item) => item.categoria === categoria)
		.map((item) => ({
			termino_id: item.termino_id,
			termino_padre_id: item.termino_padre_id,
			orden: item.orden ?? 0,
			nivel: item.nivel ?? 1
		}));
}
