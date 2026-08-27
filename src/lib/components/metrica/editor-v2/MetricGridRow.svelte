<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Una fila de la rejilla del editor: a la izquierda una parte de la secuencia, a la
	 * derecha lo que hay que responder de ella.
	 *
	 * Vive aparte porque la usan los dos componentes —el editor de estructura y la pregunta
	 * de medida que le llega desde arriba—, y tenerla escrita dos veces era garantía de que
	 * las dos columnas dejaran de alinearse.
	 */
	const props = $props<{
		/** Qué parte de la secuencia es: «Mudanza», «Quintilla 2», «Las 3 mudanzas». */
		label: string;
		/** El rango, cuando la fila es una realización concreta. */
		rango?: string;
		/** Lo que se dice de su extensión cuando no se puede tocar. */
		nota?: string;
		/** Por qué la extensión no se toca. */
		notaAyuda?: string;
		/** Sangrado: 0 es la unidad, 1 sus secciones, 2 las partes de estas. */
		depth?: number;
		/** `grupo` abre un bloque estructural, como cada ciclo del villancico. */
		variant?: 'normal' | 'comun' | 'resumen' | 'grupo';
		actionLabel?: string;
		onAction?: () => void;
		children?: Snippet;
	}>();

	const depth = $derived(Math.max(0, props.depth ?? 0));
	const variant = $derived(props.variant ?? 'normal');
</script>

<div
	class={`grid gap-x-4 gap-y-2 border-b border-[color:var(--border)] px-3 last:border-b-0 sm:grid-cols-[minmax(9rem,15rem)_minmax(0,1fr)] ${
		variant === 'comun'
			? 'bg-[color:var(--muted)] py-2'
			: variant === 'resumen'
				? 'bg-[color:var(--gray-50)] py-2'
				: variant === 'grupo'
					? 'border-t border-t-[color:var(--border)] bg-[color:var(--muted)] py-3'
					: 'bg-white py-2'
	}`}
>
	<div
		class={depth > 0 ? 'border-l border-[color:var(--border)] pl-3' : ''}
		style={depth > 1 ? `margin-left:${(depth - 1) * 0.9}rem` : undefined}
	>
		<span
			class={`block text-sm leading-snug ${
				variant === 'resumen'
					? 'text-[color:var(--muted-foreground)]'
					: 'font-medium text-[color:var(--foreground)]'
			}`}
		>
			{props.label}
		</span>
		{#if props.rango}
			<span
				class="block text-xs leading-snug tabular-nums text-[color:var(--muted-foreground)]"
			>
				{props.rango}
			</span>
		{/if}
		{#if props.nota}
			<span
				class="block text-xs leading-snug text-[color:var(--muted-foreground)]"
				title={props.notaAyuda}
			>
				{props.nota}
			</span>
		{/if}
		<!--
			La acción va **debajo** del rótulo, no enfrentada a él. Arriba, «Desplegar» quedaba
			flotando a la derecha de una columna estrecha, lejos del nombre al que se refiere y
			desalineado con todo lo demás.
		-->
		{#if props.actionLabel && props.onAction}
			<button type="button" class="link-action mt-1 block text-xs" onclick={props.onAction}>
				{props.actionLabel}
			</button>
		{/if}
	</div>
	<div class="flex min-w-0 flex-col gap-2">
		{@render props.children?.()}
	</div>
</div>
