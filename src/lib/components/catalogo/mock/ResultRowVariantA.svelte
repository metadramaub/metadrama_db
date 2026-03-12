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
	class={`card grid min-h-[88px] grid-cols-[minmax(12rem,1fr)_minmax(18rem,2.2fr)_minmax(9rem,0.9fr)] items-center gap-3 px-3 py-2 ${selected ? 'border-[color:var(--primary)] bg-[color:var(--gray-50)]' : ''}`}
>
	<div class="min-w-0">
		<p class="truncate text-sm font-semibold text-[color:var(--gray-900)]">{work.title}</p>
		<p class="truncate text-xs text-[color:var(--muted-foreground)]">{work.author}</p>
		<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{work.datingLabel} · {work.genre}</p>
	</div>

	<div class="min-w-0">
		<MetricBarcode work={work} height={30} />
	</div>

	<div class="flex min-w-0 items-center justify-end gap-3">
		<div class="text-right text-xs text-[color:var(--muted-foreground)]">
			<p>{work.totalVerses} vv.</p>
			<p>Polimetria {work.polymetryRatio.toFixed(1)}</p>
		</div>
		<label class="inline-flex items-center gap-2 text-xs font-semibold tracking-[0.06em]">
			<input
				type="checkbox"
				checked={selected}
				onchange={() => onToggle(work.id)}
				class="h-4 w-4 border border-[color:var(--border)]"
			/>
			<span>Comparar</span>
		</label>
	</div>
</article>
