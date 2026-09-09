<script lang="ts">
	// Pie de distribución de formas REUTILIZABLE. Consume MetricDistributionSlice.
	// Leyenda desplegable: forma → arquitectura → respuestas observadas.
	import EChart from '$lib/components/charts/EChart.svelte';
	import { ChevronDown, ChevronRight } from 'lucide-svelte';
	import type { EChartsOption } from 'echarts';
	import type { MetricDistributionSlice } from './metric-display.types';
	import {
		buildDistributionGroups,
		formatMetricCount,
		pluralizeMetricUnit,
		type MetricDistributionGroup,
		type MetricDistributionSequence,
		type MetricDistributionValue
	} from './metric-distribution';
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
		/** Secuencias para construir el desglose del dominio (opcional). */
		sequences?: MetricDistributionSequence[];
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

	function featureLabel(item: MetricDistributionValue): string {
		return `${item.versos} vv. en ${formatMetricCount(item)}`;
	}

	function schemeLabel(item: MetricDistributionValue, items: MetricDistributionValue[]): string {
		const total = items
			.filter((candidate) => candidate.unidad === item.unidad)
			.reduce((sum, candidate) => sum + candidate.cantidad, 0);
		if (item.cantidad === total) return formatMetricCount(item);
		const pluralUnit = pluralizeMetricUnit(item.unidad, total);
		const share = total > 0 ? ((item.cantidad / total) * 100).toFixed(2) : '0.00';
		return `${item.cantidad} de ${total} ${pluralUnit} · ${share}%`;
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
				renderer="svg"
				ariaLabel="Distribución de formas métricas"
			/>

			<ul class="divide-y divide-[color:var(--border)]">
				{#each groups as item (item.forma)}
					{@const hasDetails = item.arquitecturas.length > 0}
					<li
						onpointerenter={() => props.onHoverForma?.(item.colorKey ?? item.forma)}
						onpointerleave={() => props.onHoverForma?.(null)}
					>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 py-2 text-left text-sm"
							class:cursor-default={!hasDetails}
							onclick={() => hasDetails && toggle(item.forma)}
							onfocus={() => props.onHoverForma?.(item.colorKey ?? item.forma)}
							onblur={() => props.onHoverForma?.(null)}
							aria-expanded={hasDetails ? Boolean(expanded[item.forma]) : undefined}
						>
							<span class="flex items-center gap-2">
								<span
									class="inline-block h-3 w-3 rounded-sm"
									style={`background:${props.colorByForma[item.colorKey ?? item.forma] ?? '#9ca3af'};`}
								></span>
								<span class="font-medium">{item.forma}</span>
								{#if hasDetails}
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

						{#if hasDetails && expanded[item.forma]}
							<div class="mb-3 ml-5 space-y-4 border-l border-[color:var(--border)] pl-3">
								{#each item.arquitecturas as arquitectura (arquitectura.slug ?? arquitectura.label)}
									<section class="space-y-2 py-1">
										<div class="flex items-baseline justify-between gap-3 text-xs">
											<h4 class="font-semibold text-[color:var(--foreground)]">{arquitectura.label}</h4>
											<span class="text-[color:var(--muted-foreground)]">{valueLabel(arquitectura.versos, arquitectura.porcentaje)}</span>
										</div>

										{#if arquitectura.esquemas.length > 0}
											<div>
												<p class="text-[0.68rem] font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Esquemas de rima</p>
												<ul>
											{#each arquitectura.esquemas as esquema (`${esquema.unidad}:${esquema.label}`)}
														<li class="flex items-center justify-between gap-3 py-0.5 text-xs text-[color:var(--muted-foreground)]">
															<span class="font-mono text-[color:var(--foreground)]">{esquema.label}</span>
															<span>{schemeLabel(esquema, arquitectura.esquemas)}</span>
														</li>
													{/each}
												</ul>
											</div>
										{/if}

										{#each arquitectura.rasgos as rasgo (rasgo.label)}
											<div>
												<p class="text-[0.68rem] font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">{rasgo.label}</p>
												<ul>
													{#each rasgo.values as value (value.label)}
														<li class="flex items-center justify-between gap-3 py-0.5 text-xs text-[color:var(--muted-foreground)]">
															<span class="text-[color:var(--foreground)]">{value.label}</span>
															<span>{featureLabel(value)}</span>
														</li>
													{/each}
												</ul>
											</div>
										{/each}

										{#if arquitectura.metros.length > 0}
											<p class="text-xs text-[color:var(--muted-foreground)]">
												<span class="font-semibold uppercase tracking-[0.06em]">Metros:</span>
												{arquitectura.metros.map((metro) => `${metro.label} (${metro.versos} vv.)`).join(' · ')}
											</p>
										{/if}

										{#if arquitectura.variedades.length > 0}
											<p class="text-xs text-[color:var(--muted-foreground)]">
												<span class="font-semibold uppercase tracking-[0.06em]">Variedades:</span>
												{arquitectura.variedades.map((variedad) => `${variedad.label} (${formatMetricCount(variedad)})`).join(' · ')}
											</p>
										{/if}
									</section>
								{/each}
							</div>
						{/if}
					</li>
				{/each}
			</ul>
		</div>
	{/if}
</section>
