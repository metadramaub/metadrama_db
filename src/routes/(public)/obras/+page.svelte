<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
</script>

<section>
	<h1 class="font-display text-3xl text-[color:var(--gray-900)]">CATÁLOGO DE OBRAS</h1>
	<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
		{#if data.canSeeAllPublished}
			Vista editorial (admin/IP): incluye obras publicadas no visibles sin login.
		{:else}
			Vista pública: solo obras publicadas y visibles sin login.
		{/if}
	</p>

	<div class="mt-6 grid gap-3">
		{#if data.obras.length === 0}
			<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">
				No hay obras disponibles para esta vista.
			</div>
		{:else}
			{#each data.obras as obra}
				<article class="card p-4">
					<div class="flex flex-wrap items-start justify-between gap-2">
						<div>
							<h2 class="font-display text-xl">
								<a class="underline-offset-2 hover:underline" href={`/obras/${obra.obra_id}`}>{obra.titulo}</a>
							</h2>
							<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
								{(obra.autoria_autores ?? []).length > 0 ? (obra.autoria_autores ?? []).join(', ') : 'Autor�a no indicada'}
							</p>
						</div>
						{#if data.canSeeAllPublished && !obra.visible_publico}
							<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
								Solo con login editorial
							</span>
						{/if}
					</div>
					<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
						Tradicional: {obra.fecha_inicio_trad ?? '--'} - {obra.fecha_fin_trad ?? '--'} |
						Metadrama: {obra.fecha_inicio_metadrama ?? '--'} - {obra.fecha_fin_metadrama ?? '--'}
					</p>
				</article>
			{/each}
		{/if}
	</div>
</section>
