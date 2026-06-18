<script lang="ts">
	// Pie de distribución de formas REUTILIZABLE. Consume MetricDistributionSlice.
	// Leyenda desplegable: las formas con desglose por tipo de estrofa se expanden.
	import type { MetricDistributionSlice } from './metric-display.types';
	import { buildDistributionGroups, type MetricDistributionGroup } from './metric-distribution';

	const props = $props<{
		items: MetricDistributionSlice[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
		/** Secuencias para construir el desglose forma → tipo (opcional). */
		sequences?: { estrofa_forma_term: string; estrofa_tipo_term: string; n_versos: number }[];
	}>();

	let expanded = $state<Record<string, boolean>>({});

	const groups = $derived.by((): MetricDistributionGroup[] => {
		const slices = props.items.filter((i: MetricDistributionSlice) => i.versos > 0);
		const built = buildDistributionGroups(slices, props.sequences ?? []);
		return built.sort(
			(a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es')
		);
	});

	const gradient = $derived.by(() => {
		if (groups.length === 0) return 'conic-gradient(#d1d5db 0deg, #d1d5db 360deg)';
		let offset = 0;
		const chunks: string[] = [];
		for (const item of groups) {
			const pct = Math.max(0, Math.min(100, item.porcentaje));
			const span = (pct / 100) * 360;
			const end = Math.min(360, offset + span);
			const color = props.colorByForma[item.forma] ?? '#9ca3af';
			chunks.push(`${color} ${offset}deg ${end}deg`);
			offset = end;
		}
		if (offset < 360) chunks.push(`#e5e7eb ${offset}deg 360deg`);
		return `conic-gradient(${chunks.join(',')})`;
	});

	function valueLabel(versos: number, porcentaje: number): string {
		return props.valueMode === 'absolute' ? `${versos} vv.` : `${porcentaje.toFixed(2)}%`;
	}

	function toggle(forma: string) {
		expanded = { ...expanded, [forma]: !expanded[forma] };
	}
</script>

<section class="space-y-3">
	<div class="flex items-center justify-between gap-2">
		<h3 class="text-base font-semibold">Perfil métrico</h3>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.valueMode === 'percent' ? 'Valores en porcentaje' : 'Valores absolutos'}
		</p>
	</div>

	{#if groups.length === 0}
		<p class="text-sm text-[color:var(--muted-foreground)]">Sin distribución métrica disponible.</p>
	{:else}
		<div class="grid gap-6 md:grid-cols-[14rem_1fr] md:items-start">
			<div
				class="mx-auto h-52 w-52 rounded-full"
				style={`background:${gradient};`}
				aria-hidden="true"
			></div>

			<ul class="divide-y divide-[color:var(--border)]">
				{#each groups as item (item.forma)}
					{@const hasChildren = item.children.length > 0}
					<li>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 py-2 text-left text-sm"
							class:cursor-default={!hasChildren}
							onclick={() => hasChildren && toggle(item.forma)}
							aria-expanded={hasChildren ? Boolean(expanded[item.forma]) : undefined}
						>
							<span class="flex items-center gap-2">
								<span
									class="inline-block h-3 w-3 rounded-sm"
									style={`background:${props.colorByForma[item.forma] ?? '#9ca3af'};`}
								></span>
								<span class="font-medium">{item.forma}</span>
								{#if hasChildren}
									<span class="text-[color:var(--muted-foreground)]" aria-hidden="true">
										{expanded[item.forma] ? '▾' : '▸'}
									</span>
								{/if}
							</span>
							<span class="text-[color:var(--muted-foreground)]">
								{valueLabel(item.versos, item.porcentaje)}
							</span>
						</button>

						{#if hasChildren && expanded[item.forma]}
							<ul class="mb-2 ml-5 border-l border-[color:var(--border)] pl-3">
								{#each item.children as child (child.label)}
									<li class="flex items-center justify-between gap-3 py-1 text-xs text-[color:var(--muted-foreground)]">
										<span>{child.label}</span>
										<span>{valueLabel(child.versos, child.porcentaje)}</span>
									</li>
								{/each}
							</ul>
						{/if}
					</li>
				{/each}
			</ul>
		</div>
	{/if}
</section>
