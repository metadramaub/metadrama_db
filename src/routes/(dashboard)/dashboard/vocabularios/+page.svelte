<script lang="ts">
	import CategoryCard from '$lib/components/vocabularios/CategoryCard.svelte';
	import type { PageData } from './$types';

	type CategoryRow = PageData['metricas'][number] | PageData['tecnicosGestion'][number];
	let { data } = $props<{ data: PageData }>();
	let search = $state('');

	const filterBySearch = <T extends CategoryRow>(rows: T[]) => {
		const term = search.trim().toLowerCase();
		if (!term) return rows;
		return rows.filter((row) => row.categoria.toLowerCase().includes(term));
	};

	const metricasFiltradas = $derived.by(() => filterBySearch(data.metricas));
	const tecnicosFiltradas = $derived.by(() => filterBySearch(data.tecnicosGestion));
	const hasResults = $derived(metricasFiltradas.length > 0 || tecnicosFiltradas.length > 0);
</script>

<section class="space-y-4">
	<div class="flex flex-wrap items-end justify-between gap-3">
		<div>
			<h1 class="font-display text-3xl">VOCABULARIOS</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Selecciona una categoría para consultar o editar sus términos.
			</p>
		</div>
		<div class="text-xs text-[color:var(--muted-foreground)]">
			{#if data.canManage}
				Admin/IP: categorías no protegidas en modo edición.
			{:else}
				Modo consulta: user con permiso de solo lectura.
			{/if}
		</div>
	</div>

	<div class="card p-4">
		<label class="form-field">
			<span class="form-label">Buscar categoría</span>
			<input
				type="text"
				bind:value={search}
				placeholder="Ej.: estrofa_tipo"
				class="w-full border border-[color:var(--border)] px-3 py-2"
			/>
		</label>
	</div>

	{#if !hasResults}
		<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">No hay categorías que coincidan.</div>
	{:else}
		<section class="!mt-6 space-y-3">
			<h2 class="font-display text-xl">Vocabularios métricos</h2>
			{#if metricasFiltradas.length === 0}
				<div class="card p-4 text-sm text-[color:var(--muted-foreground)]">
					No hay categorías métricas que coincidan.
				</div>
			{:else}
				<div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
					{#each metricasFiltradas as category}
						<CategoryCard
							categoria={category.categoria}
							total={category.total}
							rootCount={category.rootCount}
							showRootCount={category.hasHierarchy}
							isProtected={category.isProtected}
							editable={category.editable}
							href={`/dashboard/vocabularios/${encodeURIComponent(category.categoria)}`}
						/>
					{/each}
				</div>
			{/if}
		</section>

		<section class="!mt-6 space-y-3">
			<h2 class="font-display text-xl">Vocabularios técnicos/gestión</h2>
			{#if tecnicosFiltradas.length === 0}
				<div class="card p-4 text-sm text-[color:var(--muted-foreground)]">
					No hay categorías técnicas/gestión que coincidan.
				</div>
			{:else}
				<div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
					{#each tecnicosFiltradas as category}
						<CategoryCard
							categoria={category.categoria}
							total={category.total}
							rootCount={category.rootCount}
							showRootCount={category.hasHierarchy}
							isProtected={category.isProtected}
							editable={category.editable}
							href={`/dashboard/vocabularios/${encodeURIComponent(category.categoria)}`}
						/>
					{/each}
				</div>
			{/if}
		</section>
	{/if}
</section>

