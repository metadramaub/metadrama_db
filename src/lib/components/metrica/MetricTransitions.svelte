<script lang="ts">
	interface TransitionSummary {
		de: string;
		a: string;
		veces: number;
	}

	const props = $props<{ rows: TransitionSummary[] }>();
	const principales = $derived(props.rows.slice(0, 6));
	const restantes = $derived(props.rows.slice(6));
</script>

<section class="space-y-3" aria-labelledby="metric-transitions-title">
	<div class="flex flex-wrap items-start justify-between gap-3">
		<div>
			<h2 id="metric-transitions-title" class="text-lg font-semibold">Qué forma sigue a cuál</h2>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Transiciones entre secuencias consecutivas, incluidos los pasos de una jornada a otra.
			</p>
		</div>
		<span class="text-xs text-[color:var(--muted-foreground)]">Calculado</span>
	</div>

	<ol class="grid gap-2 md:grid-cols-2">
		{#each principales as row (`${row.de}:${row.a}`)}
			<li class="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)_auto] items-center gap-2 rounded-lg border border-[color:var(--border)] bg-white px-4 py-3 text-sm">
				<span class="truncate font-medium" title={row.de}>{row.de}</span>
				<span class="text-[color:var(--muted-foreground)]" aria-hidden="true">→</span>
				<span class="truncate font-medium" title={row.a}>{row.a}</span>
				<span class="ml-2 rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs tabular-nums text-[color:var(--muted-foreground)]">
					{row.veces} {row.veces === 1 ? 'vez' : 'veces'}
				</span>
			</li>
		{/each}
	</ol>

	{#if restantes.length > 0}
		<details class="group rounded-lg border border-[color:var(--border)] bg-white">
			<summary class="cursor-pointer px-4 py-3 text-sm font-medium">
				Ver {restantes.length} {restantes.length === 1 ? 'transición menos frecuente' : 'transiciones menos frecuentes'}
			</summary>
			<ol class="grid gap-x-6 border-t border-[color:var(--border)] px-4 py-2 md:grid-cols-2">
				{#each restantes as row (`${row.de}:${row.a}`)}
					<li class="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)_auto] items-center gap-2 border-b border-[color:var(--border)] py-2.5 text-sm last:border-b-0 md:[&:nth-last-child(2)]:border-b-0">
						<span class="truncate" title={row.de}>{row.de}</span>
						<span class="text-[color:var(--muted-foreground)]" aria-hidden="true">→</span>
						<span class="truncate" title={row.a}>{row.a}</span>
						<span class="ml-2 text-xs tabular-nums text-[color:var(--muted-foreground)]">
							{row.veces} {row.veces === 1 ? 'vez' : 'veces'}
						</span>
					</li>
				{/each}
			</ol>
		</details>
	{/if}
</section>
