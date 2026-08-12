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
		<p class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
			{#if props.unitCount > 1}
				{props.unitCount} unidades ·
			{/if}
			{props.coverage.coveredVerses} de {props.coverage.declaredVerses} versos
		</p>
	</div>
	{#if props.coverage.state === 'complete'}
		<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
			La estructura cubre exactamente el rango declarado.
		</p>
	{:else if props.coverage.state === 'missing'}
		<p class="mt-1 text-xs">
			{missing === 1 ? 'Falta 1 verso' : `Faltan ${missing} versos`} por asignar a la estructura.
			Ajusta las unidades o revisa el verso final; el rango no cambiará automáticamente.
		</p>
	{:else}
		<p class="mt-1 text-xs">
			La estructura rebasa el rango en {overflow} {overflow === 1 ? 'verso' : 'versos'}.
			Ajusta las unidades o revisa el verso final; el rango no cambiará automáticamente.
		</p>
	{/if}
</div>
