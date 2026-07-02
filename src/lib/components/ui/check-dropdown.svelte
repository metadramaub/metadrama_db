<script lang="ts">
	import { onDestroy, onMount, tick } from 'svelte';
	import {
		buildHierarchyRows,
		collectAncestorIds,
		filterHierarchyRows,
		type HierarchyInputItem
	} from './check-dropdown-hierarchy';

	type DropdownItem = {
		id: string;
		label: string;
		description?: string | null;
		parentId?: string | null;
	};

	const props = $props<{
		multiple?: boolean;
		items: DropdownItem[];
		selectedIds: string[];
		disabledIds?: string[];
		hideCheckboxIds?: string[];
		collapsibleHierarchy?: boolean;
		autoExpandOnSearch?: boolean;
		disableParentsWithChildren?: boolean;
		placeholder?: string;
		search?: boolean;
		disabled?: boolean;
		class?: string;
		hierarchical?: boolean;
		showPathInTrigger?: boolean;
		allowSingleClear?: boolean;
		closeOnSelect?: boolean;
		portal?: boolean;
		portalOffsetPx?: number;
		portalViewportPaddingPx?: number;
		onChange?: (ids: string[]) => void;
	}>();

	let rootEl = $state<HTMLDivElement | null>(null);
	let triggerEl = $state<HTMLButtonElement | null>(null);
	let panelEl = $state<HTMLDivElement | null>(null);
	let listEl = $state<HTMLDivElement | null>(null);
	let open = $state(false);
	let query = $state('');
	let portalStyle = $state('');
	let portalListMaxHeight = $state(256);
	let expandedHierarchyIds = $state<Set<string>>(new Set());

	const isMultiple = $derived(props.multiple ?? true);
	const hierarchical = $derived(props.hierarchical ?? false);
	const collapsibleHierarchy = $derived(props.collapsibleHierarchy ?? false);
	const autoExpandOnSearch = $derived(
		props.autoExpandOnSearch ?? collapsibleHierarchy
	);
	const disableParentsWithChildren = $derived(props.disableParentsWithChildren ?? false);
	const showPathInTrigger = $derived(props.showPathInTrigger ?? false);
	const allowSingleClear = $derived(props.allowSingleClear ?? false);
	const closeOnSelect = $derived(props.closeOnSelect ?? true);
	const usePortal = $derived(props.portal ?? false);
	const portalOffsetPx = $derived(props.portalOffsetPx ?? 6);
	const portalViewportPaddingPx = $derived(props.portalViewportPaddingPx ?? 8);

	const selectedSet = $derived(new Set(props.selectedIds));
	const disabledSet = $derived(new Set(props.disabledIds ?? []));
	const hideCheckboxSet = $derived(new Set(props.hideCheckboxIds ?? []));
	const normalizedQuery = $derived(query.trim().toLowerCase());

	const itemById = $derived(
		new Map<string, DropdownItem>(props.items.map((item: DropdownItem) => [item.id, item]))
	);

	const hierarchyRows = $derived.by(() => {
		if (!hierarchical) return [];
		const hierarchyItems: HierarchyInputItem[] = props.items.map((item: DropdownItem) => ({
			id: item.id,
			label: item.label,
			parentId: item.parentId ?? null
		}));
		return buildHierarchyRows(hierarchyItems);
	});

	const hierarchyRowById = $derived(new Map(hierarchyRows.map((row) => [row.id, row])));
	const searchAutoExpanded = $derived.by(
		() => collapsibleHierarchy && autoExpandOnSearch && normalizedQuery.length > 0
	);
	const filteredHierarchyRows = $derived.by(() => {
		if (!hierarchical) return [];
		return filterHierarchyRows(hierarchyRows, normalizedQuery);
	});

	const visibleHierarchyRows = $derived.by(() => {
		if (!hierarchical) return [];
		if (!collapsibleHierarchy) return filteredHierarchyRows;
		if (searchAutoExpanded) return filteredHierarchyRows;
		const source = normalizedQuery ? filteredHierarchyRows : hierarchyRows;
		return source.filter((row) => row.ancestorIds.every((ancestorId) => expandedHierarchyIds.has(ancestorId)));
	});

	const selectedAncestorIds = $derived.by(() => {
		if (!hierarchical) return new Set<string>();
		return collectAncestorIds(hierarchyRows, props.selectedIds);
	});

	const filteredFlatItems = $derived.by(() => {
		if (hierarchical) return [];
		if (!normalizedQuery) return props.items;
		return props.items.filter((item: DropdownItem) => item.label.toLowerCase().includes(normalizedQuery));
	});

	const selectedFlatItems = $derived(
		filteredFlatItems.filter((item: DropdownItem) => selectedSet.has(item.id))
	);
	const unselectedFlatItems = $derived(
		filteredFlatItems.filter((item: DropdownItem) => !selectedSet.has(item.id))
	);

	const selectedCount = $derived(props.selectedIds.length);
	const selectedLabel = $derived.by(() => {
		const labels: string[] = [];
		for (const id of props.selectedIds) {
			const item = itemById.get(id);
			if (!item) continue;
			if (!isMultiple && hierarchical && showPathInTrigger) {
				labels.push(hierarchyRowById.get(id)?.pathLabel ?? item.label);
			} else {
				labels.push(item.label);
			}
		}
		return labels;
	});

	const triggerLabel = $derived.by(() => {
		if (selectedLabel.length === 0) return props.placeholder ?? 'Seleccionar';
		if (!isMultiple) return selectedLabel[0];
		if (selectedLabel.length === 1) return selectedLabel[0];
		return `${selectedLabel[0]} +${selectedLabel.length - 1}`;
	});

	function emitChange(nextIds: string[]) {
		props.onChange?.(nextIds);
	}

	function toggleOpen() {
		if (props.disabled) return;
		open = !open;
		if (open) {
			void refreshPortalPosition();
		}
		if (!open) {
			query = '';
		}
	}

	function closeDropdown() {
		open = false;
		query = '';
	}

	function selectItem(itemId: string, hasChildren = false) {
		if (props.disabled) return;
		if (isRowSelectionDisabled(itemId, hasChildren)) return;

		if (!isMultiple) {
			if (allowSingleClear && selectedSet.has(itemId)) {
				emitChange([]);
				if (closeOnSelect) closeDropdown();
				return;
			}
			emitChange([itemId]);
			if (closeOnSelect) closeDropdown();
			return;
		}

		if (selectedSet.has(itemId)) {
			emitChange(props.selectedIds.filter((id: string) => id !== itemId));
			return;
		}
		emitChange([...props.selectedIds, itemId]);
	}

	function toggleHierarchyNode(rowId: string) {
		if (!collapsibleHierarchy) return;
		const next = new Set(expandedHierarchyIds);
		if (next.has(rowId)) {
			next.delete(rowId);
		} else {
			next.add(rowId);
		}
		expandedHierarchyIds = next;
	}

	function isRowSelectionDisabled(rowId: string, hasChildren: boolean) {
		if (disabledSet.has(rowId)) return true;
		if (disableParentsWithChildren && hasChildren) return true;
		return false;
	}

	function shouldHideRowCheckbox(rowId: string, hasChildren: boolean) {
		if (hideCheckboxSet.has(rowId)) return true;
		if (disableParentsWithChildren && hasChildren) return true;
		return false;
	}

	function isHierarchyRowExpanded(rowId: string) {
		return expandedHierarchyIds.has(rowId);
	}

	function handleDocumentClick(event: MouseEvent) {
		if (!open) return;
		const target = event.target;
		if (!(target instanceof Node)) return;
		if (rootEl?.contains(target)) return;
		closeDropdown();
	}

	function handleEscape(event: KeyboardEvent) {
		if (event.key !== 'Escape') return;
		if (!open) return;
		closeDropdown();
	}

	function updatePortalPosition() {
		if (!open || !usePortal || !triggerEl || !panelEl) return;

		const triggerRect = triggerEl.getBoundingClientRect();
		const viewportWidth = window.innerWidth;
		const viewportHeight = window.innerHeight;
		const padding = portalViewportPaddingPx;
		const offset = portalOffsetPx;

		const width = Math.min(triggerRect.width, viewportWidth - padding * 2);
		const left = Math.max(padding, Math.min(triggerRect.left, viewportWidth - padding - width));

		const panelHeight = panelEl.offsetHeight || 280;
		const listHeight = listEl?.offsetHeight ?? 0;
		const panelChrome = Math.max(12, panelHeight - listHeight);

		const spaceBelow = viewportHeight - triggerRect.bottom - padding;
		const spaceAbove = triggerRect.top - padding;
		const openUpward = spaceBelow < panelHeight && spaceAbove > spaceBelow;

		const availableVertical = Math.max(
			120,
			(openUpward ? spaceAbove : spaceBelow) - offset
		);
		const nextListMaxHeight = Math.max(96, Math.floor(availableVertical - panelChrome));
		portalListMaxHeight = nextListMaxHeight;

		const desiredPanelHeight = panelChrome + nextListMaxHeight;
		const top = openUpward
			? Math.max(padding, triggerRect.top - offset - desiredPanelHeight)
			: Math.min(
					viewportHeight - padding - desiredPanelHeight,
					Math.max(padding, triggerRect.bottom + offset)
				);

		portalStyle = `top:${Math.round(top)}px;left:${Math.round(left)}px;width:${Math.round(width)}px;`;
	}

	async function refreshPortalPosition() {
		if (!open || !usePortal) return;
		await tick();
		updatePortalPosition();
	}

	function handleViewportReposition() {
		if (!open || !usePortal) return;
		updatePortalPosition();
	}

	$effect(() => {
		if (!open || !usePortal) return;
		query;
		props.items.length;
		props.selectedIds.length;
		void refreshPortalPosition();
	});

	$effect(() => {
		const isHierarchical = hierarchical;
		const isCollapsible = collapsibleHierarchy;
		const ids = hierarchyRows.map((row) => row.id);
		void ids.length;

		if (!isHierarchical || !isCollapsible) {
			if (expandedHierarchyIds.size > 0) {
				expandedHierarchyIds = new Set();
			}
			return;
		}

		if (expandedHierarchyIds.size === 0) return;
		const validIds = new Set(ids);
		const next = new Set<string>();
		for (const id of expandedHierarchyIds) {
			if (validIds.has(id)) next.add(id);
		}
		if (next.size !== expandedHierarchyIds.size) {
			expandedHierarchyIds = next;
		}
	});

	onMount(() => {
		if (typeof document === 'undefined') return;
		document.addEventListener('mousedown', handleDocumentClick);
		document.addEventListener('keydown', handleEscape);
		window.addEventListener('resize', handleViewportReposition, { passive: true });
		window.addEventListener('scroll', handleViewportReposition, { passive: true, capture: true });
	});

	onDestroy(() => {
		if (typeof document === 'undefined') return;
		document.removeEventListener('mousedown', handleDocumentClick);
		document.removeEventListener('keydown', handleEscape);
		window.removeEventListener('resize', handleViewportReposition);
		window.removeEventListener('scroll', handleViewportReposition, true);
	});
