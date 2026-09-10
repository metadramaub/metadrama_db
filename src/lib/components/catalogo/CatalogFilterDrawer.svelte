<script lang="ts">
	// **Los filtros viven en un cajón, no en una columna.**
	//
	// La columna se quedaba arriba: bastaba con bajar unas obras para perderla de vista, y en móvil
	// obligaba a una maquetación aparte. Como cajón hay una sola pantalla para los dos tamaños, los
	// resultados ocupan todo el ancho y el botón dice cuántos filtros hay puestos aunque esté
	// cerrado. Fuera se quedan Buscar y los chips de lo aplicado, que es lo que hay que ver sin
	// abrir nada.
	//
	// **Se abre por la derecha, que es donde está su botón.** Un cajón que sale por el lado
	// contrario al que se ha pulsado obliga a buscar con la vista dónde ha aparecido.
	//
	// Se cierra con `Escape` y devuelve el foco a su botón, como el resto de ventanas de la ficha:
	// dos ventanas que se cierran distinto se sienten como dos aplicaciones.
	import { SlidersHorizontal, X } from 'lucide-svelte';

	const props = $props<{
		/** Cuántos filtros hay puestos; 0 no pinta insignia. */
		activeCount: number;
		children: import('svelte').Snippet;
	}>();

	let abierto = $state(false);
	let botonRef = $state<HTMLButtonElement | null>(null);
	let panelRef = $state<HTMLDivElement | null>(null);

	function abrir() {
		abierto = true;
	}

	function cerrar() {
		abierto = false;
		botonRef?.focus();
	}

	// El foco entra al cajón al abrirlo: si no, la primera tabulación sigue en la página de detrás.
	$effect(() => {
		if (abierto && panelRef) panelRef.focus();
	});

	function onKeydown(event: KeyboardEvent) {
		if (event.key === 'Escape' && abierto) {
			event.stopPropagation();
			cerrar();
		}
	}
</script>

<svelte:window on:keydown={onKeydown} />

<button
	type="button"
	bind:this={botonRef}
	onclick={abrir}
	class="inline-flex items-center gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)] hover:border-[color:var(--primary)] hover:text-[color:var(--primary)]"
	aria-expanded={abierto}
	aria-haspopup="dialog"
>
	<SlidersHorizontal size={14} aria-hidden="true" />
	<span>Filtros</span>
	{#if props.activeCount > 0}
		<span
			class="min-w-5 border border-[color:var(--primary)] bg-[color:var(--primary)] px-1.5 py-0.5 text-[11px] leading-none text-white"
			aria-label={`${props.activeCount} filtros activos`}
		>
			{props.activeCount}
		</span>
	{/if}
</button>

{#if abierto}
	<!--
		El fondo cierra al pulsarlo, pero no es el único camino: están la X y Escape. Por eso lleva
		`aria-hidden` y no rol de botón, para no anunciar dos veces lo mismo.
	-->
	<div
		class="fixed inset-0 z-40 bg-black/30"
		aria-hidden="true"
		onclick={cerrar}
	></div>

	<div
		bind:this={panelRef}
		role="dialog"
		aria-modal="true"
		aria-label="Filtros del buscador"
		tabindex="-1"
		class="fixed inset-y-0 right-0 z-50 flex w-full max-w-sm flex-col border-l border-[color:var(--border)] bg-white shadow-xl outline-none"
	>
		<div
			class="flex items-center justify-between gap-3 border-b border-[color:var(--border)] px-4 py-3"
		>
			<h2 class="font-display text-xl text-[color:var(--gray-900)]">Filtros</h2>
			<button
				type="button"
				onclick={cerrar}
				class="grid h-10 w-10 place-items-center border border-transparent text-[color:var(--gray-700)] hover:border-[color:var(--border)]"
				aria-label="Cerrar filtros"
			>
				<X size={18} aria-hidden="true" />
			</button>
		</div>

		<div class="min-h-0 flex-1 overflow-y-auto">
			{@render props.children()}
		</div>
	</div>
{/if}
