<script lang="ts">
	import { browser } from '$app/environment';
	import CatalogFilterChips from '$lib/components/catalogo/CatalogFilterChips.svelte';
	import CatalogFilterDrawer from '$lib/components/catalogo/CatalogFilterDrawer.svelte';
	import CatalogFilterPanel from '$lib/components/catalogo/CatalogFilterPanel.svelte';
	import CatalogResultRow from '$lib/components/catalogo/CatalogResultRow.svelte';
	import {
		buildCatalogActiveChips,
		createDefaultCatalogFilters,
		filterAndSortCatalogObras,
		isCatalogPerfilMetricoVisible,
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
	const showPerfilMetrico = $derived(isCatalogPerfilMetricoVisible(data.catalogVisibility));
	const activeChips = $derived(
		buildCatalogActiveChips(filters, data.filterOptions, data.catalogVisibility)
	);
	const hasActiveFilters = $derived(activeChips.length > 0);
	// **El título encoge en cuanto se empieza a bajar.** Un umbral pequeño y una sola transición:
	// no hay estados intermedios que perseguir ni medidas que recalcular al redimensionar.
	let compacto = $state(false);

	// Buscar no cuenta como filtro del cajón: se ve y se borra fuera.
	const filtrosEnElCajon = $derived(activeChips.filter((chip) => chip.id !== 'textQuery').length);

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

<svelte:window on:scroll={() => (compacto = window.scrollY > 24)} />

<section class="space-y-5">
	<!--
		**La barra de control se queda pegada arriba, y el título con ella.** Con la columna de
		filtros bastaba bajar unas obras para perder de vista qué se estaba filtrando; ahora el
		recuento, la búsqueda, el botón y los chips de lo aplicado siguen ahí abajo del todo.
		El título encoge al desplazarse y se mete en la misma línea, para no gastar en un rótulo el
		alto que necesita la lista.

		**Fondo plano y opaco**, el mismo de la página: con translúcido y desenfoque se veían por
		debajo los colores de los códigos de barras al pasar, y esta pantalla ya tiene color de
		sobra.
	-->
	<header
		class="sticky top-0 z-30 -mx-4 space-y-3 border-b border-[color:var(--border)] bg-[color:var(--background)] px-4 py-3 md:-mx-6 md:px-6"
	>
		<div class="flex flex-wrap items-center justify-between gap-3">
			<h1
				class="font-display text-[color:var(--gray-900)] transition-all duration-200"
				class:text-4xl={!compacto}
				class:text-xl={compacto}
			>
				Obras
			</h1>

			<div class="flex flex-wrap items-center justify-end gap-3">
			<span class="text-sm text-[color:var(--muted-foreground)]">
				{filtered.length} de {data.obras.length}
				{data.obras.length === 1 ? 'obra' : 'obras'}
			</span>

			<!--
				Buscar se queda fuera del cajón: es el filtro rápido, el único que se usa sin
				decidir nada. Todo lo demás está detrás del botón.
			-->
			<input
				type="search"
				value={filters.textQuery}
				placeholder="Título o autor..."
				aria-label="Buscar por título o autor"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm sm:w-56"
				oninput={(event) => setFilters({ ...filters, textQuery: event.currentTarget.value })}
			/>

			<CatalogFilterDrawer activeCount={filtrosEnElCajon}>
				<CatalogFilterPanel
					filters={filters}
					options={data.filterOptions}
					visibility={data.catalogVisibility}
					hasActiveFilters={hasActiveFilters}
					onChange={setFilters}
					onClear={clearFilters}
				/>
			</CatalogFilterDrawer>
			<!--
				La vista simple no es otra página del sitio: es esta misma lista sin nada que decidir,
				para quien viene a ver qué hay y no a buscar.
			-->
			<a
				href="/obras/listado"
				class="inline-flex items-center gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)] hover:border-[color:var(--primary)] hover:text-[color:var(--primary)]"
			>
				<span>Ver listado simple</span>
			</a>
			</div>
		</div>

		<CatalogFilterChips chips={activeChips} onRemove={removeFilterChip} onClear={clearFilters} />
	</header>

	<div>
		<div class="space-y-3">
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
						<CatalogResultRow
							obra={obra}
							canSeeAllPublished={data.canSeeAllPublished}
							showPerfilMetrico={showPerfilMetrico}
						/>
					{/each}
				</div>
			{/if}
		</div>
	</div>
</section>
