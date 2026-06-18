<script lang="ts">
	// Código de barras métrico REUTILIZABLE (ficha, catálogo, autor).
	// Consume MetricBarSegment genérico, no PublicFichaSecuencia.
	import { scaleLinear } from 'd3-scale';
	import { ArrowRight } from 'lucide-svelte';
	import type { MetricBarSegment } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

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
		/** Forma (slug/colorKey) a resaltar desde fuera (p.ej. hover en la leyenda). */
		highlightedForma?: string | null;
	}>();

	let activeTooltipId = $state<string | null>(null);
	let hoveredId = $state<string | null>(null);
	let lastPointerType = $state<string>('mouse');

	// Secuencia "enfocada" (hover de puntero o tooltip táctil abierto). Cuando hay
	// una, las demás se atenúan para destacarla.
	const focusedId = $derived(hoveredId ?? activeTooltipId);
	// Forma resaltada desde fuera (hover en la leyenda del pie), normalizada.
	const highlightedFormaKey = $derived(
		props.highlightedForma ? normalizeFormaKey(props.highlightedForma) : null
	);
	const DIMMED_OPACITY = 0.35;

	function segmentFormaKey(segment: MetricBarSegment) {
		return normalizeFormaKey(segment.colorKey ?? segment.forma);
	}

	function isSegmentDimmed(segment: MetricBarSegment) {
		// Prioridad: resalte por forma (externo) sobre el hover de una secuencia.
		if (highlightedFormaKey) return segmentFormaKey(segment) !== highlightedFormaKey;
		if (focusedId) return focusedId !== segment.id;
		return false;
	}

	const viewStart = $derived(props.rangeStart ?? 1);
	const viewEnd = $derived(props.rangeEnd ?? Math.max(props.totalVerses, viewStart));
	const trackHeight = $derived(props.trackHeight ?? 30);
	// Las líneas de jornada/cuadro sobresalen por arriba y abajo del track para
	// que destaquen sobre los segmentos. El SVG reserva ese margen vertical.
	const markerOverhang = $derived(Math.max(3, trackHeight * 0.18));
	const svgHeight = $derived(trackHeight + markerOverhang * 2);
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
				const color = props.colorByForma[segment.colorKey ?? segment.forma] ?? '#9ca3af';
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

	// Formas cuyas subdivisiones no se dibujan: en una tirada de quintillas el
	// desglose interno es tan menudo que confunde, y se sobreentiende que va
	// dividida en quintillas.
	const SUBSEGMENT_HIDDEN_FORMS = new Set(['quintilla']);

	function hasHiddenSubsegments(segment: MetricBarSegment) {
		const key = normalizeFormaKey(segment.colorKey ?? segment.forma);
		return SUBSEGMENT_HIDDEN_FORMS.has(key);
	}

	function visibleSubsegments(segment: MetricBarSegment) {
		if (hasHiddenSubsegments(segment)) return [];
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
			class="metric-bar-svg block w-full"
			style={`height:${svgHeight}px;margin-top:-${markerOverhang}px;margin-bottom:-${markerOverhang}px;`}
			viewBox={`0 ${-markerOverhang} 100 ${svgHeight}`}
			preserveAspectRatio="none"
			role="img"
			aria-label="Código de barras métrico"
		>
			{#each positionedSegments as item (item.segment.id)}
				<g
					role="img"
					aria-label={`Versos ${item.segment.v_ini}-${item.segment.v_fin}, ${item.segment.label}`}
					opacity={isSegmentDimmed(item.segment) ? DIMMED_OPACITY : 1}
					style="transition:opacity 120ms ease;"
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
					y1={-markerOverhang}
					y2={trackHeight + markerOverhang}
					stroke="var(--gray-500)"
					stroke-width="0.3"
					stroke-dasharray="1 1"
				></line>
			{/each}

			{#each jornadaMarkers as marker, index (`jornada-${index}`)}
				<line
					x1={marker}
					x2={marker}
					y1={-markerOverhang}
					y2={trackHeight + markerOverhang}
					stroke="var(--gray-900)"
					stroke-width="0.6"
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
						onpointerenter={(event) => {
							if (event.pointerType === 'mouse') hoveredId = item.segment.id;
						}}
						onpointerleave={() => (hoveredId = null)}
						onfocus={() => (hoveredId = item.segment.id)}
						onblur={() => (hoveredId = null)}
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
	.metric-bar-svg {
		overflow: visible;
	}

	.metric-bar-hover {
		overflow: visible;
	}

	.metric-bar-hotspot {
		cursor: pointer;
		background: transparent;
	}

	.metric-bar-hotspot:focus-visible {
		outline: 2px solid var(--gray-900);
		outline-offset: -2px;
	}
</style>
