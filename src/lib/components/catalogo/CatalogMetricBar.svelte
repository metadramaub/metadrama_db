<script lang="ts">
	import MetricBarcode from '$lib/components/metrica/MetricBarcode.svelte';
	import type { MetricBarSegment } from '$lib/components/metrica/metric-display.types';
	import type { CatalogStructureTramo, CatalogTramo } from '$lib/catalogo/catalog-filters';
	import { colorForForma } from '$lib/utils/metric-colors';

	const props = $props<{
		tramos: CatalogTramo[];
		totalVersos: number | null;
		jornadas?: CatalogStructureTramo[] | null;
		cuadros?: CatalogStructureTramo[] | null;
		height?: number;
	}>();

	const total = $derived(
		Math.max(
			1,
			props.totalVersos ?? 0,
			...props.tramos.map((tramo: CatalogTramo) => tramo.f),
			...(props.jornadas ?? []).map((tramo: CatalogStructureTramo) => tramo.f),
			...(props.cuadros ?? []).map((tramo: CatalogStructureTramo) => tramo.f)
		)
	);
	const trackHeight = $derived(props.height ?? 14);

	function prettyForma(slug: string): string {
		return slug.replace(/[_-]+/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
	}

	const segments = $derived.by(() =>
		props.tramos.map(
			(tramo: CatalogTramo): MetricBarSegment => ({
				id: `${tramo.i}-${tramo.f}-${tramo.s}`,
				v_ini: tramo.i,
				v_fin: tramo.f,
				forma: prettyForma(tramo.s),
				colorKey: tramo.s,
				label: prettyForma(tramo.s),
				n_versos: tramo.f - tramo.i + 1
			})
		)
	);

	const colorByForma = $derived.by(() => {
		const map: Record<string, string> = {};
		for (const tramo of props.tramos) {
			if (!map[tramo.s]) map[tramo.s] = colorForForma({ slug: tramo.s, tipoForma: tramo.t });
		}
		return map;
	});

	const jornadaMarkers = $derived(
		(props.jornadas ?? []).map((tramo: CatalogStructureTramo) => ({
			verse: tramo.f,
			title: `Jornada ${tramo.n} · vv. ${tramo.i}-${tramo.f}`
		}))
	);
	const cuadroMarkers = $derived(
		(props.cuadros ?? []).map((tramo: CatalogStructureTramo) => ({
			verse: tramo.f,
			title: `Cuadro ${tramo.n} · vv. ${tramo.i}-${tramo.f}`
		}))
	);
</script>

<MetricBarcode
	segments={segments}
	totalVerses={total}
	{jornadaMarkers}
	{cuadroMarkers}
	colorByForma={colorByForma}
	trackHeight={trackHeight}
	showNativeTitles
	compactMarkers
/>
