<script lang="ts">
	import EChart from '$lib/components/charts/EChart.svelte';
	import type { EChartsOption } from 'echarts';

	type MiniMetricSlice = {
		slug: string;
		label: string;
		versos: number;
		pct: number;
		color: string;
	};

	const props = $props<{
		slices: MiniMetricSlice[];
		size?: 'sm' | 'md';
	}>();

	const visibleSlices = $derived.by((): MiniMetricSlice[] =>
		props.slices.filter((slice: MiniMetricSlice) => slice.versos > 0)
	);
	const dominant = $derived<MiniMetricSlice | null>(visibleSlices[0] ?? null);
	const topSlices = $derived(visibleSlices.slice(0, 5));
	const restCount = $derived(Math.max(0, visibleSlices.length - topSlices.length));
	const chartSize = $derived(props.size === 'md' ? '7.25rem' : '3rem');
	const chartClass = $derived(props.size === 'md' ? 'h-[7.25rem] w-[7.25rem]' : 'h-12 w-12');
	const contentClass = $derived(props.size === 'md' ? 'min-h-[7.25rem]' : 'min-h-12');

	const chartOption = $derived.by((): EChartsOption => ({
		color: visibleSlices.map((slice: MiniMetricSlice) => slice.color),
		aria: {
			enabled: true
		},
		tooltip: {
			show: false
		},
		series: [
			{
				name: 'Perfil métrico',
				type: 'pie',
				radius: ['48%', '78%'],
				center: ['50%', '50%'],
				minAngle: 3,
				avoidLabelOverlap: false,
				silent: true,
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
					scale: false
				},
				data: visibleSlices.map((slice: MiniMetricSlice) => ({
					name: slice.label,
					value: slice.versos
				}))
			}
		]
	}));
</script>

{#if dominant}
	<div class="grid grid-cols-[auto_minmax(0,1fr)] items-stretch gap-4">
		<EChart
			option={chartOption}
			height={chartSize}
			renderer="svg"
			class={`${chartClass} pointer-events-none shrink-0`}
			ariaLabel={`Distribución métrica agregada; forma dominante: ${dominant.label}`}
		/>
		<div class={`${contentClass} flex min-w-0 flex-col justify-center text-xs`}>
			<p class="text-[color:var(--muted-foreground)]">Formas dominantes</p>
			<ul class="mt-1 space-y-0.5">
				{#each topSlices as slice (slice.slug)}
					<li class="flex min-w-0 items-center gap-1.5">
						<span class="inline-block h-2.5 w-2.5 shrink-0 rounded-sm" style={`background:${slice.color};`}></span>
						<span class="truncate font-semibold text-[color:var(--gray-900)]">{slice.label}</span>
						<span class="shrink-0 text-[color:var(--muted-foreground)]">
							{slice.pct.toLocaleString('es-ES', { maximumFractionDigits: 1 })}%
						</span>
					</li>
				{/each}
			</ul>
			{#if restCount > 0}
				<p class="mt-0.5 text-[11px] text-[color:var(--muted-foreground)]">
					+{restCount} {restCount === 1 ? 'forma' : 'formas'}
				</p>
			{/if}
		</div>
	</div>
{/if}
