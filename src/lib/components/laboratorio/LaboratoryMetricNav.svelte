<script lang="ts">
	import {
		LABORATORY_METRIC_GROUPS,
		LABORATORY_METRICS
	} from '$lib/laboratorio/metricas';

	const props = $props<{
		selectedId: string;
		onSelect: (id: string) => void;
	}>();
</script>

<nav class="border-y border-[color:var(--border)] bg-white py-3" aria-label="Medidas disponibles">
	{#each LABORATORY_METRIC_GROUPS as group (group)}
		<div class="py-2 first:pt-0 last:pb-0">
			<h3 class="px-4 text-[10px] font-semibold uppercase tracking-[0.14em] text-[color:var(--muted-foreground)]">
				{group}
			</h3>
			<div class="mt-1">
				{#each LABORATORY_METRICS.filter((metric) => metric.group === group) as metric (metric.id)}
					<button
						type="button"
						class={`w-full border-l-2 px-4 py-1.5 text-left text-sm transition-colors ${props.selectedId === metric.id ? 'border-[color:var(--primary)] bg-[color:var(--muted)] font-semibold' : 'border-transparent hover:bg-[color:var(--gray-50)]'}`}
						onclick={() => props.onSelect(metric.id)}
					>
						{metric.label}
					</button>
				{/each}
			</div>
		</div>
	{/each}
</nav>
