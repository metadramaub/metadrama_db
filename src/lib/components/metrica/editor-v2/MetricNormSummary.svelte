<script lang="ts">
	import type { MetricNormFact } from './norm-summary';
	import type { Rejilla } from '$lib/metrica/rejilla';
	import MetricPositionGrid from '$lib/components/metrica/MetricPositionGrid.svelte';

	const props = $props<{
		facts: MetricNormFact[];
		catalogHref: string;
		/** La arquitectura dibujada, cuando la norma fija posiciones que enseñar. */
		rejilla?: Rejilla | null;
	}>();
</script>

<div class="border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2.5 text-sm">
	<div class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
		<span class="font-medium">Norma de la arquitectura</span>
		<a
			class="link-action text-xs"
			href={props.catalogHref}
			target="_blank"
			rel="noreferrer"
		>
			Ver ficha completa ↗
		</a>
	</div>
	<!-- La estructura antes de la lista: quien anota está reconociéndola en el texto, y una
	     figura se compara con lo que tiene delante mejor que una frase. -->
	{#if props.rejilla}
		<div class="mt-2">
			<MetricPositionGrid rejilla={props.rejilla} />
		</div>
	{/if}
	{#if props.facts.length > 0}
		<dl class="mt-2 grid gap-x-5 gap-y-1.5 sm:grid-cols-[max-content_minmax(0,1fr)]">
			{#each props.facts as fact (`${fact.label}:${fact.value}`)}
				<dt class="text-[color:var(--muted-foreground)]">{fact.label}</dt>
				<dd>{fact.value}</dd>
			{/each}
		</dl>
	{:else}
		<p class="mt-1 text-[color:var(--muted-foreground)]">
			La arquitectura no fija aquí más datos que los que se responden abajo.
		</p>
	{/if}
</div>
