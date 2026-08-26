<script lang="ts">
	import type { MetricLengthRule } from '$lib/metrica/catalogo';
	import { metricLengthError } from '$lib/metrica/metric-length';

	const props = $props<{
		rule: MetricLengthRule | null;
		start: number;
		end: number;
		configurationName?: string;
		formName?: string;
		/**
		 * Si alguna unidad declara una arquitectura propia. Entonces la regla de longitud calla:
		 * una tirada de décimas con una aumentada mide `10n + 2`, y exigirle múltiplos de diez
		 * sería avisar de lo que la norma admite. Quien comprueba el pasaje es la cobertura.
		 */
		conArquitecturasPropias?: boolean;
	}>();

	const message = $derived(
		metricLengthError(
			props.rule,
			props.start,
			props.end,
			props.configurationName,
			props.formName,
			props.conArquitecturasPropias ?? false
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
