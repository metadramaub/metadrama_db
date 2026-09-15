<script lang="ts">
	import EChart from '$lib/components/charts/EChart.svelte';
	import type { LaboratoryMetric } from '$lib/laboratorio/metricas';
	import type { EChartsOption } from 'echarts';

	const props = $props<{
		rows: Array<{ id: string; title: string; authors: string; value: number }>;
		metric: LaboratoryMetric;
		q1: number | null;
		median: number | null;
		q3: number | null;
		focusedId?: string | null;
		formatValue: (value: number | null) => string;
	}>();

	const escapeHtml = (value: string) =>
		value
			.replaceAll('&', '&amp;')
			.replaceAll('<', '&lt;')
			.replaceAll('>', '&gt;')
			.replaceAll('"', '&quot;');

	const axisValue = (value: number) => {
		if (props.metric.unit === 'porcentaje') return `${Math.round(value * 100)} %`;
		return value.toLocaleString('es', { maximumFractionDigits: 1 });
	};

	const option = $derived.by((): EChartsOption => {
		const data = props.rows.map((row, index) => ({
			value: [row.value, ((index % 7) - 3) * 0.075],
			id: row.id,
			title: row.title,
			authors: row.authors,
			metricValue: row.value,
			itemStyle: {
				color: row.id === props.focusedId ? '#cba44a' : '#535353',
				opacity: row.id === props.focusedId ? 1 : 0.72,
				borderColor: row.id === props.focusedId ? '#1a1a1a' : '#ffffff',
				borderWidth: 1
			}
		}));

		return {
			aria: { enabled: true },
			animationDuration: 250,
			grid: { top: 22, right: 24, bottom: 42, left: 24, containLabel: true },
			tooltip: {
				trigger: 'item',
				confine: true,
				formatter: (params: unknown) => {
					const point = (params as { data?: (typeof data)[number] }).data;
					if (!point) return '';
					return `<strong>${escapeHtml(point.title)}</strong><br>${escapeHtml(point.authors)}<br>${escapeHtml(props.formatValue(point.metricValue))}`;
				}
			},
			xAxis: {
				type: 'value',
				min: props.metric.unit === 'porcentaje' ? 0 : undefined,
				max: props.metric.unit === 'porcentaje' ? 1 : undefined,
				axisLabel: { color: '#535353', formatter: axisValue },
				axisLine: { lineStyle: { color: '#a3a3a3' } },
				splitLine: { lineStyle: { color: '#e6e6e6' } }
			},
			yAxis: { type: 'value', min: -0.42, max: 0.42, show: false },
			series: [
				{
					type: 'scatter',
					data,
					symbolSize: (value: unknown, params: unknown) =>
						(params as { data?: { id?: string } }).data?.id === props.focusedId ? 14 : 10,
					markArea:
						props.q1 !== null && props.q3 !== null
							? {
									silent: true,
									itemStyle: { color: 'rgba(203, 164, 74, 0.12)' },
									data: [[{ xAxis: props.q1 }, { xAxis: props.q3 }]]
								}
							: undefined,
					markLine:
						props.median !== null
							? {
									silent: true,
									symbol: 'none',
									lineStyle: { color: '#cba44a', width: 2 },
									label: { show: false },
									data: [{ xAxis: props.median }]
								}
							: undefined
				}
			]
		};
	});
</script>

<EChart
	{option}
	height="15rem"
	ariaLabel={`Distribución de ${props.metric.label.toLocaleLowerCase('es')} entre las obras de la muestra`}
/>

<div class="mt-1 flex items-center justify-end gap-4 text-[11px] text-[color:var(--muted-foreground)]">
	<span class="inline-flex items-center gap-1.5"><span class="h-2.5 w-5 bg-[rgba(203,164,74,0.16)]"></span>Rango central</span>
	<span class="inline-flex items-center gap-1.5"><span class="h-3 w-0.5 bg-[color:var(--primary)]"></span>Mediana</span>
</div>