</script>

<div bind:this={rootEl} class={`relative ${props.class ?? ''}`}>
	<button
		bind:this={triggerEl}
		type="button"
		class="flex w-full items-center justify-between gap-2 rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-left text-sm disabled:cursor-not-allowed disabled:bg-[color:var(--muted)]"
		disabled={props.disabled}
		onclick={toggleOpen}
	>
		<span class="min-w-0 truncate">{triggerLabel}</span>
		<div class="flex items-center gap-2">
			{#if isMultiple && selectedCount > 0}
				<span class="inline-flex min-w-6 items-center justify-center rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs">
					{selectedCount}
				</span>
			{/if}
			<span class="text-xs text-[color:var(--muted-foreground)]">{open ? 'Cerrar' : 'Abrir'}</span>
		</div>
	</button>

	{#if open}
		<div
			bind:this={panelEl}
			class={`border border-[color:var(--border)] bg-white p-2 shadow-lg ${usePortal ? 'fixed z-[120]' : 'absolute z-30 mt-1 w-full'}`}
			style={usePortal ? portalStyle : undefined}
		>
			{#if props.search}
				<input
					type="text"
					class="mb-2 w-full rounded-md border border-[color:var(--border)] px-2 py-1 text-sm"
					placeholder="Buscar"
					bind:value={query}
				/>
			{/if}

			<div
				bind:this={listEl}
				class={`overflow-y-auto ${usePortal ? '' : 'max-h-64'}`}
				style={usePortal ? `max-height:${portalListMaxHeight}px;` : undefined}
			>
				{#if hierarchical}
					{#if visibleHierarchyRows.length === 0}
						<div class="px-2 py-2 text-sm text-[color:var(--muted-foreground)]">Sin opciones</div>
					{:else}
						{#each visibleHierarchyRows as row}
							{@const item = itemById.get(row.id)}
							{@const rowSelectionDisabled = isRowSelectionDisabled(row.id, row.hasChildren)}
							{@const rowHideCheckbox = shouldHideRowCheckbox(row.id, row.hasChildren)}
							{@const showToggle = collapsibleHierarchy && row.hasChildren}
							{@const rowExpanded = searchAutoExpanded || isHierarchyRowExpanded(row.id)}
							{@const rowIsGroupedParent = disableParentsWithChildren && row.hasChildren}
							{@const rowTermTogglesGroup = rowIsGroupedParent && collapsibleHierarchy}
							{@const rowTermToggleEnabled = rowTermTogglesGroup && !searchAutoExpanded}
							{#if item}
								<div
									class={`flex w-full items-start gap-1 px-2 py-2 text-sm ${selectedAncestorIds.has(row.id) && !selectedSet.has(row.id) ? 'bg-[color:var(--muted)]/40' : ''}`}
									style={`padding-left: ${Math.max(0, row.depth - 1) * 0.85}rem`}
								>
									{#if showToggle}
										<button
											type="button"
											class="mt-0.5 inline-flex h-4 w-4 shrink-0 items-center justify-center rounded text-[11px] leading-none text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] disabled:opacity-50"
											aria-label={rowExpanded ? 'Colapsar grupo' : 'Expandir grupo'}
											aria-expanded={rowExpanded}
											disabled={searchAutoExpanded}
											onclick={() => toggleHierarchyNode(row.id)}
										>
											<span class={`transition-transform duration-150 ${rowExpanded ? 'rotate-90' : ''}`} aria-hidden="true">&gt;</span>
										</button>
									{/if}
									<button
										type="button"
										class={`flex min-w-0 flex-1 items-start gap-2 rounded px-1 py-0.5 text-left hover:bg-[color:var(--muted)] disabled:cursor-not-allowed ${rowSelectionDisabled ? 'opacity-70' : ''}`}
										disabled={rowTermTogglesGroup ? !rowTermToggleEnabled : rowSelectionDisabled}
										aria-expanded={rowTermTogglesGroup ? rowExpanded : undefined}
										onclick={() => {
											if (rowTermToggleEnabled) {
												toggleHierarchyNode(row.id);
												return;
											}
											selectItem(row.id, row.hasChildren);
										}}
									>
										{#if !(showToggle && rowHideCheckbox)}
											{#if rowHideCheckbox}
												<span class="mt-0.5 inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
											{:else}
												<input type="checkbox" checked={selectedSet.has(row.id)} disabled={true} class="pointer-events-none mt-0.5" />
											{/if}
										{/if}
										<div class="min-w-0">
											<div
												class={`truncate ${rowIsGroupedParent || (selectedAncestorIds.has(row.id) && !selectedSet.has(row.id)) ? 'text-[color:var(--muted-foreground)]' : ''}`}
											>
												{item.label}
											</div>
											{#if row.pathLabel !== item.label}
												<div class="truncate text-xs text-[color:var(--muted-foreground)]">{row.pathLabel}</div>
											{/if}
											{#if item.description}
												<div class="text-xs text-[color:var(--muted-foreground)]">{item.description}</div>
											{/if}
										</div>
									</button>
								</div>
							{/if}
						{/each}
					{/if}
				{:else}
					{#if selectedFlatItems.length === 0 && unselectedFlatItems.length === 0}
						<div class="px-2 py-2 text-sm text-[color:var(--muted-foreground)]">Sin opciones</div>
					{:else}
						{#if selectedFlatItems.length > 0}
							{#each selectedFlatItems as item}
								<button
									type="button"
									class="flex w-full items-start gap-2 px-2 py-2 text-left text-sm hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-60"
									disabled={disabledSet.has(item.id)}
									onclick={() => selectItem(item.id)}
								>
									<input type="checkbox" checked={true} disabled={true} class="pointer-events-none mt-0.5" />
									<div class="min-w-0">
										<div class="truncate">{item.label}</div>
										{#if item.description}
											<div class="text-xs text-[color:var(--muted-foreground)]">{item.description}</div>
										{/if}
									</div>
								</button>
							{/each}
						{/if}

						{#if selectedFlatItems.length > 0 && unselectedFlatItems.length > 0}
							<div class="my-1 border-t border-[color:var(--border)]"></div>
						{/if}

						{#each unselectedFlatItems as item}
							<button
								type="button"
								class="flex w-full items-start gap-2 px-2 py-2 text-left text-sm hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-60"
								disabled={disabledSet.has(item.id)}
								onclick={() => selectItem(item.id)}
							>
								<input type="checkbox" checked={false} disabled={true} class="pointer-events-none mt-0.5" />
								<div class="min-w-0">
									<div class="truncate">{item.label}</div>
									{#if item.description}
										<div class="text-xs text-[color:var(--muted-foreground)]">{item.description}</div>
									{/if}
								</div>
							</button>
						{/each}
					{/if}
				{/if}
			</div>
		</div>
	{/if}
</div>
