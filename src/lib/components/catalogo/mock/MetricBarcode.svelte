<script lang="ts">
	import {
		MOCK_METRIC_PALETTE_BY_ID,
		type MockCatalogWork,
		type MockMetricSegment
	} from '$lib/mock/catalogo-mock';

	interface PositionedSegment {
		segment: MockMetricSegment;
		left: number;
		width: number;
		color: string;
	}

	const props = $props<{ work: MockCatalogWork; height?: number }>();

	const totalVerses = $derived(Math.max(props.work.totalVerses, 1));
	const trackHeight = $derived(props.height ?? 28);

	const positionedSegments = $derived.by(() => {
		return props.work.segments.map((segment: MockMetricSegment) => {
			const left = ((segment.startVerse - 1) / totalVerses) * 100;
			const width = ((segment.endVerse - segment.startVerse + 1) / totalVerses) * 100;
			const palette = MOCK_METRIC_PALETTE_BY_ID[segment.formId];

			return {
				segment,
				left: Math.max(0, left),
				width: Math.max(0.6, width),
				color: palette?.color ?? '#9ca3af'
			} satisfies PositionedSegment;
		});
	});

	const jornadaMarkers = $derived.by(() => {
		return props.work.jornadaBreaks
			.filter((marker: number) => marker > 0 && marker < totalVerses)
			.map((marker: number) => (marker / totalVerses) * 100);
	});

	const cuadroMarkers = $derived.by(() => {
		return props.work.cuadroBreaks
			.filter((marker: number) => marker > 0 && marker < totalVerses)
			.map((marker: number) => (marker / totalVerses) * 100);
	});

	function variationLabel(segment: MockMetricSegment): string {
		if (segment.variationTags.length === 0) return 'Sin variaciones registradas';
		return segment.variationTags.join(', ');
	}

	function verseCount(segment: MockMetricSegment): number {
		return segment.endVerse - segment.startVerse + 1;
	}
</script>

<div class="w-full">
	<div
		class="relative z-50 w-full overflow-visible border border-[color:var(--border)] bg-[color:var(--gray-100)]"
		style={`height:${trackHeight}px;`}
	>
		{#each positionedSegments as item (item.segment.id)}
			<button
				type="button"
				class="group absolute inset-y-0 z-20 block p-0 text-left focus:outline-none focus-visible:ring-1 focus-visible:ring-[color:var(--foreground)]"
				style={`left:${item.left}%;width:${item.width}%;`}
				aria-label={`${item.segment.formLabel}, versos ${item.segment.startVerse}-${item.segment.endVerse}`}
			>
				<span class="block h-full border-r border-white/40" style={`background:${item.color};`}></span>
				<span
					class="pointer-events-none absolute left-1/2 top-0 z-[90] hidden w-64 -translate-x-1/2 -translate-y-[110%] border border-[color:var(--border)] bg-white p-2 text-[11px] leading-tight shadow-sm group-hover:block group-focus-visible:block"
				>
					<span class="block font-semibold text-[color:var(--gray-900)]">{item.segment.formLabel}</span>
					<span class="mt-1 block text-[color:var(--muted-foreground)]">
						Número de versos: {verseCount(item.segment)}
					</span>
					<span class="mt-1 block text-[color:var(--muted-foreground)]">
						Variaciones: {variationLabel(item.segment)}
					</span>
				</span>
			</button>
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
