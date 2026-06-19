<script lang="ts">
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import CatalogMetricBar from '$lib/components/catalogo/CatalogMetricBar.svelte';
	import type { CatalogStructureTramo, CatalogTramo } from '$lib/catalogo/catalog-filters';

	type Obra = {
		obra_id: string;
		slug: string;
		titulo: string;
		autoria_autores: string[];
		genero_term: string | null;
		fecha_inicio_trad: number | null;
		fecha_fin_trad: number | null;
		total_versos: number | null;
		visible_publico: boolean | null;
		es_obra_asignada: boolean;
		tramos?: CatalogTramo[] | null;
		jornadas_tramos?: CatalogStructureTramo[] | null;
		cuadros_tramos?: CatalogStructureTramo[] | null;
		numero_efectivo_formas?: number | null;
		densidad_transiciones?: number | null;
		n_formas_distintas?: number | null;
	};

	const props = $props<{
		obra: Obra;
		canSeeAllPublished: boolean;
		showPerfilMetrico?: boolean;
	}>();

	const tramos = $derived(props.obra.tramos ?? []);
	const jornadasTramos = $derived(props.obra.jornadas_tramos ?? []);
	const cuadrosTramos = $derived(props.obra.cuadros_tramos ?? []);
	const showPerfil = $derived(Boolean(props.showPerfilMetrico) && tramos.length > 0);

	function formatNumber(value: number | null | undefined, decimals = 1): string | null {
		if (value === null || value === undefined) return null;
		return value.toFixed(decimals);
	}

	const diversidadLabel = $derived(formatNumber(props.obra.numero_efectivo_formas));
	const densidadLabel = $derived(formatNumber(props.obra.densidad_transiciones));

	function datacionLabel(obra: Obra): string {
		const ini = obra.fecha_inicio_trad;
		const fin = obra.fecha_fin_trad;
		if (ini === null && fin === null) return 'Sin datación';
		if (ini === fin || fin === null) return String(ini);
		if (ini === null) return String(fin);
		return `${ini}-${fin}`;
	}
</script>

<article class="group border border-[color:var(--border)] bg-white p-4 transition-colors hover:border-[color:var(--gray-400)]">
	<div class="grid gap-3 md:grid-cols-[minmax(0,1fr)_auto] md:items-start">
		<div class="min-w-0">
			<div class="flex flex-wrap items-center gap-2">
				<h2 class="font-display text-xl leading-tight text-[color:var(--gray-900)]">
					<a class="underline-offset-3 hover:underline" href={`/obras/${props.obra.slug}`}>
						{props.obra.titulo}
					</a>
				</h2>
				{#if !props.obra.visible_publico}
					{#if props.obra.es_obra_asignada}
						<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-[11px] text-[color:var(--muted-foreground)]">
							Tu ficha
						</span>
					{:else if props.canSeeAllPublished}
						<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-[11px] text-[color:var(--muted-foreground)]">
							Editorial
						</span>
					{/if}
				{/if}
			</div>

			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				{props.obra.autoria_autores.length > 0
					? props.obra.autoria_autores.join(', ')
					: 'Autoría no indicada'}
			</p>
		</div>

		<a
			href={`/obras/${props.obra.slug}`}
			class="inline-flex h-9 w-9 items-center justify-center border border-[color:var(--border)] text-[color:var(--gray-700)] transition-colors group-hover:border-[color:var(--primary)] group-hover:text-[color:var(--primary)]"
			aria-label={`Abrir ficha de ${props.obra.titulo}`}
		>
			<ArrowRight size={16} aria-hidden="true" />
		</a>
	</div>

	<div class="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
		<span>Datación: {datacionLabel(props.obra)}</span>
		{#if props.obra.genero_term}
			<span>Género: {props.obra.genero_term}</span>
		{/if}
		{#if props.obra.total_versos !== null}
			<span>{props.obra.total_versos} vv.</span>
		{/if}
	</div>

	{#if showPerfil}
		<div class="mt-3 space-y-1.5">
			<CatalogMetricBar
				tramos={tramos}
				jornadas={jornadasTramos}
				cuadros={cuadrosTramos}
				totalVersos={props.obra.total_versos}
			/>
			<div class="flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-[color:var(--muted-foreground)]">
				{#if diversidadLabel}
					<span title="Número efectivo de formas (diversidad métrica)">
						Diversidad: <span class="font-semibold text-[color:var(--gray-700)]">{diversidadLabel}</span>
					</span>
				{/if}
				{#if densidadLabel}
					<span title="Cambios de estrofa por cada 100 versos">
						Densidad: <span class="font-semibold text-[color:var(--gray-700)]">{densidadLabel}</span>
					</span>
				{/if}
				{#if props.obra.n_formas_distintas !== null && props.obra.n_formas_distintas !== undefined}
					<span>{props.obra.n_formas_distintas} formas</span>
				{/if}
			</div>
		</div>
	{/if}
</article>
