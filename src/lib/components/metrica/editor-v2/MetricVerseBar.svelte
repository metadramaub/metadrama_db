<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Un verso dibujado como una barra proporcional a lo que mide.
	 *
	 * Nació en la pregunta de los pies quebrados, donde ver el verso corto *más corto* dice de un
	 * vistazo lo que un número obliga a comparar. Vive aparte porque **cualquier pregunta de medida
	 * merece verse igual**: la del quebrado de la copla castellana, la de sus posiciones fijas en la
	 * manriqueña y la de las formas aliradas abiertas, que eligen entre siete y once en cada verso.
	 * Lo que cambia entre ellas es qué controles van a la derecha y con qué se compara la anchura;
	 * la barra es la misma.
	 *
	 * `maximo` es la medida contra la que se escala. En una forma con medida de base es esa base
	 * —así los quebrados se ven más cortos que el resto—; en una forma abierta, la mayor del
	 * repertorio, para que el endecasílabo llene y el heptasílabo no.
	 */
	/*
	 * **La rejilla se estrecha hasta donde haga falta.** Reservaba `12rem` fijos para los controles
	 * de la derecha, que en una forma alirada son dos botones de tres letras, y `9rem` mínimos para
	 * la barra: dentro del modal eso se salía por la derecha. Ahora la columna de la barra puede
	 * encogerse y la de los controles ocupa lo que ocupe.
	 */
	const props = $props<{
		/** «Verso 3». */
		etiqueta: string;
		/** Lo que mide, si ya se sabe. */
		silabas: number | null;
		/** Con qué se compara la anchura. */
		maximo: number | null;
		/**
		 * `base` es lo que pone la norma sin preguntar; `elegida`, lo que ha respondido el editor;
		 * `pendiente`, un verso marcado al que le falta la medida; `vacia`, lo que no se sabe aún.
		 */
		variante: 'base' | 'elegida' | 'pendiente' | 'vacia';
		/** «BASE», «QUEBRADO», «ELIGE LA MEDIDA». */
		distintivo?: string;
		/** Qué decir cuando no hay medida que escribir. */
		texto?: string;
		/** Los controles de la derecha, que cambian según la pregunta. */
		children?: Snippet;
	}>();

	const destacada = $derived(props.variante === 'elegida' || props.variante === 'pendiente');

	// Un mínimo del 30 % para que la barra más corta siga siendo legible.
	const anchura = $derived.by(() => {
		const silabas = props.silabas;
		const maximo = props.maximo;
		if (!silabas || !maximo) return 100;
		return Math.max(30, Math.min(100, (silabas / maximo) * 100));
	});
</script>

<div class="grid min-w-0 items-center gap-2 sm:grid-cols-[3rem_minmax(0,1fr)_auto]">
	<span class="text-xs text-[color:var(--muted-foreground)]">{props.etiqueta}</span>
	<div class="relative h-9 overflow-hidden border border-[color:var(--border)] bg-white">
		<div
			class={`absolute inset-y-0 left-0 ${
				destacada ? 'bg-amber-100' : 'bg-[color:var(--muted)]'
			}`}
			style={`width: ${anchura}%`}
		></div>
		<span class="relative flex h-full items-center px-2 text-xs">
			{#if props.silabas}
				<span class="font-medium tabular-nums">{props.silabas} sílabas</span>
			{:else if props.texto}
				<span class="font-medium">{props.texto}</span>
			{/if}
			{#if props.distintivo}
				<span
					class={`ml-1.5 text-[0.65rem] font-medium uppercase tracking-wide ${
						destacada ? 'text-amber-800' : 'text-[color:var(--muted-foreground)]'
					}`}
				>
					{props.distintivo}
				</span>
			{/if}
		</span>
	</div>
	{#if props.children}
		{@render props.children()}
	{/if}
</div>
