<script lang="ts">
	// Código de barras métrico REUTILIZABLE (ficha, catálogo, autor).
	// Consume MetricBarSegment genérico, no PublicFichaSecuencia.
	import { scaleLinear } from 'd3-scale';
	import { ArrowRight } from 'lucide-svelte';
	import type { MetricBarSegment } from './metric-display.types';

	interface PositionedSegment {
		segment: MetricBarSegment;
		x: number;
		width: number;
		color: string;
	}

	const props = $props<{
		segments: MetricBarSegment[];
		totalVerses: number;
		rangeStart?: number;
		rangeEnd?: number;
		jornadaMarkers?: number[];
		cuadroMarkers?: number[];
		colorByForma: Record<string, string>;
		onOpenSegment?: (id: string) => void;
		trackHeight?: number;
		/** Mostrar sub-segmentos (subtipos) como divisiones internas. */
		showSubsegments?: boolean;
	}>();

	let activeTooltipId = $state<string | null>(null);
	let lastPointerType = $state<string>('mouse');

	const viewStart = $derived(props.rangeStart ?? 1);
	const viewEnd = $derived(props.rangeEnd ?? Math.max(props.totalVerses, viewStart));
	const trackHeight = $derived(props.trackHeight ?? 30);
	const interactive = $derived(typeof props.onOpenSegment === 'function');
	const xScale = $derived.by(() =>
		scaleLinear().domain([viewStart, viewEnd + 1]).range([0, 100]).clamp(true)
	);

	function positionOf(vIni: number, vFin: number) {
		const boundedStart = Math.max(vIni, viewStart);
		const boundedEnd = Math.min(vFin, viewEnd);
		const x = xScale(boundedStart);
		const width = xScale(boundedEnd + 1) - x;
		return {
			x: Math.max(0, x),
			width: Math.max(0.7, width)
		};
	}

	const positionedSegments = $derived.by(() => {
		return props.segments
			.filter((s: MetricBarSegment) => s.v_fin >= viewStart && s.v_ini <= viewEnd)
			.map((segment: MetricBarSegment) => {
				const { x, width } = positionOf(segment.v_ini, segment.v_fin);
				const color = props.colorByForma[segment.forma] ?? '#9ca3af';
				return { segment, x, width, color } satisfies PositionedSegment;
			});
	});

	const jornadaMarkers = $derived.by(() =>
		(props.jornadaMarkers ?? [])
			.filter((m: number) => m > viewStart && m < viewEnd)
			.map((m: number) => xScale(m + 1))
	);
	const cuadroMarkers = $derived.by(() =>
		(props.cuadroMarkers ?? [])
			.filter((m: number) => m > viewStart && m < viewEnd)
			.map((m: number) => xScale(m + 1))
	);

	function open(id: string) {
		activeTooltipId = null;
		props.onOpenSegment?.(id);
	}

	function subsegmentX(parent: MetricBarSegment, sub: { v_ini: number; v_fin: number }) {
		const x = xScale(Math.max(sub.v_ini, parent.v_ini));
		return Math.max(0, Math.min(100, x));
	}

	function visibleSubsegments(segment: MetricBarSegment) {
		return (segment.subsegments ?? []).filter((sub) => sub.v_ini > segment.v_ini);
	}

	function segmentTitle(segment: MetricBarSegment) {
		const verses = `Versos ${segment.v_ini}-${segment.v_fin}`;
		const count = segment.n_versos !== undefined ? `, ${segment.n_versos} versos` : '';
		return `${segment.label}. ${verses}${count}`;
	}

	function subtypesLabel(segment: MetricBarSegment) {
		const count = segment.subsegments?.length ?? 0;
		if (count === 0) return null;
		return `${count} subtipo${count === 1 ? '' : 's'}`;
	}

	function handleHotspotClick(id: string) {
		if (lastPointerType === 'touch' || lastPointerType === 'pen') {
			if (activeTooltipId === id) {
				open(id);
				return;
			}
			activeTooltipId = id;
			return;
		}

		open(id);
	}
</script>

