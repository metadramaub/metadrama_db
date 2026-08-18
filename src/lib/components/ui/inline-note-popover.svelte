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

	const margen = 8;
	const separacion = 6;

	function colocar() {
		if (!root || !bubble) return;
		const disparador = root.getBoundingClientRect();
		const ancho = bubble.offsetWidth;
		const alto = bubble.offsetHeight;
		const izquierdaIdeal = disparador.right - ancho;
		izquierda = Math.min(
			Math.max(izquierdaIdeal, margen),
			Math.max(margen, window.innerWidth - margen - ancho)
		);

		const sobre = disparador.top - separacion - alto;
		const debajo = disparador.bottom + separacion;
		const cabeSobre = sobre >= margen;
		const cabeDebajo = debajo + alto <= window.innerHeight - margen;
		lado = cabeSobre || !cabeDebajo ? 'arriba' : 'abajo';
		const arribaIdeal = lado === 'arriba' ? sobre : debajo;
		arriba = Math.min(
			Math.max(arribaIdeal, margen),
			Math.max(margen, window.innerHeight - margen - alto)
		);
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
			class="fixed z-40 w-max min-w-52 max-w-[min(22rem,calc(100vw-1rem))] border border-[color:var(--border)] bg-white px-3 py-2 text-left text-xs font-normal leading-5 text-[color:var(--foreground)] shadow-md"
			style={`left:${izquierda}px;top:${arriba}px`}
			role="tooltip"
			data-side={lado}
			bind:this={bubble}
		>
			{@html renderInlineMarkdown(text)}
		</span>
	{/if}
</span>
