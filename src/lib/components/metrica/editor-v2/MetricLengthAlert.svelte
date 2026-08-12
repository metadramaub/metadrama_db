<script lang="ts">
	import type { MetricLengthRule } from '$lib/metrica/catalogo';
	import { metricLengthError } from '$lib/metrica/metric-length';

	const props = $props<{
		rule: MetricLengthRule | null;
		start: number;
		end: number;
		configurationName?: string;
		formName?: string;
	}>();

	const message = $derived(
		metricLengthError(
			props.rule,
			props.start,
			props.end,
			props.configurationName,
			props.formName
		)
	);
</script>

{#if message}
	<div
		class="border-l-4 border-amber-600 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-950"
		role="alert"
	>
		<p class="font-semibold">El número de versos no es compatible con esta forma</p>
		<p>{message}</p>
	</div>
{/if}
