<script lang="ts">
	// Pie de distribución de formas REUTILIZABLE. Consume MetricDistributionSlice.
	// Leyenda desplegable: las formas con desglose por tipo de estrofa se expanden.
	import EChart from '$lib/components/charts/EChart.svelte';
	import { ChevronDown, ChevronRight } from 'lucide-svelte';
	import type { EChartsOption } from 'echarts';
	import type { MetricDistributionSlice } from './metric-display.types';
	import { buildDistributionGroups, type MetricDistributionGroup } from './metric-distribution';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		items: MetricDistributionSlice[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
		title?: string;
		/** Forma (slug/colorKey) a resaltar desde fuera (p.ej. hover en el barcode). */
		highlightedForma?: string | null;
		/** Notifica la forma sobrevolada en la leyenda (null al salir). */
		onHoverForma?: (forma: string | null) => void;
		/** Secuencias para construir el desglose forma → tipo/subtipo (opcional). */
		sequences?: {
			v_ini?: number;
			v_fin?: number;
			estrofa_forma_term: string;
			estrofa_tipo_term: string;
			n_versos: number;
			subtipos_estrofa?: { subtipo_estrofa_term: string; v_ini: number; v_fin: number }[];
		}[];
	}>();

	let expanded = $state<Record<string, boolean>>({});

	const groups = $derived.by((): MetricDistributionGroup[] => {
		const slices = props.items.filter((i: MetricDistributionSlice) => i.versos > 0);
		const built = buildDistributionGroups(slices, props.sequences ?? []);
		return built.sort(
			(a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es')
		);
	});

	function groupKey(item: MetricDistributionSlice) {
		return normalizeFormaKey(item.colorKey ?? item.forma);
	}

	// Forma resaltada desde fuera (hover en el barcode), normalizada.
	const highlightedFormaKey = $derived(
		props.highlightedForma ? normalizeFormaKey(props.highlightedForma) : null
	);
	const DIMMED_OPACITY = 0.35;

	function isDimmed(item: MetricDistributionSlice) {
		return highlightedFormaKey !== null && groupKey(item) !== highlightedFormaKey;
	}

	function valueLabel(versos: number, porcentaje: number): string {
		return props.valueMode === 'absolute' ? `${versos} vv.` : `${porcentaje.toFixed(2)}%`;
	}

	function toggle(forma: string) {
		expanded = { ...expanded, [forma]: !expanded[forma] };
	}

	const chartOption = $derived.by((): EChartsOption => {
		const colors = groups.map((item) => props.colorByForma[item.colorKey ?? item.forma] ?? '#9ca3af');
		return {
			color: colors,
			aria: {
				enabled: true
			},
			tooltip: {
				trigger: 'item',
				confine: true,
				textStyle: {
					fontSize: 11,
					lineHeight: 16
				},
				formatter: (params: unknown) => {
					const data = (params as { data?: MetricDistributionGroup }).data;
					if (!data) return '';
					return [
						`<strong>${data.forma}</strong>`,
						`Versos: ${data.versos}`,
						`Porcentaje: ${data.porcentaje.toFixed(2)}%`
					].join('<br />');
				}
			},
			series: [
				{
					name: 'Perfil métrico',
					type: 'pie',
					radius: ['42%', '76%'],
					center: ['50%', '50%'],
					avoidLabelOverlap: true,
					minAngle: 2,
					itemStyle: {
						borderColor: '#ffffff',
						borderWidth: 1
					},
					label: {
						show: false
					},
					labelLine: {
						show: false
					},
					emphasis: {
						scale: true,
						scaleSize: 4
					},
					data: groups.map((item) => ({
						...item,
						name: item.forma,
						value: item.versos,
						itemStyle: {
							opacity: isDimmed(item) ? DIMMED_OPACITY : 1
						}
					}))
				}
			]
		};
	});
</script>

<section class="space-y-3">
	<div class="flex items-center justify-between gap-2">
		<h3 class="text-base font-semibold">{props.title ?? 'Perfil métrico'}</h3>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.valueMode === 'percent' ? 'Valores en porcentaje' : 'Valores absolutos'}
		</p>
	</div>

	{#if groups.length === 0}
		<p class="text-sm text-[color:var(--muted-foreground)]">Sin distribución métrica disponible.</p>
	{:else}
		<div class="grid gap-6 md:grid-cols-[14rem_1fr] md:items-start">
			<EChart
				option={chartOption}
				height="14rem"
				class="mx-auto max-w-56"
				ariaLabel="Distribución de formas métricas"
			/>

			<ul class="divide-y divide-[color:var(--border)]">
				{#each groups as item (item.forma)}
					{@const hasChildren = item.children.length > 0}
					<li
						onpointerenter={() => props.onHoverForma?.(item.colorKey ?? item.forma)}
						onpointerleave={() => props.onHoverForma?.(null)}
					>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 py-2 text-left text-sm"
							class:cursor-default={!hasChildren}
							onclick={() => hasChildren && toggle(item.forma)}
							onfocus={() => props.onHoverForma?.(item.colorKey ?? item.forma)}
							onblur={() => props.onHoverForma?.(null)}
							aria-expanded={hasChildren ? Boolean(expanded[item.forma]) : undefined}
						>
							<span class="flex items-center gap-2">
								<span
									class="inline-block h-3 w-3 rounded-sm"
									style={`background:${props.colorByForma[item.colorKey ?? item.forma] ?? '#9ca3af'};`}
								></span>
								<span class="font-medium">{item.forma}</span>
								{#if hasChildren}
									{#if expanded[item.forma]}
										<ChevronDown class="h-3.5 w-3.5 text-[color:var(--muted-foreground)]" aria-hidden="true" />
									{:else}
										<ChevronRight class="h-3.5 w-3.5 text-[color:var(--muted-foreground)]" aria-hidden="true" />
									{/if}
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
