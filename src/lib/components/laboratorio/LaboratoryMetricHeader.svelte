<script lang="ts">
	import LaboratoryReadingKey from '$lib/components/laboratorio/LaboratoryReadingKey.svelte';
	import { getLaboratoryMetricHelp, type LaboratoryMetric } from '$lib/laboratorio/metricas';

	const props = $props<{
		metric: LaboratoryMetric;
		titleId: string;
	}>();

	const help = $derived(getLaboratoryMetricHelp(props.metric));
</script>

<header class="border-b border-[color:var(--border)] px-5 py-4">
	<p class="text-[10px] font-semibold uppercase tracking-[0.14em] text-[color:var(--primary)]">{props.metric.group}</p>
	<h2 id={props.titleId} class="mt-1 text-xl font-semibold">{props.metric.label}</h2>
	<p class="mt-1 max-w-2xl text-sm leading-6 text-[color:var(--muted-foreground)]">{props.metric.description}</p>
	<LaboratoryReadingKey
		items={[
			{ label: 'Unidad', value: help.unitLabel },
			{ label: 'Base de cálculo', value: props.metric.denominator }
		]}
		note={help.explanation}
		caution={props.metric.caution}
	/>
</header>
