<script lang="ts">
	import type { Snippet } from 'svelte';
	import ChevronLeft from 'lucide-svelte/icons/chevron-left';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Button from '$lib/components/ui/button.svelte';

	/**
	 * El contenedor donde se anota una secuencia.
	 *
	 * **Por qué es un modal ancho y no un panel lateral.** Lo que el editor V2 pide no es un campo:
	 * es una rejilla verso a verso, las preguntas de cada unidad, las desviaciones y, debajo, todo lo
	 * que no es métrico. En el panel lateral de la pestaña de secuencias eso no cabe, y trabajar así
	 * obliga a desplazarse tanto que se pierde de vista el pasaje que se está leyendo.
	 *
	 * **Y por qué vive aquí y no dentro del laboratorio.** Nació ahí, pero lo usan dos sitios: el
	 * editor de pruebas y la pestaña de secuencias de una obra. Separarlo es lo que impide que se
	 * separen ellos: si el laboratorio y la obra se anotaran en pantallas distintas, probar en uno
	 * dejaría de decir nada del otro.
	 *
	 * No sabe nada de guardar ni de qué es una secuencia. Recibe lo que tiene que enseñar y avisa de
	 * lo que se pulsa; quien lo monta decide qué significa cada cosa.
	 */
	const props = $props<{
		/** «Nueva secuencia» o «Editar secuencia»: lo decide quien lo monta. */
		titulo: string;
		/** Los versos que abarca, para tenerlos siempre a la vista mientras se anota. */
		rango?: { v_ini: number; v_fin: number } | null;
		/**
		 * Dónde cae esta secuencia entre las de la obra, para ir a la anterior y a la siguiente sin
		 * cerrar. Se omite cuando aún no está guardada: no está en ninguna parte todavía.
		 */
		posicion?: { indice: number; total: number } | null;
		alAnterior?: () => void;
		alSiguiente?: () => void;
		hayAnterior?: boolean;
		haySiguiente?: boolean;
		/**
		 * Cuántas preguntas hay contestadas de cuántas. **Se ve antes de pulsar Guardar**, no
		 * después del aviso: enterarse de que falta algo cuando ya creías haber terminado es la
		 * manera más segura de que se quede sin contestar.
		 */
		respuestas?: { contestadas: number; total: number } | null;
		sucio?: boolean;
		guardando?: boolean;
		error?: string | null;
		/** Solo se ofrece borrar lo que ya existe. */
		alEliminar?: (() => void) | null;
		alCerrar: () => void;
		alGuardar: () => void;
		children: Snippet;
	}>();

	const versos = $derived(props.rango ? props.rango.v_fin - props.rango.v_ini + 1 : 0);
</script>

<div class="fixed inset-0 z-40 flex items-start justify-center bg-black/50 p-4">
	<!--
		`inert` mientras guarda: no basta con deshabilitar los botones, porque el cuerpo entero sigue
		siendo editable y un cambio hecho a mitad del guardado se perdería sin que nadie lo dijera.
	-->
	<div
		class="flex max-h-[92vh] w-full max-w-6xl flex-col overflow-hidden border border-[color:var(--border)] bg-[color:var(--gray-50)]"
		inert={props.guardando}
		aria-busy={props.guardando}
	>
		<div class="border-b border-[color:var(--border)] bg-white px-5 py-3">
			<div class="flex flex-wrap items-center justify-between gap-3">
				<div class="flex min-w-0 items-center gap-3">
					<h3 class="text-base font-semibold">{props.titulo}</h3>
					{#if props.rango}
						<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
							vv. {props.rango.v_ini}–{props.rango.v_fin} · {versos}
							{versos === 1 ? 'verso' : 'versos'}
						</span>
					{/if}
					{#if props.posicion}
						<div class="flex items-center gap-1">
							<button
								type="button"
								class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
								aria-label="Secuencia anterior"
								onclick={() => props.alAnterior?.()}
								disabled={!props.hayAnterior || props.guardando}
							>
								<ChevronLeft size={18} />
							</button>
							<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
								{props.posicion.indice} / {props.posicion.total}
							</span>
							<button
								type="button"
								class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
								aria-label="Secuencia siguiente"
								onclick={() => props.alSiguiente?.()}
								disabled={!props.haySiguiente || props.guardando}
							>
								<ChevronRight size={18} />
							</button>
						</div>
					{/if}
					{#if props.respuestas && props.respuestas.total > 0}
						<span
							class={`whitespace-nowrap text-sm ${
								props.respuestas.contestadas < props.respuestas.total
									? 'text-[color:var(--primary)]'
									: 'text-[color:var(--muted-foreground)]'
							}`}
						>
							{props.respuestas.contestadas} de {props.respuestas.total}
							{props.respuestas.total === 1 ? 'respuesta' : 'respuestas'}
						</span>
					{/if}
				</div>
				<div class="flex items-center gap-2">
					{#if props.sucio}
						<span class="text-xs text-[color:var(--muted-foreground)]">Cambios sin guardar</span>
					{/if}
					{#if props.alEliminar}
						<Button variant="danger" onclick={() => props.alEliminar?.()} disabled={props.guardando}>
							Eliminar
						</Button>
					{/if}
					<Button variant="secondary" onclick={props.alCerrar} disabled={props.guardando}>
						Cerrar
					</Button>
					<Button
						variant="success"
						onclick={props.alGuardar}
						disabled={props.guardando}
						loading={props.guardando}
						loadingLabel="Guardando…"
					>
						Guardar
					</Button>
				</div>
			</div>
			{#if props.error}
				<p class="mt-2 border-l-4 border-red-500 bg-red-50 p-2 text-sm text-red-900">
					{props.error}
				</p>
			{/if}
		</div>

		<!-- El cuerpo se desplaza solo, para que la cabecera no se vaya al leer un pasaje largo. -->
		<div class="min-h-0 flex-1 overflow-y-auto">
			{@render props.children()}
		</div>
	</div>
</div>
