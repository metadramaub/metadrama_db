<script lang="ts">
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
	<div>
		<h2 id="metric-runs-title" class="text-lg font-semibold">Las secuencias de cada forma</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Cuántas secuencias ocupa cada forma y qué extensión tienen.
		</p>
	</div>
	<div class="overflow-x-auto rounded-lg border border-[color:var(--border)] bg-white">
		<table class="w-full min-w-[38rem] text-sm">
			<thead>
				<tr class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]">
					<th scope="col" class="px-4 py-3 font-semibold">Forma</th>
					<th scope="col" class="px-3 py-3 text-right font-semibold">Secuencias</th>
					<th scope="col" class="px-3 py-3 text-right font-semibold">Versos</th>
					<th scope="col" class="px-3 py-3 text-right font-semibold">Media</th>
					<th scope="col" class="px-4 py-3 text-right font-semibold">Mín.–máx.</th>
				</tr>
			</thead>
			<tbody>
				{#each props.rows as row (row.colorKey)}
					<tr class="border-b border-[color:var(--border)] last:border-b-0">
						<th scope="row" class="px-4 py-2.5 text-left font-medium">
							<span class="inline-flex items-center gap-2">
								<span class="h-2.5 w-2.5 shrink-0 rounded-full" style={`background-color: ${props.colorByForma[row.colorKey] ?? 'var(--gray-400)'}`}></span>
								{row.forma}
							</span>
						</th>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.secuencias}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.versos}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.media} vv.</td>
						<td class="px-4 py-2.5 text-right tabular-nums">{row.minima}–{row.maxima} vv.</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</section>
