<script lang="ts">
	// Pie de distribución de formas REUTILIZABLE. Consume MetricDistributionSlice.
	import type { MetricDistributionSlice } from './metric-display.types';

	const props = $props<{
		items: MetricDistributionSlice[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
	}>();

	const normalizedItems = $derived.by(() =>
		props.items
			.filter((item: MetricDistributionSlice) => item.versos > 0)
			.sort(
				(a: MetricDistributionSlice, b: MetricDistributionSlice) =>
					b.versos - a.versos || a.forma.localeCompare(b.forma, 'es')
			)
	);

	const gradient = $derived.by(() => {
		if (normalizedItems.length === 0) return 'conic-gradient(#d1d5db 0deg, #d1d5db 360deg)';
		let offset = 0;
		const chunks: string[] = [];
		for (const item of normalizedItems) {
			const pct = Math.max(0, Math.min(100, item.porcentaje));
			const span = (pct / 100) * 360;
			const end = Math.min(360, offset + span);
			const color = props.colorByForma[item.forma] ?? '#9ca3af';
			chunks.push(`${color} ${offset}deg ${end}deg`);
			offset = end;
		}
		if (offset < 360) {
			chunks.push(`#e5e7eb ${offset}deg 360deg`);
		}
		return `conic-gradient(${chunks.join(',')})`;
	});

	function valueLabel(item: MetricDistributionSlice): string {
		if (props.valueMode === 'absolute') return `${item.versos} vv.`;
		return `${item.porcentaje.toFixed(2)}%`;
	}
</script>

<section class="card p-4">
	<div class="mb-3 flex items-center justify-between gap-2">
		<h3 class="text-base font-semibold">Perfil métrico</h3>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.valueMode === 'percent' ? 'Valores en porcentaje' : 'Valores absolutos'}
		</p>
	</div>

	{#if normalizedItems.length === 0}
		<p class="text-sm text-[color:var(--muted-foreground)]">Sin distribución métrica disponible.</p>
	{:else}
		<div class="grid gap-4 md:grid-cols-[15rem_1fr] md:items-start">
			<div class="mx-auto h-56 w-56 border border-[color:var(--border)] p-3">
				<div
					class="h-full w-full rounded-full border border-[color:var(--border)]"
					style={`background:${gradient};`}
					aria-hidden="true"
				></div>
			</div>
			<div class="space-y-2">
				{#each normalizedItems as item (item.forma)}
					<div class="flex items-center justify-between gap-3 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
						<div class="flex items-center gap-2">
							<span
								class="inline-block h-3 w-3 border border-[color:var(--border)]"
								style={`background:${props.colorByForma[item.forma] ?? '#9ca3af'};`}
							></span>
							<span class="font-medium">{item.forma}</span>
						</div>
						<span class="text-[color:var(--muted-foreground)]">{valueLabel(item)}</span>
					</div>
				{/each}
			</div>
		</div>
	{/if}
</section>