<div class="w-full">
	<div
		class="relative z-20 w-full overflow-visible border border-[color:var(--border)] bg-[color:var(--gray-100)]"
		style={`height:${trackHeight}px;`}
	>
		<svg
			class="block h-full w-full"
			viewBox={`0 0 100 ${trackHeight}`}
			preserveAspectRatio="none"
			role="img"
			aria-label="Código de barras métrico"
		>
			{#each positionedSegments as item (item.segment.id)}
				<g
					role="img"
					aria-label={`Versos ${item.segment.v_ini}-${item.segment.v_fin}, ${item.segment.label}`}
				>
					<rect x={item.x} y="0" width={item.width} height={trackHeight} fill={item.color}></rect>

					{#if props.showSubsegments && item.segment.subsegments && item.segment.subsegments.length > 0}
						{#each visibleSubsegments(item.segment) as sub (sub.id)}
							<line
								x1={subsegmentX(item.segment, sub)}
								x2={subsegmentX(item.segment, sub)}
								y1="0"
								y2={trackHeight}
								stroke="rgba(255,255,255,0.65)"
								stroke-width="0.25"
							></line>
						{/each}
					{/if}
				</g>
			{/each}

			{#each cuadroMarkers as marker, index (`cuadro-${index}`)}
				<line
					x1={marker}
					x2={marker}
					y1="0"
					y2={trackHeight}
					stroke="var(--gray-500)"
					stroke-width="0.25"
					stroke-dasharray="1 1"
				></line>
			{/each}

			{#each jornadaMarkers as marker, index (`jornada-${index}`)}
				<line
					x1={marker}
					x2={marker}
					y1="0"
					y2={trackHeight}
					stroke="var(--gray-900)"
					stroke-width="0.5"
				></line>
			{/each}
		</svg>

		{#if interactive}
			{#each positionedSegments as item (item.segment.id)}
				<div class="metric-bar-hover group absolute inset-y-0 z-30" style={`left:${item.x}%;width:${item.width}%;`}>
					<button
						type="button"
						class="metric-bar-hotspot absolute inset-0 block p-0"
						aria-label={`${activeTooltipId === item.segment.id ? 'Abrir detalle' : 'Mostrar detalle'}. ${segmentTitle(item.segment)}`}
						onpointerdown={(event) => (lastPointerType = event.pointerType)}
						onclick={() => handleHotspotClick(item.segment.id)}
					></button>

					<div
						class={`pointer-events-auto absolute left-1/2 top-0 z-40 w-64 -translate-x-1/2 -translate-y-[110%] border border-[color:var(--border)] bg-white p-2 text-[11px] leading-tight shadow-sm group-hover:block group-focus-within:block ${activeTooltipId === item.segment.id ? 'block' : 'hidden'}`}
					>
						<div class="flex items-start justify-between gap-2">
							<div class="min-w-0">
								<div class="font-semibold text-[color:var(--gray-900)]">{item.segment.label}</div>
								<div class="mt-1 text-[color:var(--muted-foreground)]">
									Versos: {item.segment.v_ini}-{item.segment.v_fin}
								</div>
								{#if item.segment.n_versos !== undefined}
									<div class="mt-1 text-[color:var(--muted-foreground)]">Nº versos: {item.segment.n_versos}</div>
								{/if}
								{#if subtypesLabel(item.segment)}
									<div class="mt-1 text-[color:var(--muted-foreground)]">{subtypesLabel(item.segment)}</div>
								{/if}
							</div>
							<button
								type="button"
								class="shrink-0 border border-[color:var(--border)] bg-white p-1 text-[color:var(--gray-800)] hover:bg-[color:var(--muted)]"
								aria-label={`Abrir detalle. ${segmentTitle(item.segment)}`}
								onpointerdown={(event) => (lastPointerType = event.pointerType)}
								onclick={(event) => {
									event.stopPropagation();
									open(item.segment.id);
								}}
							>
								<ArrowRight class="h-3.5 w-3.5" aria-hidden="true" />
							</button>
						</div>
					</div>
				</div>
			{/each}
		{/if}
	</div>
</div>

<style>
	.metric-bar-hover {
		overflow: visible;
	}

	.metric-bar-hotspot {
		cursor: pointer;
		background: transparent;
	}

	.metric-bar-hover:hover .metric-bar-hotspot,
	.metric-bar-hover:focus-within .metric-bar-hotspot {
		box-shadow: inset 0 0 0 1px var(--gray-900);
		outline: none;
	}
</style>
