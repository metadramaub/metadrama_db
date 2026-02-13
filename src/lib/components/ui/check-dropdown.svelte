<script lang="ts">
	import { onDestroy, onMount } from 'svelte';

	type DropdownItem = {
		id: string;
		label: string;
		description?: string | null;
	};

	const props = $props<{
		multiple?: boolean;
		items: DropdownItem[];
		selectedIds: string[];
		disabledIds?: string[];
		placeholder?: string;
		search?: boolean;
		disabled?: boolean;
		class?: string;
		onChange?: (ids: string[]) => void;
	}>();

	let rootEl = $state<HTMLDivElement | null>(null);
	let open = $state(false);
	let query = $state('');

	const isMultiple = $derived(props.multiple ?? true);
	const selectedSet = $derived(new Set(props.selectedIds));
	const disabledSet = $derived(new Set(props.disabledIds ?? []));
	const normalizedQuery = $derived(query.trim().toLowerCase());
	const filteredItems = $derived.by(() => {
		if (!normalizedQuery) return props.items;
		return props.items.filter((item: DropdownItem) => item.label.toLowerCase().includes(normalizedQuery));
	});
	const selectedItems = $derived(
		filteredItems.filter((item: DropdownItem) => selectedSet.has(item.id))
	);
	const unselectedItems = $derived(
		filteredItems.filter((item: DropdownItem) => !selectedSet.has(item.id))
	);
	const selectedCount = $derived(props.selectedIds.length);
	const selectedLabel = $derived.by(() => {
		const byId = new Map<string, DropdownItem>(
			props.items.map((item: DropdownItem) => [item.id, item])
		);
		return props.selectedIds.map((id: string) => byId.get(id)?.label).filter(Boolean) as string[];
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
		if (!open) {
			query = '';
		}
	}

	function closeDropdown() {
		open = false;
		query = '';
	}

	function selectItem(itemId: string) {
		if (props.disabled) return;
		if (disabledSet.has(itemId)) return;

		if (!isMultiple) {
			emitChange([itemId]);
			closeDropdown();
			return;
		}

		if (selectedSet.has(itemId)) {
			emitChange(props.selectedIds.filter((id: string) => id !== itemId));
			return;
		}
		emitChange([...props.selectedIds, itemId]);
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

	onMount(() => {
		if (typeof document === 'undefined') return;
		document.addEventListener('mousedown', handleDocumentClick);
		document.addEventListener('keydown', handleEscape);
	});

	onDestroy(() => {
		if (typeof document === 'undefined') return;
		document.removeEventListener('mousedown', handleDocumentClick);
		document.removeEventListener('keydown', handleEscape);
	});
</script>

<div bind:this={rootEl} class={`relative ${props.class ?? ''}`}>
	<button
		type="button"
		class="flex w-full items-center justify-between gap-2 rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-left text-sm disabled:cursor-not-allowed disabled:bg-[color:var(--muted)]"
		disabled={props.disabled}
		onclick={toggleOpen}
	>
		<span class="min-w-0 truncate">{triggerLabel}</span>
		<div class="flex items-center gap-2">
			{#if selectedCount > 0}
				<span class="inline-flex min-w-6 items-center justify-center rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs">
					{selectedCount}
				</span>
			{/if}
			<span class="text-xs text-[color:var(--muted-foreground)]">{open ? 'Cerrar' : 'Abrir'}</span>
		</div>
	</button>

	{#if open}
		<div class="absolute z-30 mt-1 w-full border border-[color:var(--border)] bg-white p-2 shadow-lg">
			{#if props.search}
				<input
					type="text"
					class="mb-2 w-full rounded-md border border-[color:var(--border)] px-2 py-1 text-sm"
					placeholder="Buscar"
					bind:value={query}
				/>
			{/if}

			<div class="max-h-64 overflow-y-auto">
				{#if selectedItems.length === 0 && unselectedItems.length === 0}
					<div class="px-2 py-2 text-sm text-[color:var(--muted-foreground)]">Sin opciones</div>
				{:else}
					{#if selectedItems.length > 0}
						{#each selectedItems as item}
							<button
								type="button"
								class="flex w-full items-start gap-2 px-2 py-2 text-left text-sm hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-60"
								disabled={disabledSet.has(item.id)}
								onclick={() => selectItem(item.id)}
							>
								<input type="checkbox" checked={true} disabled={true} class="mt-0.5" />
								<div class="min-w-0">
									<div class="truncate">{item.label}</div>
									{#if item.description}
										<div class="text-xs text-[color:var(--muted-foreground)]">{item.description}</div>
									{/if}
								</div>
							</button>
						{/each}
					{/if}

					{#if selectedItems.length > 0 && unselectedItems.length > 0}
						<div class="my-1 border-t border-[color:var(--border)]"></div>
					{/if}

					{#each unselectedItems as item}
						<button
							type="button"
							class="flex w-full items-start gap-2 px-2 py-2 text-left text-sm hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-60"
							disabled={disabledSet.has(item.id)}
							onclick={() => selectItem(item.id)}
						>
							<input type="checkbox" checked={false} disabled={true} class="mt-0.5" />
							<div class="min-w-0">
								<div class="truncate">{item.label}</div>
								{#if item.description}
									<div class="text-xs text-[color:var(--muted-foreground)]">{item.description}</div>
								{/if}
							</div>
						</button>
					{/each}
				{/if}
			</div>
		</div>
	{/if}
</div>
