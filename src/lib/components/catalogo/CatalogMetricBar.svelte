<script lang="ts">
	import type { CatalogTramo } from '$lib/catalogo/catalog-filters';
	import { colorForForma } from '$lib/utils/metric-colors';

	const props = $props<{
		tramos: CatalogTramo[];
		totalVersos: number | null;
		height?: number;
	}>();

	const total = $derived(
		Math.max(
			1,
			props.totalVersos ?? 0,
			...props.tramos.map((tramo: CatalogTramo) => tramo.f)
		)
	);
	const trackHeight = $derived(props.height ?? 14);

	function prettyForma(slug: string): string {
		return slug.replace(/[_-]+/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
	}

	const positioned = $derived.by(() =>
		props.tramos.map((tramo: CatalogTramo) => ({
			tramo,
			left: Math.max(0, ((tramo.i - 1) / total) * 100),
			width: Math.max(0.4, ((tramo.f - tramo.i + 1) / total) * 100),
			color: colorForForma({ slug: tramo.s, tipoForma: tramo.t })
		}))
	);
</script>

<div
	class="relative w-full overflow-hidden border border-[color:var(--border)] bg-[color:var(--gray-100)]"
	style={`height:${trackHeight}px;`}
	role="img"
	aria-label="Perfil métrico de la obra"
>
	{#each positioned as item (item.tramo.i)}
		<span
			class="group absolute inset-y-0 block"
			style={`left:${item.left}%;width:${item.width}%;background:${item.color};`}
			title={`${prettyForma(item.tramo.s)} · vv. ${item.tramo.i}-${item.tramo.f}`}
		></span>
	{/each}
</div>
