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

<div class="flex items-start gap-3">
	<label class="pt-1" aria-label={`Seleccionar ${work.title}`}>
		<input
			type="checkbox"
			checked={selected}
			onchange={() => onToggle(work.id)}
			class="h-4 w-4 border border-[color:var(--border)]"
		/>
	</label>

	<article class={`card min-h-[112px] flex-1 px-3 py-2 ${selected ? 'border-[color:var(--primary)] bg-[color:var(--gray-50)]' : ''}`}>
		<div class="flex items-start justify-between gap-4">
			<div class="min-w-0">
				<p class="truncate text-sm font-semibold text-[color:var(--gray-900)]">{work.title}</p>
				<p class="truncate text-xs text-[color:var(--muted-foreground)]">{work.author}</p>
			</div>
			<div class="shrink-0 text-right text-xs text-[color:var(--muted-foreground)]">
				<p>{work.datingLabel}</p>
				<p>{work.genre}</p>
			</div>
		</div>

		<div class="mt-3">
			<MetricBarcode work={work} height={30} />
		</div>

		<div class="mt-3 flex items-center justify-between text-xs text-[color:var(--muted-foreground)]">
			<p>Score polimetría: {work.polymetryRatio.toFixed(1)}</p>
			<p>{work.totalVerses} vv.</p>
		</div>
	</article>
</div>
