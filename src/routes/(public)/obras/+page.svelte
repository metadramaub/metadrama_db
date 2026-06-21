<script lang="ts">
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type Obra = PageData['obras'][number];

	function datacionLabel(obra: Obra): string {
		const ini = obra.fecha_inicio_trad;
		const fin = obra.fecha_fin_trad;
		if (ini === null && fin === null) return 'Sin datación';
		if (ini === fin || fin === null) return String(ini);
		if (ini === null) return String(fin);
		return `${ini}-${fin}`;
	}
</script>

<section class="space-y-5">
	<header class="flex flex-wrap items-end justify-between gap-3">
		<div>
			<h1 class="font-display text-4xl text-[color:var(--gray-900)]">Obras</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Listado simple de obras publicadas.
			</p>
		</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">
			{data.obras.length} {data.obras.length === 1 ? 'obra' : 'obras'}
		</div>
	</header>

	<div class="flex justify-end">
		<a
			href="/catalogo"
			class="inline-flex items-center gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)] hover:border-[color:var(--primary)] hover:text-[color:var(--primary)]"
		>
			<span>Ir al catálogo avanzado</span>
			<ArrowRight size={14} aria-hidden="true" />
		</a>
	</div>

	{#if data.obras.length === 0}
		<div class="border border-[color:var(--border)] bg-white p-6 text-sm text-[color:var(--muted-foreground)]">
			No hay obras disponibles para esta vista.
		</div>
	{:else}
		<div class="border border-[color:var(--border)] bg-white">
			{#each data.obras as obra (obra.obra_id)}
				<a
					href={`/obras/${obra.slug}`}
					class="group grid gap-2 border-b border-[color:var(--border)] px-4 py-3 last:border-b-0 hover:bg-[color:var(--muted)]/60 md:grid-cols-[minmax(0,1fr)_auto] md:items-center"
				>
					<div class="min-w-0">
						<div class="flex flex-wrap items-center gap-2">
							<h2 class="truncate font-display text-lg text-[color:var(--gray-900)]">{obra.titulo}</h2>
							{#if !obra.visible_publico}
								{#if obra.es_obra_asignada}
									<span class="border border-[color:var(--border)] bg-white px-2 py-0.5 text-[11px] text-[color:var(--muted-foreground)]">
										Tu ficha
									</span>
								{:else if data.canSeeAllPublished}
									<span class="border border-[color:var(--border)] bg-white px-2 py-0.5 text-[11px] text-[color:var(--muted-foreground)]">
										No visible
									</span>
								{/if}
							{/if}
						</div>
						<div class="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
							<span>Datación: {datacionLabel(obra)}</span>
							{#if obra.total_versos !== null}
								<span>{obra.total_versos} vv.</span>
							{/if}
						</div>
					</div>

					<span
						class="inline-flex h-8 w-8 items-center justify-center border border-[color:var(--border)] bg-white text-[color:var(--gray-700)] group-hover:border-[color:var(--primary)] group-hover:text-[color:var(--primary)]"
						aria-hidden="true"
					>
						<ArrowRight size={15} />
					</span>
				</a>
			{/each}
		</div>
	{/if}
</section>
