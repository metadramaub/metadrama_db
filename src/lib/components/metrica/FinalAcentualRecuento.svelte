<script lang="ts">
	import { etiquetaFinal, finalesPredominantes, type RecuentoFinalAcentual } from '$lib/metrica/final-acentual';

	const { recuento }: { recuento: RecuentoFinalAcentual } = $props();
</script>

{#if finalesPredominantes.some((final) => (recuento[final] ?? 0) > 0)}
	<dl class="mt-5 space-y-1 border-l-2 border-[color:var(--border)] pl-3 text-sm">
		{#each finalesPredominantes as final (final)}
			{@const cantidad = recuento[final] ?? 0}
			{#if cantidad > 0}
				<div class="flex flex-wrap items-baseline gap-x-2">
					<dt class="font-medium">{etiquetaFinal[final]}</dt>
					<dd class="text-[color:var(--muted-foreground)]">{cantidad} {cantidad === 1 ? 'secuencia documentada' : 'secuencias documentadas'}</dd>
				</div>
			{/if}
		{/each}
	</dl>
{/if}
