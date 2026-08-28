<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Una de las secciones del modal de anotación, plegable y con nombre.
	 *
	 * El modal reúne cuatro cosas que se anotan a la vez pero se miran por separado —la métrica, las
	 * caracterizaciones, la sinopsis y los comentarios—, y desplegadas todas no caben: hay que
	 * recorrer la pantalla entera para llegar a la última. Cada una se pliega, **y solo la primera
	 * viene abierta**, que es donde empieza el trabajo.
	 *
	 * El raíl de la izquierda es el índice de estas secciones: pulsar allí abre la que toca y baja
	 * hasta ella.
	 */
	const props = $props<{
		/** El ancla a la que salta el raíl. */
		id: string;
		titulo: string;
		abierta: boolean;
		alAlternar: () => void;
		/** Qué decir plegada, para no tener que abrirla solo para ver si tiene algo. */
		resumen?: string | null;
		children: Snippet;
	}>();
</script>

<section id={props.id} class="border border-[color:var(--border)] bg-white">
	<div
		class={`flex flex-wrap items-center justify-between gap-2 bg-[color:var(--muted)] px-4 py-2.5 ${
			props.abierta ? 'border-b border-[color:var(--border)]' : ''
		}`}
	>
		<h3 class="form-panel-title">{props.titulo}</h3>
		<div class="flex items-baseline gap-3">
			{#if !props.abierta && props.resumen}
				<span class="text-xs text-[color:var(--muted-foreground)]">{props.resumen}</span>
			{/if}
			<button
				type="button"
				class="link-action text-xs"
				aria-expanded={props.abierta}
				aria-controls={`${props.id}-cuerpo`}
				onclick={props.alAlternar}
			>
				{props.abierta ? 'Colapsar' : 'Desplegar'}
			</button>
		</div>
	</div>
	{#if props.abierta}
		<div id={`${props.id}-cuerpo`} class="space-y-4 p-4">
			{@render props.children()}
		</div>
	{/if}
</section>
