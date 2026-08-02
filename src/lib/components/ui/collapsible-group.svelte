<script lang="ts">
	import type { Snippet } from 'svelte';
	import ChevronDown from 'lucide-svelte/icons/chevron-down';

	/**
	 * Un bloque del formulario con su título y su pliegue. Sirve para aligerar una pantalla
	 * larga sin esconder nada: el título sigue viéndose y dice qué hay dentro.
	 */
	const props = $props<{
		id: string;
		title: string;
		/** Lo que se lee en la cabecera cuando está plegado. */
		summary?: string;
		open?: boolean;
		onToggle?: (open: boolean) => void;
		children: Snippet;
	}>();

	let internalOpen = $state(true);
	const open = $derived(props.open ?? internalOpen);

	function toggle() {
		const next = !open;
		internalOpen = next;
		props.onToggle?.(next);
	}
</script>

<section id={props.id} class="border border-[color:var(--border)] bg-white">
	<h3 class="m-0">
		<button
			type="button"
			class="flex w-full items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-4 py-2.5 text-left transition-colors hover:bg-[color:var(--border)]"
			class:border-b-0={!open}
			aria-expanded={open}
			aria-controls={`${props.id}-cuerpo`}
			onclick={toggle}
		>
			<span class="form-section-title mb-0">{props.title}</span>
			<span class="flex min-w-0 items-center gap-2">
				{#if !open && props.summary}
					<span class="truncate text-xs text-[color:var(--muted-foreground)]">
						{props.summary}
					</span>
				{/if}
				<ChevronDown
					size={16}
					class={`shrink-0 text-[color:var(--muted-foreground)] transition-transform ${open ? '' : '-rotate-90'}`}
				/>
			</span>
		</button>
	</h3>
	<div id={`${props.id}-cuerpo`} class="space-y-4 p-4" hidden={!open}>
		{@render props.children()}
	</div>
</section>
