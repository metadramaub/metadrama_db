<script lang="ts">
	import CategoryCard from '$lib/components/vocabularios/CategoryCard.svelte';
	import type { PageData } from './$types';

	type CategoryRow = PageData['categories'][number];
	let { data } = $props<{ data: PageData }>();
	let search = $state('');

	const filteredCategories = $derived.by(() => {
		const term = search.trim().toLowerCase();
		if (!term) return data.categories;
		return data.categories.filter((row: CategoryRow) => row.categoria.toLowerCase().includes(term));
	});
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
				Modo consulta: solo lectura para este perfil.
			{/if}
		</div>
	</div>

	<div class="card p-4">
		<label class="text-sm">
			<span class="mb-1 block">Buscar categoría</span>
			<input
				type="text"
				bind:value={search}
				placeholder="Ej.: estrofa_tipo"
				class="w-full border border-[color:var(--border)] px-3 py-2"
			/>
		</label>
	</div>

	{#if filteredCategories.length === 0}
		<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">No hay categorías que coincidan.</div>
	{:else}
		<div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
			{#each filteredCategories as category}
				<CategoryCard
					categoria={category.categoria}
					total={category.total}
					rootCount={category.rootCount}
					childCount={category.childCount}
					isProtected={category.isProtected}
					editable={category.editable}
					href={`/dashboard/vocabularios/${encodeURIComponent(category.categoria)}`}
				/>
			{/each}
		</div>
	{/if}
</section>
