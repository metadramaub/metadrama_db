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
		/** Slug de forma → etiqueta visible (vocabulario). Si falta, se prettifica el slug. */
		formaLabels?: Record<string, string>;
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

	/** Lo que se dice de un tramo cuya secuencia todavía no declara forma. */
	const SIN_FORMA = 'Sin forma anotada';

	function prettyForma(slug: string): string {
		return slug.replace(/[_-]+/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
	}
	function formaLabel(slug: string | null): string {
		if (!slug) return SIN_FORMA;
		return props.formaLabels?.[slug] ?? prettyForma(slug);
	}

	const segments = $derived.by(() =>
		props.tramos.map(
			(tramo: CatalogTramo): MetricBarSegment => ({
				id: `${tramo.i}-${tramo.f}-${tramo.s}`,
				v_ini: tramo.i,
				v_fin: tramo.f,
				forma: formaLabel(tramo.s),
				colorKey: tramo.s ?? SIN_FORMA,
				label: formaLabel(tramo.s),
				n_versos: tramo.f - tramo.i + 1
			})
		)
	);

	const colorByForma = $derived.by(() => {
		const map: Record<string, string> = {};
		for (const tramo of props.tramos) {
			const clave = tramo.s ?? SIN_FORMA;
			if (!map[clave]) map[clave] = colorForForma({ slug: tramo.s ?? '', tipoForma: tramo.t });
		}
		return map;
	});

	/**
	 * Los cortes dicen **lo que empieza** en ellos —«Jornada 2 · desde el v. 936»—, como en la ficha:
	 * la barra añade el verso. Un cuadro que acaba donde acaba la jornada no lleva corte propio.
	 */
	/** Los cortes entre tramos consecutivos, nombrados por el tramo que abren. */
	function cortesEntre(tramos: CatalogStructureTramo[] | null | undefined, nombre: string) {
		const ordenados = [...(tramos ?? [])].sort((a, b) => a.i - b.i);
		return ordenados.slice(0, -1).map((tramo, indice) => ({
			verse: tramo.f,
			title: `${nombre} ${ordenados[indice + 1].n}`
		}));
	}
	const jornadaMarkers = $derived(cortesEntre(props.jornadas, 'Jornada'));
	const cuadroMarkers = $derived(
		cortesEntre(props.cuadros, 'Cuadro').filter(
			(corte) => !jornadaMarkers.some((jornada) => jornada.verse === corte.verse)
		)
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
