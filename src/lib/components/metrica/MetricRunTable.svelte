<script lang="ts">
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import MetricFormLabel from './MetricFormLabel.svelte';
	interface RunSummary {
		forma: string;
		colorKey: string;
		secuencias: number;
		versos: number;
		media: number;
		minima: number;
		maxima: number;
	}

	const props = $props<{
		rows: RunSummary[];
		colorByForma: Record<string, string>;
	}>();
</script>

<section class="space-y-3" aria-labelledby="metric-runs-title">
	<MetricAnalysisHeading
		id="metric-runs-title"
		title="Las secuencias de cada forma"
		description="Cuántas secuencias ocupa cada forma y qué extensión tienen."
	/>
	<div class="overflow-x-auto rounded-lg border border-[color:var(--border)] bg-white">
		<table class="w-full min-w-[38rem] border-collapse text-sm">
			<thead>
				<tr class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]">
					<th scope="col" class="py-2 pr-3 pl-4 font-semibold">Forma</th>
					<th scope="col" class="px-3 py-2 text-right font-semibold">Secuencias</th>
					<th scope="col" class="px-3 py-2 text-right font-semibold">Versos</th>
					<th scope="col" class="px-3 py-2 text-right font-semibold">Media</th>
					<th scope="col" class="py-2 pr-4 pl-3 text-right font-semibold">Mín.–máx.</th>
				</tr>
			</thead>
			<tbody>
				{#each props.rows as row (row.colorKey)}
					<tr class="border-b border-[color:var(--border)] last:border-b-0">
						<th scope="row" class="py-2.5 pr-3 pl-4 text-left font-medium">
							<MetricFormLabel forma={row.forma} colorKey={row.colorKey} colorByForma={props.colorByForma} />
						</th>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.secuencias}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.versos}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.media} vv.</td>
						<td class="py-2.5 pr-4 pl-3 text-right tabular-nums">{row.minima}–{row.maxima} vv.</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</section>
