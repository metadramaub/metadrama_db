<script lang="ts">
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import MetricFormLabel from './MetricFormLabel.svelte';
	import type { MetricSequenceReference } from './metric-display.types';
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
	interface RunSummary {
		forma: string;
		colorKey: string;
		secuencias: number;
		versos: number;
		media: number;
		minima: number;
		maxima: number;
		tiradas: (MetricSequenceReference & { versos: number })[];
	}

	const props = $props<{
		rows: RunSummary[];
		colorByForma: Record<string, string>;
		onOpen: (sequenceId: string) => void;
	}>();
	let formaAbierta = $state<string | null>(null);
</script>

<section class="space-y-3" aria-labelledby="metric-runs-title">
	<MetricAnalysisHeading
		id="metric-runs-title"
		title="Secuencias por forma"
		description="Cuántas tiradas hay de cada forma y cuánto duran. Selecciona una forma para ver sus secuencias."
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
							<button
								type="button"
								class="inline-flex items-center gap-2 rounded text-left underline-offset-4 hover:underline focus-visible:outline focus-visible:outline-2"
								aria-expanded={formaAbierta === row.colorKey}
								onclick={() => (formaAbierta = formaAbierta === row.colorKey ? null : row.colorKey)}
							>
								<MetricFormLabel forma={row.forma} colorKey={row.colorKey} colorByForma={props.colorByForma} />
								<ChevronDown size={14} aria-hidden="true" />
							</button>
						</th>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.secuencias}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.versos}</td>
						<td class="px-3 py-2.5 text-right tabular-nums">{row.media} vv.</td>
						<td class="py-2.5 pr-4 pl-3 text-right tabular-nums">{row.minima}–{row.maxima} vv.</td>
					</tr>
					{#if formaAbierta === row.colorKey}
						<tr class="border-b border-[color:var(--border)]">
							<td colspan="5" class="px-4 py-2">
								<ul class="flex flex-wrap gap-2">
									{#each row.tiradas as tirada (tirada.secuencia_id)}
										<li>
											<button
												type="button"
												class="rounded border border-[color:var(--border)] px-2 py-1 text-sm tabular-nums hover:bg-[color:var(--muted)] focus-visible:outline focus-visible:outline-2"
												onclick={() => props.onOpen(tirada.secuencia_id)}
											>
												{tirada.v_ini === tirada.v_fin ? `v. ${tirada.v_ini}` : `vv. ${tirada.v_ini}–${tirada.v_fin}`} · {tirada.versos} vv.
											</button>
										</li>
									{/each}
								</ul>
							</td>
						</tr>
					{/if}
				{/each}
			</tbody>
		</table>
	</div>
</section>
