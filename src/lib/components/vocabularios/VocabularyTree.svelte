<script lang="ts">
	import {
		flattenVocabularyTree,
		isDescendant,
		moveVocabularyByDropIntent,
		type VocabularyDropPlacement,
		type VocabularyItem
	} from './useVocabularyTree';

	const props = $props<{
		items: VocabularyItem[];
		selectedId: string | null;
		readOnly?: boolean;
		search?: string;
		collapseKey?: string;
		allowNesting?: boolean;
		onSelect?: (terminoId: string) => void;
		onChange?: (items: VocabularyItem[]) => void;
	}>();

	type DropTargetState = {
		targetId: string | null;
		placement: VocabularyDropPlacement;
		valid: boolean;
	} | null;

	let draggedId = $state<string | null>(null);
	let activeDrop = $state<DropTargetState>(null);
	let collapsedIds = $state<Set<string>>(new Set());
	let initializedCollapseKey = $state<string | null>(null);

	const readOnly = $derived(Boolean(props.readOnly));
	const allowNesting = $derived(props.allowNesting ?? true);
	const searchActive = $derived((props.search ?? '').trim().length > 0);
	const canDrag = $derived(!readOnly && !searchActive);
	const dragging = $derived(Boolean(draggedId));
	const byId = $derived(new Map<string, VocabularyItem>(props.items.map((item: VocabularyItem) => [item.termino_id, item])));
	const flattened = $derived(flattenVocabularyTree(props.items));
	const childCountById = $derived.by(() => {
		const counts = new Map<string, number>();
		for (const item of props.items) {
			const parentId = item.termino_padre_id ?? null;
			if (!parentId) continue;
			counts.set(parentId, (counts.get(parentId) ?? 0) + 1);
		}
		return counts;
	});
	const depthById = $derived(
		new Map<string, number>(flattened.map((row) => [row.item.termino_id, row.depth]))
	);
	const visibleIds = $derived.by(() => {
		const query = (props.search ?? '').trim().toLowerCase();
		if (!query) {
			return new Set(props.items.map((item: VocabularyItem) => item.termino_id));
		}

		const include = new Set<string>();
		const matched = props.items.filter((item: VocabularyItem) => item.termino.toLowerCase().includes(query));
		for (const item of matched) {
			include.add(item.termino_id);

			let parentId = item.termino_padre_id;
			const visited = new Set<string>();
			while (parentId && !visited.has(parentId)) {
				visited.add(parentId);
				include.add(parentId);
				parentId = byId.get(parentId)?.termino_padre_id ?? null;
			}

			for (const candidate of props.items) {
				if (isDescendant(props.items, item.termino_id, candidate.termino_id)) {
					include.add(candidate.termino_id);
				}
			}
		}
		return include;
	});

	const filteredRows = $derived(flattened.filter((row) => visibleIds.has(row.item.termino_id)));
	const visibleRows = $derived.by(() => {
		if (searchActive) return filteredRows;
		const rows = [];
		const hiddenDepths: number[] = [];
		for (const row of filteredRows) {
			while (hiddenDepths.length > 0 && row.depth <= hiddenDepths[hiddenDepths.length - 1]) {
				hiddenDepths.pop();
			}
			if (hiddenDepths.length > 0) continue;
			rows.push(row);
			if (collapsedIds.has(row.item.termino_id)) {
				hiddenDepths.push(row.depth);
			}
		}
		return rows;
	});

	function emit(nextItems: VocabularyItem[]) {
		props.onChange?.(nextItems);
	}

	function hasChildren(terminoId: string): boolean {
		return (childCountById.get(terminoId) ?? 0) > 0;
	}

	function isCollapsed(terminoId: string): boolean {
		return collapsedIds.has(terminoId);
	}

	function toggleCollapsed(terminoId: string) {
		if (!hasChildren(terminoId)) return;
		const next = new Set(collapsedIds);
		if (next.has(terminoId)) {
			next.delete(terminoId);
		} else {
			next.add(terminoId);
		}
		collapsedIds = next;
	}

	function isPlacementActive(targetId: string | null, placement: VocabularyDropPlacement): boolean {
		return activeDrop?.targetId === targetId && activeDrop?.placement === placement;
	}

	function resolveDropParentId(targetId: string | null, placement: VocabularyDropPlacement): string | null {
		if (placement === 'root-start' || placement === 'root-end') {
			return null;
		}
		if (!targetId) {
			return null;
		}
		if (placement === 'mid') {
			return targetId;
		}
		return byId.get(targetId)?.termino_padre_id ?? null;
	}

	function isDropPlacementAllowed(
		draggedTerminoId: string,
		targetId: string | null,
		placement: VocabularyDropPlacement
	): boolean {
		if (!allowNesting && placement === 'mid') {
			return false;
		}
		if (placement === 'mid' && targetId && (depthById.get(targetId) ?? 1) >= 2) {
			return false;
		}
		if (!allowNesting) {
			const nextParentId = resolveDropParentId(targetId, placement);
			if (nextParentId !== null) {
				return false;
			}
		}
		return draggedTerminoId.length > 0;
	}

	function rowClass(rowId: string, depth: number): string {
		const hierarchyBg = depth === 1 ? 'bg-[color:var(--muted)]' : 'bg-white';
		const selected =
			props.selectedId === rowId
				? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
				: `border-[color:var(--border)] ${hierarchyBg}`;
		const rowDragging = draggedId === rowId ? 'scale-[0.99] opacity-60' : '';
		const dropMidValid = isPlacementActive(rowId, 'mid') && activeDrop?.valid;
		const dropMidInvalid = isPlacementActive(rowId, 'mid') && !activeDrop?.valid;
		const dropClass = dropMidValid
			? 'ring-2 ring-[color:var(--primary)] ring-offset-1'
			: dropMidInvalid
				? 'ring-2 ring-red-400 ring-offset-1'
				: '';
		return `border px-2 py-2 transition ${selected} ${rowDragging} ${dropClass}`;
	}

	function dropZoneClass(targetId: string | null, placement: VocabularyDropPlacement): string {
		const active = isPlacementActive(targetId, placement);
		const valid = activeDrop?.valid ?? false;
		if (placement === 'root-start' || placement === 'root-end') {
			if (!active) {
				return 'rounded border border-dashed border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)] transition-colors';
			}
			return valid
				? 'rounded border border-dashed border-[color:var(--primary)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--foreground)] transition-colors'
				: 'rounded border border-dashed border-red-400 bg-red-50 px-3 py-2 text-xs text-red-700 transition-colors';
		}
		if (!active) {
			return 'h-2 rounded border border-transparent transition-all';
		}
		return valid
			? 'h-7 rounded border border-dashed border-[color:var(--primary)] bg-[color:var(--muted)] px-2 text-[11px] text-[color:var(--foreground)] transition-all'
			: 'h-7 rounded border border-dashed border-red-400 bg-red-50 px-2 text-[11px] text-red-700 transition-all';
	}

	function dropHintLabel(targetId: string | null, placement: VocabularyDropPlacement): string {
		const targetTerm = targetId ? (byId.get(targetId)?.termino ?? 'termino') : 'raiz';
		if (!isPlacementActive(targetId, placement)) return '';
		if (!activeDrop?.valid) return 'Movimiento no valido';
		switch (placement) {
			case 'top':
				return `Antes de ${targetTerm}`;
			case 'mid':
				return `Como hijo de ${targetTerm}`;
			case 'bottom':
				return `Despues de ${targetTerm}`;
			case 'root-start':
				return 'Mover al inicio de raiz';
			case 'root-end':
				return 'Mover al final de raiz';
			default:
				return '';
		}
	}

	function draggingLabel(): string {
		if (!draggedId) return '';
		return byId.get(draggedId)?.termino ?? '';
	}

	function onDragStart(event: DragEvent, terminoId: string) {
		if (!canDrag) return;
		draggedId = terminoId;
		activeDrop = null;
		event.dataTransfer?.setData('text/plain', terminoId);
		if (event.dataTransfer) {
			event.dataTransfer.effectAllowed = 'move';
		}
	}

	function onDragEnd() {
		draggedId = null;
		activeDrop = null;
	}

	function onDropZoneDragOver(event: DragEvent, targetId: string | null, placement: VocabularyDropPlacement) {
		if (!canDrag || !draggedId) return;
		if (!isDropPlacementAllowed(draggedId, targetId, placement)) {
			activeDrop = null;
			if (event.dataTransfer) event.dataTransfer.dropEffect = 'none';
			return;
		}
		const preview = moveVocabularyByDropIntent(props.items, draggedId, targetId, placement);
		const valid = preview !== props.items;
		activeDrop = { targetId, placement, valid };
		if (valid) {
			event.preventDefault();
			if (event.dataTransfer) event.dataTransfer.dropEffect = 'move';
		} else if (event.dataTransfer) {
			event.dataTransfer.dropEffect = 'none';
		}
	}

	function onDropZoneDrop(event: DragEvent, targetId: string | null, placement: VocabularyDropPlacement) {
		event.preventDefault();
		if (!canDrag || !draggedId) return;
		if (!isDropPlacementAllowed(draggedId, targetId, placement)) {
			draggedId = null;
			activeDrop = null;
			return;
		}
		const moved = moveVocabularyByDropIntent(props.items, draggedId, targetId, placement);
		if (moved !== props.items) {
			emit(moved);
		}
		draggedId = null;
		activeDrop = null;
	}

	$effect(() => {
		const key = props.collapseKey ?? '__default__';
		if (initializedCollapseKey !== key) {
			const rootIdsWithChildren = props.items
				.filter(
					(item: VocabularyItem) =>
						!item.termino_padre_id && (childCountById.get(item.termino_id) ?? 0) > 0
				)
				.map((item: VocabularyItem) => item.termino_id);
			collapsedIds = new Set(rootIdsWithChildren);
			initializedCollapseKey = key;
			return;
		}

		const next = new Set(
			[...collapsedIds].filter((terminoId) => (childCountById.get(terminoId) ?? 0) > 0)
		);
		if (next.size !== collapsedIds.size) {
			collapsedIds = next;
		}
	});
