<script lang="ts">
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import type { ECharts, SetOptionOpts } from 'echarts/core';
	import type { EChartsOption } from 'echarts';

	const props = $props<{
		option: EChartsOption;
		class?: string;
		height?: string;
		renderer?: 'canvas' | 'svg';
		ariaLabel?: string;
		notMerge?: boolean;
		lazyUpdate?: boolean;
	}>();

	type EChartsRuntime = Pick<typeof import('echarts/core'), 'init'>;

	let runtimePromise: Promise<EChartsRuntime> | null = null;

	function loadECharts(): Promise<EChartsRuntime> {
		runtimePromise ??= Promise.all([
			import('echarts/core'),
			import('echarts/charts'),
			import('echarts/components'),
			import('echarts/renderers')
		]).then(([core, charts, components, renderers]) => {
			core.use([
				charts.PieChart,
				components.AriaComponent,
				components.LegendComponent,
				components.TitleComponent,
				components.TooltipComponent,
				renderers.CanvasRenderer,
				renderers.SVGRenderer
			]);
			return { init: core.init };
		});

		return runtimePromise;
	}

	let container: HTMLDivElement;
	let chart: ECharts | null = null;
	let mounted = $state(false);
	let resizeObserver: ResizeObserver | null = null;

	const setOptionOpts = $derived<SetOptionOpts>({
		notMerge: props.notMerge ?? true,
		lazyUpdate: props.lazyUpdate ?? false
	});

	onMount(() => {
		if (!browser || !container) return;

		let cancelled = false;

		void loadECharts().then(({ init }) => {
			if (cancelled || !container) return;

			chart = init(container, null, {
				renderer: props.renderer ?? 'canvas'
			});
			mounted = true;
			chart.setOption(props.option, setOptionOpts);

			resizeObserver = new ResizeObserver(() => {
				chart?.resize();
			});
			resizeObserver.observe(container);
		});

		return () => {
			cancelled = true;
			resizeObserver?.disconnect();
			resizeObserver = null;
			chart?.dispose();
			chart = null;
			mounted = false;
		};
	});

	$effect(() => {
		if (!mounted || !chart) return;
		chart.setOption(props.option, setOptionOpts);
	});
</script>

<div
	bind:this={container}
	class={`w-full ${props.class ?? ''}`}
	style={`height:${props.height ?? '16rem'};`}
	role={props.ariaLabel ? 'img' : undefined}
	aria-label={props.ariaLabel}
></div>
