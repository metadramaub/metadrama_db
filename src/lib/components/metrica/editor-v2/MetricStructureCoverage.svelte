<script lang="ts">
	import type { MetricStructureCoverage } from './structure-coverage';

	const props = $props<{
		coverage: MetricStructureCoverage;
		unitCount: number;
	}>();

	const missing = $derived(Math.abs(Math.min(0, props.coverage.difference)));
	const overflow = $derived(Math.max(0, props.coverage.difference));
</script>

<div
	class={`border px-3 py-2.5 text-sm ${
		props.coverage.state === 'complete'
			? 'border-[color:var(--border)] bg-[color:var(--gray-50)]'
			: 'border-amber-300 bg-amber-50 text-amber-950'
	}`}
>
	<div class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
		<p class="font-medium">Cobertura del rango</p>
		<!--
			**Los dos números van con su nombre.** Decían «39 de 2 versos», que se lee como «39 de un
			total de 2» y chirría en cuanto la estructura pasa del rango, que es justo cuando hay que
			leerlo. No era un número al revés: la estructura cubría 39 y el rango declaraba 2.

			Cuando cuadran, uno solo basta y sobra el resto.
		-->
		<p class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
			{#if props.unitCount > 1}
				{props.unitCount} unidades ·
			{/if}
			{#if props.coverage.state === 'complete'}
				{props.coverage.coveredVerses}
				{props.coverage.coveredVerses === 1 ? 'verso' : 'versos'}
			{:else}
				estructura {props.coverage.coveredVerses} · rango {props.coverage.declaredVerses}
			{/if}
		</p>
	</div>
	{#if props.coverage.state === 'complete'}
		<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
			La estructura cubre exactamente el rango declarado.
		</p>
	{:else if props.coverage.state === 'missing'}
		<!--
			Y la explicación repite los dos números en una frase, porque es donde se entiende de qué
			habla cada uno.
		-->
		<p class="mt-1 text-xs">
			La estructura ocupa {props.coverage.coveredVerses}
			{props.coverage.coveredVerses === 1 ? 'verso' : 'versos'} y el rango declara
			{props.coverage.declaredVerses}: {missing === 1 ? 'falta 1 verso' : `faltan ${missing} versos`}
			por asignar. Ajusta las unidades o revisa el verso final; el rango no cambiará
			automáticamente.
		</p>
	{:else}
		<p class="mt-1 text-xs">
			La estructura ocupa {props.coverage.coveredVerses}
			{props.coverage.coveredVerses === 1 ? 'verso' : 'versos'} y el rango declara
			{props.coverage.declaredVerses}: {overflow === 1 ? 'sobra 1' : `sobran ${overflow}`}. Ajusta
			las unidades o revisa el verso final; el rango no cambiará automáticamente.
		</p>
	{/if}
</div>
