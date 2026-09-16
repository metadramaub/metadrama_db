<script lang="ts">
	import Info from 'lucide-svelte/icons/info';
	import type { LaboratoryAxisScale } from '$lib/laboratorio/chart-scale';

	const props = $props<{ scale: LaboratoryAxisScale }>();

	const percentage = (value: number | null | undefined) =>
		value === null || value === undefined
			? '—'
			: `${(value * 100).toLocaleString('es', { maximumFractionDigits: 2 })} %`;
</script>

{#if props.scale.expandedPercentage}
	<p class="mt-2 flex items-start gap-1.5 text-xs leading-5 text-[color:var(--muted-foreground)]">
		<Info class="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden="true" />
		<span>
			<strong class="font-semibold text-[color:var(--foreground)]">Escala ampliada: 0–{percentage(props.scale.maximum)}.</strong>
			El máximo observado es {percentage(props.scale.maximumObserved)}; el porcentaje sigue referido al 100 % del denominador indicado.
		</span>
	</p>
{/if}
