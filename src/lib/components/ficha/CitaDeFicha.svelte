<script lang="ts">
	// Cómo citar la ficha, a la vista en su cabecera.
	//
	// **Se lee sin pulsar nada y se copia con un clic.** Antes era un botón negro junto al título
	// que copiaba una cita que no se veía: pesaba más que el propio título y había que pegarla para
	// saber qué decía. Ahora va en el bloque «La ficha», en pequeño y gris como el resto del bloque —es
	// el párrafo más largo de la cabecera y no puede pesar más que la obra—, y el
	// aviso de copiado es un toast, para que el botón no cambie de tamaño al pulsarlo.
	//
	// La cita es la de «Cómo citar un análisis específico», la misma que lleva cada gráfico.
	import { onMount } from 'svelte';
	import { Copy } from 'lucide-svelte';
	import { anioDeFicha, citaDelAnalisis, textoDe } from '$lib/figuras/cita';
	import { copiarAlPortapapeles } from '$lib/utils/portapapeles';

	const props = $props<{
		titulo: string;
		autorFicha: string | null;
		updatedAt: string | null;
		obraSlug: string;
	}>();

	// Se pone al montar: es la fecha del ordenador de quien lee, que el servidor no conoce.
	let consulta = $state<Date | undefined>(undefined);
	onMount(() => {
		consulta = new Date();
	});

	const cita = $derived(
		citaDelAnalisis(
			{
				obraTitulo: props.titulo,
				obraSlug: props.obraSlug,
				autorFicha: props.autorFicha,
				anio: anioDeFicha(props.updatedAt)
			},
			consulta
		)
	);
</script>

<div class="mt-3">
	<div class="mb-0.5 flex items-center justify-between gap-3">
		<span class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
			Cómo citar esta ficha
		</span>
		<button
			type="button"
			class="inline-flex shrink-0 items-center gap-1.5 border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold text-[color:var(--gray-800)] hover:bg-[color:var(--gray-50)]"
			onclick={() => copiarAlPortapapeles(textoDe(cita))}
		>
			<Copy class="h-3.5 w-3.5" aria-hidden="true" />
			Copiar
		</button>
	</div>
	<p class="text-xs leading-5 text-[color:var(--gray-600)]">
		{#each cita as tramo, indice (indice)}
			{#if tramo.cursiva}<em>{tramo.texto}</em>{:else}{tramo.texto}{/if}
		{/each}
	</p>
</div>
