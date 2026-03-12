<script lang="ts">
	import MetricBarcode from './MetricBarcode.svelte';
	import type { MockCatalogWork } from '$lib/mock/catalogo-mock';

	let {
		work,
		selected,
		onToggle
	} = $props<{
		work: MockCatalogWork;
		selected: boolean;
		onToggle: (workId: string) => void;
	}>();
</script>

<article
	class={`card grid min-h-[72px] grid-cols-[minmax(8rem,1.8fr)_minmax(6.5rem,1.3fr)_minmax(4.5rem,0.8fr)_minmax(5.5rem,0.9fr)_minmax(6rem,1fr)_minmax(10rem,2.4fr)_3rem] items-center gap-2 px-3 py-2 text-xs ${selected ? 'border-[color:var(--primary)] bg-[color:var(--gray-50)]' : ''}`}
>
	<p class="truncate font-semibold text-[color:var(--gray-900)]">{work.title}</p>
	<p class="truncate text-[color:var(--muted-foreground)]">{work.author}</p>
	<p class="text-[color:var(--muted-foreground)]">{work.datingLabel}</p>
	<p class="truncate text-[color:var(--muted-foreground)]">{work.genre}</p>
	<div class="text-[color:var(--muted-foreground)]">
		<p>{work.topMetrics[0]}</p>
		<p class="mt-1">P {work.polymetryRatio.toFixed(1)}</p>
	</div>
	<div class="min-w-0">
		<MetricBarcode work={work} height={24} />
	</div>
	<label class="inline-flex items-center justify-end gap-2 font-semibold tracking-[0.06em]">
		<input
			type="checkbox"
			checked={selected}
			onchange={() => onToggle(work.id)}
			class="h-4 w-4 border border-[color:var(--border)]"
		/>
		<span>Lab</span>
	</label>
</article>
