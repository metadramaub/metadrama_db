<script lang="ts">
	import type { PublicFichaSecuencia } from '$lib/types/public-ficha.types';

	interface PositionedSegment {
		secuencia: PublicFichaSecuencia;
		left: number;
		width: number;
		color: string;
	}

	const props = $props<{
		segments: PublicFichaSecuencia[];
		totalVerses: number;
		rangeStart?: number;
		rangeEnd?: number;
		jornadaMarkers?: number[];
		cuadroMarkers?: number[];
		colorByForma: Record<string, string>;
		onOpenSequence?: (secuenciaId: string) => void;
		trackHeight?: number;
	}>();

	const viewStart = $derived(props.rangeStart ?? 1);
	const viewEnd = $derived(props.rangeEnd ?? Math.max(props.totalVerses, viewStart));
	const viewLength = $derived(Math.max(1, viewEnd - viewStart + 1));
	const trackHeight = $derived(props.trackHeight ?? 30);

	const positionedSegments = $derived.by(() => {
		return props.segments
			.filter((segment: PublicFichaSecuencia) => segment.v_fin >= viewStart && segment.v_ini <= viewEnd)
			.map((segment: PublicFichaSecuencia) => {
				const boundedStart = Math.max(segment.v_ini, viewStart);
				const boundedEnd = Math.min(segment.v_fin, viewEnd);
				const boundedLength = Math.max(1, boundedEnd - boundedStart + 1);
				const left = ((boundedStart - viewStart) / viewLength) * 100;
				const width = (boundedLength / viewLength) * 100;
				const color = props.colorByForma[segment.estrofa_forma_term] ?? '#9ca3af';
				return {
					secuencia: segment,
					left: Math.max(0, left),
					width: Math.max(0.7, width),
					color
				} satisfies PositionedSegment;
			});
	});

	const jornadaMarkers = $derived.by(() => {
		return (props.jornadaMarkers ?? [])
			.filter((marker: number) => marker > viewStart && marker < viewEnd)
			.map((marker: number) => ((marker - viewStart + 1) / viewLength) * 100);
	});

	const cuadroMarkers = $derived.by(() => {
		return (props.cuadroMarkers ?? [])
			.filter((marker: number) => marker > viewStart && marker < viewEnd)
			.map((marker: number) => ((marker - viewStart + 1) / viewLength) * 100);
	});

	function openSequence(secuenciaId: string) {
		props.onOpenSequence?.(secuenciaId);
	}
</script>

<div class="w-full">
	<div
		class="relative z-20 w-full overflow-visible border border-[color:var(--border)] bg-[color:var(--gray-100)]"
		style={`height:${trackHeight}px;`}
	>
		{#each positionedSegments as item (item.secuencia.secuencia_id)}
			<div
				class="group absolute inset-y-0 z-20"
				style={`left:${item.left}%;width:${item.width}%;`}
			>
				<button
					type="button"
					class="block h-full w-full p-0 text-left focus:outline-none focus-visible:ring-1 focus-visible:ring-[color:var(--foreground)]"
					style={`background:${item.color};`}
					aria-label={`Secuencia ${item.secuencia.v_ini}-${item.secuencia.v_fin}, ${item.secuencia.estrofa_tipo_term}`}
					onclick={() => openSequence(item.secuencia.secuencia_id)}
				>
					<span class="sr-only">Abrir detalle de secuencia</span>
				</button>
				<div
					class="pointer-events-none absolute left-1/2 top-0 z-[90] hidden w-64 -translate-x-1/2 -translate-y-[110%] border border-[color:var(--border)] bg-white p-2 text-[11px] leading-tight shadow-sm group-hover:block group-focus-within:block"
				>
					<div class="font-semibold text-[color:var(--gray-900)]">{item.secuencia.estrofa_tipo_term}</div>
					<div class="mt-1 text-[color:var(--muted-foreground)]">
						Versos: {item.secuencia.v_ini}-{item.secuencia.v_fin}
					</div>
					<div class="mt-1 text-[color:var(--muted-foreground)]">
						Nº versos: {item.secuencia.n_versos}
					</div>
					<button
						type="button"
						class="pointer-events-auto mt-2 border border-[color:var(--border)] bg-white px-2 py-1 text-[11px] font-semibold tracking-[0.03em] text-[color:var(--gray-800)]"
						onclick={(event) => {
							event.stopPropagation();
							openSequence(item.secuencia.secuencia_id);
						}}
					>
						Ver más
					</button>
				</div>
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
