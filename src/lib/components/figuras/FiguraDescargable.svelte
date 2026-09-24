<script lang="ts">
	// Un gráfico de la zona pública que se puede descargar.
	//
	// Envuelve lo que se ve en pantalla y pone al lado **un icono, sin palabra**, que se aviva al
	// pasar por encima. Descargar es lo secundario de un gráfico que se está leyendo; el botón
	// anterior, con «Descargar PNG» escrito debajo de cada uno, pesaba casi tanto como el título.
	//
	// El icono va en su propia columna y no flotando sobre el gráfico: flotando tapaba el primer
	// porcentaje de las franjas o el final del código de barras, según el caso.
	//
	// Lo que se descarga no es lo que se ve, sino `grafico(opciones)`: el mismo componente en modo
	// figura, sin interacción, con su sello y en la paleta elegida. Se pinta solo al abrir el modal.
	import type { Snippet } from 'svelte';
	import { Download } from 'lucide-svelte';
	import ModalFigura from './ModalFigura.svelte';
	import type { FiguraDescargable, OpcionesFigura, ProcedenciaFigura } from '$lib/figuras/tipos';

	const props = $props<{
		figura: FiguraDescargable;
		procedencia: ProcedenciaFigura;
		children: Snippet;
		grafico: Snippet<[OpcionesFigura]>;
	}>();

	let abierta = $state(false);
</script>

<div class="figura grid grid-cols-[minmax(0,1fr)_auto] items-start gap-2">
	<div class="min-w-0">
		{@render props.children()}
	</div>
	<button
		type="button"
		class="figura__boton inline-flex h-7 w-7 items-center justify-center border border-transparent text-[color:var(--gray-500)] hover:border-[color:var(--border)] hover:bg-white hover:text-[color:var(--gray-900)] focus-visible:border-[color:var(--gray-800)] focus-visible:text-[color:var(--gray-900)] focus-visible:outline-none"
		aria-label={`Descargar el gráfico «${props.figura.titulo}»`}
		title="Descargar el gráfico"
		onclick={() => (abierta = true)}
	>
		<Download class="h-4 w-4" aria-hidden="true" />
	</button>
</div>

{#if abierta}
	<ModalFigura
		figura={props.figura}
		procedencia={props.procedencia}
		grafico={props.grafico}
		onClose={() => (abierta = false)}
	/>
{/if}

<style>
	/* Donde hay ratón, casi invisible hasta que se pasa por el gráfico. En una pantalla táctil no
	   hay «pasar por encima», y se queda como está: tenue pero a la vista. */
	@media (hover: hover) {
		.figura__boton {
			opacity: 0.35;
			transition: opacity 120ms ease;
		}

		.figura:hover .figura__boton,
		.figura__boton:focus-visible {
			opacity: 1;
		}
	}
</style>
