<script lang="ts">
	import {
		ETIQUETAS_DETERMINACION,
		type DeterminacionMetrica
	} from '$lib/metrica/determinacion';

	const { valor }: { valor: DeterminacionMetrica } = $props();
</script>

<span class="block text-[0.6rem] leading-tight text-[color:var(--muted-foreground)]">
	<span class="font-medium">{ETIQUETAS_DETERMINACION[valor.grado]}</span>
	{#if valor.detalle}
		<span class="font-normal opacity-70">· {valor.detalle}</span>
	{/if}
</span>