</script>

<div class="space-y-2" role="list">
	{#if !readOnly && searchActive}
		<p class="rounded border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
			Limpia la busqueda para reordenar.
		</p>
	{/if}

	{#if canDrag && dragging}
		<div class="rounded border border-[color:var(--primary)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--foreground)]">
			<div class="font-medium">Arrastrando: {draggingLabel()}</div>
			<div class="mt-1 text-[color:var(--muted-foreground)]">Suelta en zona superior, centro o inferior para decidir posicion.</div>
		</div>
	{/if}

	{#if visibleRows.length === 0}
		<p class="border border-[color:var(--border)] bg-white px-3 py-4 text-sm text-[color:var(--muted-foreground)]">
			No hay terminos para mostrar.
		</p>
	{:else}
		{#each visibleRows as row}
			<div class="space-y-1">
				{#if canDrag}
					<div
						class={dropZoneClass(row.item.termino_id, 'top')}
						role="presentation"
						ondragover={(event) => onDropZoneDragOver(event, row.item.termino_id, 'top')}
						ondrop={(event) => onDropZoneDrop(event, row.item.termino_id, 'top')}
					>
						{#if isPlacementActive(row.item.termino_id, 'top')}
							<div class="flex h-full items-center">{dropHintLabel(row.item.termino_id, 'top')}</div>
						{/if}
					</div>
				{/if}

				<div
					class={rowClass(row.item.termino_id, row.depth)}
					role="listitem"
					draggable={canDrag}
					ondragstart={(event) => onDragStart(event, row.item.termino_id)}
					ondragend={onDragEnd}
					ondragover={(event) => onDropZoneDragOver(event, row.item.termino_id, 'mid')}
					ondrop={(event) => onDropZoneDrop(event, row.item.termino_id, 'mid')}
				>
					<div class="flex items-center gap-2" style={`padding-left: ${(row.depth - 1) * 1.2}rem`}>
						{#if hasChildren(row.item.termino_id)}
							<button
								type="button"
								class="inline-flex h-5 w-5 items-center justify-center rounded border border-[color:var(--border)] text-xs text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)]"
								onclick={(event) => {
									event.stopPropagation();
									toggleCollapsed(row.item.termino_id);
								}}
								aria-label={isCollapsed(row.item.termino_id) ? 'Expandir hijos' : 'Colapsar hijos'}
							>
								{isCollapsed(row.item.termino_id) ? '>' : 'v'}
							</button>
						{:else}
							<span class="inline-block h-5 w-5"></span>
						{/if}
						{#if !readOnly}
							<span
								class={`select-none text-[color:var(--muted-foreground)] ${canDrag ? 'cursor-grab active:cursor-grabbing' : 'cursor-not-allowed opacity-50'}`}
							>
								::
							</span>
						{/if}
						<button
							type="button"
							class="text-left text-sm font-medium text-[color:var(--foreground)]"
							onclick={() => props.onSelect?.(row.item.termino_id)}
						>
							{row.item.termino}
						</button>
						{#if hasChildren(row.item.termino_id)}
							<span class="text-[10px] text-[color:var(--muted-foreground)]">
								{childCountById.get(row.item.termino_id) ?? 0} hijos
							</span>
						{/if}
						<span class="ml-auto text-[10px] text-[color:var(--muted-foreground)]">N{row.depth}</span>
						{#if row.item.activo === false}
							<span class="border border-[color:var(--border)] px-1 py-0.5 text-[10px] text-[color:var(--muted-foreground)]">
								inactivo
							</span>
						{/if}
					</div>

					{#if isPlacementActive(row.item.termino_id, 'mid')}
						<div class={`mt-2 rounded border px-2 py-1 text-[11px] ${activeDrop?.valid ? 'border-[color:var(--primary)] bg-[color:var(--muted)] text-[color:var(--foreground)]' : 'border-red-400 bg-red-50 text-red-700'}`}>
							{dropHintLabel(row.item.termino_id, 'mid')}
						</div>
					{/if}
				</div>

				{#if canDrag}
					<div
						class={dropZoneClass(row.item.termino_id, 'bottom')}
						role="presentation"
						ondragover={(event) => onDropZoneDragOver(event, row.item.termino_id, 'bottom')}
						ondrop={(event) => onDropZoneDrop(event, row.item.termino_id, 'bottom')}
					>
						{#if isPlacementActive(row.item.termino_id, 'bottom')}
							<div class="flex h-full items-center">{dropHintLabel(row.item.termino_id, 'bottom')}</div>
						{/if}
					</div>
				{/if}
			</div>
		{/each}
	{/if}
</div>
