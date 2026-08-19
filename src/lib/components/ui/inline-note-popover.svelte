<script lang="ts">
	import Info from 'lucide-svelte/icons/info';
	import { tick, type Snippet } from 'svelte';
	import { renderInlineMarkdown } from '$lib/utils/markdown';

	/**
	 * El disparador por defecto es el icono de información, que sirve para una nota colgada de
	 * una línea de texto. Pero a veces **lo anotado es un elemento que ya está en pantalla** —una
	 * celda de la rejilla—, y entonces el icono al lado no cabe y separa la nota de su sitio: se
	 * pasa `disparador` y es ese elemento el que abre. La colocación de la burbuja, que es lo
	 * delicado, se reutiliza igual en los dos casos.
	 */
	const {
		text,
		label = 'Mostrar nota',
		disparador,
		claseRaiz = '',
		estiloRaiz = '',
		claseBoton = ''
	}: {
		text: string;
		label?: string;
		disparador?: Snippet;
		claseRaiz?: string;
		estiloRaiz?: string;
		claseBoton?: string;
	} = $props();

	let root = $state<HTMLSpanElement | null>(null);
	let bubble = $state<HTMLSpanElement | null>(null);
	let abierto = $state(false);
	let lado = $state<'arriba' | 'abajo'>('arriba');
	let izquierda = $state(0);
	let arriba = $state(0);
	/** Tope de altura cuando la nota no cabe entera en el hueco elegido. */
	let maxAlto = $state<number | null>(null);

	const margen = 8;
	const separacion = 6;

	/**
	 * Coloca la burbuja donde más sitio hay.
	 *
	 * Antes prefería siempre arriba y solo bajaba si no cabía, de modo que una nota larga en la
	 * mitad superior de la pantalla se quedaba arriba a la fuerza y se recortaba contra el borde.
	 * Ahora se mide el hueco por los dos lados y gana el mayor cuando en ninguno cabe entera; la
	 * burbuja se limita entonces a ese hueco y su texto se desplaza dentro.
	 */
	function colocar() {
		if (!root || !bubble) return;
		const disparador = root.getBoundingClientRect();

		// Se mide con el tope de altura levantado: si no, la medición devuelve el tope anterior
		// y la burbuja se va encogiendo a cada recolocación.
		maxAlto = null;
		const ancho = bubble.offsetWidth;
		const alto = bubble.scrollHeight;

		// Se abre **hacia la derecha** del icono, que es el sentido de lectura, y solo se vuelca
		// hacia la izquierda cuando por la derecha no cabe.
		const haciaLaDerecha = disparador.left;
		const haciaLaIzquierda = disparador.right - ancho;
		const cabeALaDerecha = haciaLaDerecha + ancho <= window.innerWidth - margen;
		izquierda = Math.min(
			Math.max(cabeALaDerecha ? haciaLaDerecha : haciaLaIzquierda, margen),
			Math.max(margen, window.innerWidth - margen - ancho)
		);

		const huecoArriba = disparador.top - separacion - margen;
		const huecoAbajo = window.innerHeight - disparador.bottom - separacion - margen;

		if (alto <= huecoArriba) lado = 'arriba';
		else if (alto <= huecoAbajo) lado = 'abajo';
		else lado = huecoArriba >= huecoAbajo ? 'arriba' : 'abajo';

		const hueco = lado === 'arriba' ? huecoArriba : huecoAbajo;
		maxAlto = alto > hueco ? Math.max(hueco, 64) : null;

		const altoFinal = maxAlto ?? alto;
		arriba =
			lado === 'arriba'
				? Math.max(disparador.top - separacion - altoFinal, margen)
				: Math.min(disparador.bottom + separacion, window.innerHeight - margen - altoFinal);
	}

	async function alternar() {
		abierto = !abierto;
		if (!abierto) return;
		await tick();
		colocar();
	}

	$effect(() => {
		if (!abierto) return;

		const cerrarFuera = (event: PointerEvent) => {
			if (!root?.contains(event.target as Node)) abierto = false;
		};
		const cerrarConEscape = (event: KeyboardEvent) => {
			if (event.key === 'Escape') abierto = false;
		};
		const recolocar = () => colocar();

		window.addEventListener('pointerdown', cerrarFuera);
		window.addEventListener('keydown', cerrarConEscape);
		window.addEventListener('resize', recolocar);
		window.addEventListener('scroll', recolocar, true);
		return () => {
			window.removeEventListener('pointerdown', cerrarFuera);
			window.removeEventListener('keydown', cerrarConEscape);
			window.removeEventListener('resize', recolocar);
			window.removeEventListener('scroll', recolocar, true);
		};
	});
</script>

<span class="relative inline-flex align-middle {claseRaiz}" style={estiloRaiz} bind:this={root}>
	<button
		type="button"
		class={disparador
			? claseBoton
			: 'ml-1 inline-flex size-4 items-center justify-center text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-1'}
		aria-label={abierto ? 'Ocultar nota' : label}
		aria-expanded={abierto}
		onclick={alternar}
	>
		{#if disparador}{@render disparador()}{:else}<Info
				size={13}
				strokeWidth={1.75}
				aria-hidden="true"
			/>{/if}
	</button>
	{#if abierto}
		<span
			class="fixed z-40 w-max min-w-52 max-w-[min(22rem,calc(100vw-1rem))] overflow-y-auto whitespace-normal break-words border border-[color:var(--border)] bg-white px-3 py-2 text-left text-xs font-normal leading-5 text-[color:var(--foreground)] shadow-md"
			style={`left:${izquierda}px;top:${arriba}px${maxAlto === null ? '' : `;max-height:${maxAlto}px`}`}
			role="tooltip"
			data-side={lado}
			bind:this={bubble}
		>
			{@html renderInlineMarkdown(text)}
		</span>
	{/if}
</span>
