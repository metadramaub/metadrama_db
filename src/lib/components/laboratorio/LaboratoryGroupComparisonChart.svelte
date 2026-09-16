<script lang="ts">
	import EChart from '$lib/components/charts/EChart.svelte';
	import LaboratoryPercentageScaleNote from '$lib/components/laboratorio/LaboratoryPercentageScaleNote.svelte';
	import {
		formatLaboratoryAxisTick,
		getLaboratoryAxisScale
	} from '$lib/laboratorio/chart-scale';
	import type {
		LaboratoryMetric,
		LaboratoryValueSummary
	} from '$lib/laboratorio/metricas';
	import type { EChartsOption } from 'echarts';

	type GroupRow = {
		id: string;
		title: string;
		authors: string;
		value: number;
	};
	type GroupPoint = {
		value: number;
		rows: GroupRow[];
		focused: boolean;
	};

	const props = $props<{
		metric: LaboratoryMetric;
		groupA: { label: string; color: string; rows: GroupRow[]; summary: LaboratoryValueSummary };
		groupB: { label: string; color: string; rows: GroupRow[]; summary: LaboratoryValueSummary };
		focusedId?: string | null;
		formatValue: (value: number | null) => string;
	}>();

	const escapeHtml = (value: string) =>
		value
			.replaceAll('&', '&amp;')
			.replaceAll('<', '&lt;')
			.replaceAll('>', '&gt;')
			.replaceAll('"', '&quot;');

	const axisScale = $derived(
		getLaboratoryAxisScale(props.metric, [
			...props.groupA.rows.map((row) => row.value),
			...props.groupB.rows.map((row) => row.value)
		])
	);
	const axisValue = (value: number) => formatLaboratoryAxisTick(value, props.metric, axisScale);

	function groupCoincidentRows(rows: GroupRow[]): GroupPoint[] {
		const byValue = new Map<number, GroupRow[]>();
		for (const row of rows) {
			const coincident = byValue.get(row.value) ?? [];
			coincident.push(row);
			byValue.set(row.value, coincident);
		}

		return [...byValue.entries()]
			.map(([value, coincident]) => ({
				value,
				rows: coincident,
				focused: coincident.some((row) => row.id === props.focusedId)
			}))
			.sort((a, b) => a.value - b.value);
	}

	const option = $derived.by((): EChartsOption => {
		const groups = [props.groupB, props.groupA];
		const scatterSeries = groups.map((group) => {
			const data = groupCoincidentRows(group.rows).map((point) => ({
				value: [point.value, group.label],
				rows: point.rows,
				focused: point.focused,
				groupLabel: group.label,
				metricValue: point.value,
				itemStyle: {
					color: point.focused ? '#1a1a1a' : group.color,
					opacity: point.focused ? 1 : 0.82,
					borderColor: point.focused ? group.color : '#ffffff',
					borderWidth: point.focused ? 3 : 1
				}
			}));
			return {
				name: group.label,
				type: 'scatter' as const,
				data,
				symbolSize: (value: unknown, params: unknown) => {
					const point = (params as { data?: { rows?: GroupRow[]; focused?: boolean } }).data;
					const count = point?.rows?.length ?? 1;
					return Math.min(point?.focused ? 22 : 19, (point?.focused ? 15 : 10) + (count - 1) * 3);
				}
			};
		});
		const rangeSeries = groups.flatMap((group) => {
			if (group.summary.q1 === null || group.summary.q3 === null) return [];
			return [
				{
					name: `${group.label}: rango central`,
					type: 'line' as const,
					data: [
						[group.summary.q1, group.label],
						[group.summary.q3, group.label]
					],
					symbol: 'none',
					silent: true,
					lineStyle: { color: group.color, width: 8, opacity: 0.2 }
				}
			];
		});
		const medianData = groups
			.filter((group) => group.summary.median !== null)
			.map((group) => ({
				value: [group.summary.median as number, group.label],
				itemStyle: { color: group.color, borderColor: '#ffffff', borderWidth: 2 }
			}));

		return {
			aria: { enabled: true },
			animationDuration: 250,
			grid: { top: 22, right: 24, bottom: 44, left: 24, containLabel: true },
			tooltip: {
				trigger: 'item',
				confine: true,
				formatter: (params: unknown) => {
					const point = (params as {
						data?: { rows?: GroupRow[]; groupLabel?: string; metricValue?: number };
					}).data;
					if (!point?.rows?.length || point.metricValue === undefined) return '';
					const works = point.rows
						.map((row) => `<strong>${escapeHtml(row.title)}</strong><br>${escapeHtml(row.authors)}`)
						.join('<br>');
					return `<strong>${escapeHtml(point.groupLabel ?? '')} · ${escapeHtml(props.formatValue(point.metricValue))}</strong><br>${works}`;
				}
			},
			xAxis: {
				type: 'value',
				min: axisScale.minimum,
				max: axisScale.maximum,
				axisLabel: { color: '#535353', formatter: axisValue },
				axisLine: { lineStyle: { color: '#a3a3a3' } },
				splitLine: { lineStyle: { color: '#e6e6e6' } }
			},
			yAxis: {
				type: 'category',
				data: [props.groupB.label, props.groupA.label],
				axisLabel: {
					fontWeight: 700,
					formatter: (value: string) =>
						value === props.groupA.label ? `{groupA|${value}}` : `{groupB|${value}}`,
					rich: {
						groupA: { color: props.groupA.color, fontWeight: 700 },
						groupB: { color: props.groupB.color, fontWeight: 700 }
					}
				},
				axisTick: { show: false },
				axisLine: { show: false },
				splitLine: { show: true, lineStyle: { color: '#e6e6e6' } }
			},
			series: [
				...rangeSeries,
				...scatterSeries,
				{
					name: 'Medianas',
					type: 'scatter',
					data: medianData,
					symbol: 'diamond',
					symbolSize: 17,
					silent: true,
					z: 5
				}
			]
		};
	});
</script>

<EChart
	{option}
	height="16rem"
	ariaLabel={`Comparación de ${props.metric.label.toLocaleLowerCase('es')} entre ${props.groupA.label} y ${props.groupB.label}`}
/>

<LaboratoryPercentageScaleNote scale={axisScale} />

<p class="mt-2 text-xs leading-5 text-[color:var(--muted-foreground)]">
	El eje horizontal muestra el valor de la medida. Las dos franjas horizontales solo separan los grupos:
	no ordenan las obras ni representan otra magnitud. Un punto mayor reúne obras con exactamente el mismo valor.
</p>

<div class="mt-1 flex flex-wrap items-center justify-end gap-4 text-[11px] text-[color:var(--muted-foreground)]">
	<span class="inline-flex items-center gap-1.5"><span class="h-2.5 w-5 bg-[rgba(83,83,83,0.16)]"></span>Rango central</span>
	<span class="inline-flex items-center gap-1.5"><span class="h-3 w-3 rotate-45 bg-[color:var(--foreground)]"></span>Mediana</span>
	{#if props.focusedId}
		<span class="inline-flex items-center gap-1.5"><span class="h-3 w-3 rounded-full border-2 border-[color:var(--gray-500)] bg-[color:var(--foreground)]"></span>Obra de referencia</span>
	{/if}
</div>
