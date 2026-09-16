<script lang="ts">
	import ZoomIn from 'lucide-svelte/icons/zoom-in';
	import type { LaboratoryAxisScale } from '$lib/laboratorio/chart-scale';

	const props = $props<{ scale: LaboratoryAxisScale }>();

	const percentage = (value: number | null | undefined) =>
		value === null || value === undefined
			? '—'
			: `${(value * 100).toLocaleString('es', { maximumFractionDigits: 2 })} %`;
</script>

{#if props.scale.expandedPercentage}
	<p class="mt-2 flex items-start gap-1.5 text-xs leading-5 text-[color:var(--muted-foreground)]">
		<ZoomIn class="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden="true" />
		<span>
			<strong class="font-semibold text-[color:var(--foreground)]">Eje ampliado hasta {percentage(props.scale.maximum)}</strong>
			para hacer legibles valores pequeños; máximo observado: {percentage(props.scale.maximumObserved)}.
		</span>
	</p>
{/if}
