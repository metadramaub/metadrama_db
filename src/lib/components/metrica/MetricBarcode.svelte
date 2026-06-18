<script lang="ts">
	// Código de barras métrico REUTILIZABLE (ficha, catálogo, autor).
	// Consume MetricBarSegment genérico, no PublicFichaSecuencia.
	import type { MetricBarSegment } from './metric-display.types';

	interface PositionedSegment {
		segment: MetricBarSegment;
		left: number;
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

	const viewStart = $derived(props.rangeStart ?? 1);
	const viewEnd = $derived(props.rangeEnd ?? Math.max(props.totalVerses, viewStart));
	const viewLength = $derived(Math.max(1, viewEnd - viewStart + 1));
	const trackHeight = $derived(props.trackHeight ?? 30);
	const interactive = $derived(typeof props.onOpenSegment === 'function');

	function positionOf(vIni: number, vFin: number) {
		const boundedStart = Math.max(vIni, viewStart);
		const boundedEnd = Math.min(vFin, viewEnd);
		const boundedLength = Math.max(1, boundedEnd - boundedStart + 1);
		return {
			left: Math.max(0, ((boundedStart - viewStart) / viewLength) * 100),
			width: Math.max(0.7, (boundedLength / viewLength) * 100)
		};
	}

	const positionedSegments = $derived.by(() => {
		return props.segments
			.filter((s: MetricBarSegment) => s.v_fin >= viewStart && s.v_ini <= viewEnd)
			.map((segment: MetricBarSegment) => {
				const { left, width } = positionOf(segment.v_ini, segment.v_fin);
				const color = props.colorByForma[segment.forma] ?? '#9ca3af';
				return { segment, left, width, color } satisfies PositionedSegment;
			});
	});

	const jornadaMarkers = $derived.by(() =>
		(props.jornadaMarkers ?? [])
			.filter((m: number) => m > viewStart && m < viewEnd)
			.map((m: number) => ((m - viewStart + 1) / viewLength) * 100)
	);
	const cuadroMarkers = $derived.by(() =>
		(props.cuadroMarkers ?? [])
			.filter((m: number) => m > viewStart && m < viewEnd)
			.map((m: number) => ((m - viewStart + 1) / viewLength) * 100)
	);

	function open(id: string) {
		props.onOpenSegment?.(id);
	}

	// Posición de un sub-segmento RELATIVA al segmento padre (0-100% del padre).
	function subsegmentStyle(parent: MetricBarSegment, sub: { v_ini: number; v_fin: number }) {
		const parentLen = Math.max(1, parent.v_fin - parent.v_ini + 1);
		const left = ((Math.max(sub.v_ini, parent.v_ini) - parent.v_ini) / parentLen) * 100;
		const len = Math.max(1, Math.min(sub.v_fin, parent.v_fin) - Math.max(sub.v_ini, parent.v_ini) + 1);
		const width = (len / parentLen) * 100;
		return `left:${Math.max(0, left)}%;width:${Math.max(0.5, width)}%;`;
	}
</script>

<div class="w-full">
	<div
		class="relative z-20 w-full overflow-visible border border-[color:var(--border)] bg-[color:var(--gray-100)]"
		style={`height:${trackHeight}px;`}
	>
		{#each positionedSegments as item (item.segment.id)}
			<div class="group absolute inset-y-0 z-20" style={`left:${item.left}%;width:${item.width}%;`}>
				{#if interactive}
					<button
						type="button"
						class="block h-full w-full p-0 text-left focus:outline-none focus-visible:ring-1 focus-visible:ring-[color:var(--foreground)]"
						style={`background:${item.color};`}
						aria-label={`Versos ${item.segment.v_ini}-${item.segment.v_fin}, ${item.segment.label}`}
						onclick={() => open(item.segment.id)}
					>
						<span class="sr-only">Abrir detalle</span>
					</button>
				{:else}
					<div class="h-full w-full" style={`background:${item.color};`} aria-hidden="true"></div>
				{/if}

				{#if props.showSubsegments && item.segment.subsegments && item.segment.subsegments.length > 0}
					{#each item.segment.subsegments as sub (sub.id)}
						<span
							class="pointer-events-none absolute inset-y-0 border-l border-white/60"
							style={subsegmentStyle(item.segment, sub)}
						></span>
					{/each}
				{/if}

				{#if interactive}
					<div
						class="pointer-events-none absolute left-1/2 top-0 z-[90] hidden w-64 -translate-x-1/2 -translate-y-[110%] border border-[color:var(--border)] bg-white p-2 text-[11px] leading-tight shadow-sm group-hover:block group-focus-within:block"
					>
						<div class="font-semibold text-[color:var(--gray-900)]">{item.segment.label}</div>
						<div class="mt-1 text-[color:var(--muted-foreground)]">
							Versos: {item.segment.v_ini}-{item.segment.v_fin}
						</div>
						{#if item.segment.n_versos !== undefined}
							<div class="mt-1 text-[color:var(--muted-foreground)]">Nº versos: {item.segment.n_versos}</div>
						{/if}
						{#if item.segment.subsegments && item.segment.subsegments.length > 0}
							<div class="mt-1 text-[color:var(--muted-foreground)]">
								{item.segment.subsegments.length} subtipo{item.segment.subsegments.length === 1 ? '' : 's'}
							</div>
						{/if}
						<button
							type="button"
							class="pointer-events-auto mt-2 border border-[color:var(--border)] bg-white px-2 py-1 text-[11px] font-semibold tracking-[0.03em] text-[color:var(--gray-800)]"
							onclick={(event) => {
								event.stopPropagation();
								open(item.segment.id);
							}}
						>
							Ver más
						</button>
					</div>
				{/if}
			</div>
		{/each}

		{#each cuadroMarkers as marker, index (`cuadro-${index}`)}
			<span
				class="pointer-events-none absolute inset-y-0 z-40 border-l border-dashed border-[color:var(--gray-500)]"
				style={`left:${marker}%;`}
			></span>
		{/each}

		{#each jornadaMarkers as marker, index (`jornada-${index}`)}
			<span
				class="pointer-events-none absolute inset-y-0 z-50 w-[2px] bg-[color:var(--gray-900)]"
				style={`left:calc(${marker}% - 1px);`}
			></span>
		{/each}
	</div>
</div>
