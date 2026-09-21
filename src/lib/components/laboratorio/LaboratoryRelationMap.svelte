<script lang="ts">
	import EChart from '$lib/components/charts/EChart.svelte';
	import type { EChartsOption } from 'echarts';

	type RelationPoint = {
		id: string;
		label: string;
		x: number;
		y: number;
		color?: string;
		detail: string;
	};

	const props = $props<{
		points: RelationPoint[];
		xLabel: string;
		yLabel: string;
		ariaLabel: string;
	}>();

	const escapeHtml = (value: string) =>
		value
			.replaceAll('&', '&amp;')
			.replaceAll('<', '&lt;')
			.replaceAll('>', '&gt;')
			.replaceAll('"', '&quot;');

	const option = $derived.by((): EChartsOption => {
		const data = props.points.map((point: RelationPoint) => ({
			value: [point.x, point.y],
			label: point.label,
			detail: point.detail,
			itemStyle: {
				color: point.color ?? '#535353',
				opacity: 0.82,
				borderColor: '#ffffff',
				borderWidth: 1
			}
		}));

		return {
			aria: { enabled: true },
			animationDuration: 250,
			grid: { top: 18, right: 24, bottom: 52, left: 58, containLabel: true },
			tooltip: {
				trigger: 'item',
				confine: true,
				formatter: (params: unknown) => {
					const point = (params as { data?: (typeof data)[number] }).data;
					if (!point) return '';
					return `<strong>${escapeHtml(point.label)}</strong><br>${escapeHtml(point.detail)}`;
				}
			},
			xAxis: {
				type: 'value',
				min: 0,
				max: 100,
				name: props.xLabel,
				nameLocation: 'middle',
				nameGap: 34,
				axisLabel: { formatter: '{value} %', color: '#535353' },
				axisLine: { lineStyle: { color: '#a3a3a3' } },
				splitLine: { lineStyle: { color: '#e6e6e6' } }
			},
			yAxis: {
				type: 'value',
				min: 0,
				name: props.yLabel,
				nameLocation: 'middle',
				nameGap: 42,
				axisLabel: { color: '#535353' },
				axisLine: { lineStyle: { color: '#a3a3a3' } },
				splitLine: { lineStyle: { color: '#e6e6e6' } }
			},
			series: [{ type: 'scatter', data, symbolSize: 12 }]
		};
	});
</script>

<EChart {option} height="26rem" ariaLabel={props.ariaLabel} />
