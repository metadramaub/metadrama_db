<script lang="ts">
	import { browser } from '$app/environment';
	import CatalogFilterChips from '$lib/components/catalogo/CatalogFilterChips.svelte';
	import CatalogFilterPanel from '$lib/components/catalogo/CatalogFilterPanel.svelte';
	import CatalogResultRow from '$lib/components/catalogo/CatalogResultRow.svelte';
	import {
		buildCatalogActiveChips,
		createDefaultCatalogFilters,
		filterAndSortCatalogObras,
		parseCatalogFilters,
		removeCatalogChip,
		serializeCatalogFilters,
		type CatalogActiveChipId,
		type CatalogFilters
	} from '$lib/catalogo/catalog-filters';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type Obra = PageData['obras'][number];

	function getInitialFilters(): CatalogFilters {
		return { ...data.initialFilters };
	}

	let filters = $state<CatalogFilters>(getInitialFilters());
	let mounted = false;
	let syncingFromHistory = false;

	const filtered = $derived(filterAndSortCatalogObras<Obra>(data.obras, filters, data.filterOptions));
	const activeChips = $derived(
		buildCatalogActiveChips(filters, data.filterOptions, data.catalogVisibility)
	);
	const hasActiveFilters = $derived(activeChips.length > 0);

	function setFilters(next: CatalogFilters) {
		filters = next;
	}

	function clearFilters() {
		filters = createDefaultCatalogFilters(data.filterOptions);
	}

	function removeFilterChip(chipId: CatalogActiveChipId) {
		filters = removeCatalogChip(filters, chipId, data.filterOptions);
	}

	function syncFiltersFromLocation() {
		if (!browser) return;
		syncingFromHistory = true;
		filters = parseCatalogFilters(
			new URLSearchParams(window.location.search),
			data.filterOptions,
			data.catalogVisibility
		);
		queueMicrotask(() => {
			syncingFromHistory = false;
		});
	}

	function replaceUrlFromFilters() {
		if (!browser || !mounted || syncingFromHistory) return;
		const params = serializeCatalogFilters(filters, data.filterOptions, data.catalogVisibility);
		const query = params.toString();
		const nextUrl = `${window.location.pathname}${query ? `?${query}` : ''}${window.location.hash}`;
		const currentUrl = `${window.location.pathname}${window.location.search}${window.location.hash}`;
		if (nextUrl === currentUrl) return;
		window.history.replaceState(window.history.state, '', nextUrl);
	}

	$effect(() => {
		filters;
		replaceUrlFromFilters();
	});

	$effect(() => {
		if (!browser) return;
		mounted = true;
		window.addEventListener('popstate', syncFiltersFromLocation);
		return () => {
			window.removeEventListener('popstate', syncFiltersFromLocation);
		};
	});
</script>

<section class="space-y-5">
	<header class="flex flex-wrap items-end justify-between gap-3">
		<div>
			<h1 class="font-display text-4xl text-[color:var(--gray-900)]">Catálogo</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				{#if data.canSeeAllPublished}
					Vista editorial: incluye obras publicadas no visibles sin login.
				{:else}
					Repertorio métrico del teatro áureo.
				{/if}
			</p>
		</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">
			{filtered.length} de {data.obras.length}
			{data.obras.length === 1 ? 'obra' : 'obras'}
		</div>
	</header>

	<div class="grid gap-5 lg:grid-cols-[300px_minmax(0,1fr)]">
		<CatalogFilterPanel
			filters={filters}
			options={data.filterOptions}
			visibility={data.catalogVisibility}
			hasActiveFilters={hasActiveFilters}
			onChange={setFilters}
			onClear={clearFilters}
		/>

		<div class="space-y-3">
			<CatalogFilterChips chips={activeChips} onRemove={removeFilterChip} onClear={clearFilters} />

			{#if filtered.length === 0}
				<div class="border border-[color:var(--border)] bg-white p-6 text-sm text-[color:var(--muted-foreground)]">
					{#if data.obras.length === 0}
						No hay obras disponibles para esta vista.
					{:else}
						Ninguna obra coincide con los filtros.
					{/if}
				</div>
			{:else}
				<div class="grid gap-2">
					{#each filtered as obra (obra.obra_id)}
						<CatalogResultRow obra={obra} canSeeAllPublished={data.canSeeAllPublished} />
					{/each}
				</div>
			{/if}
		</div>
	</div>
</section>
