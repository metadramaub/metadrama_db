<script lang="ts">
	import type { Snippet } from 'svelte';
	import X from 'lucide-svelte/icons/x';

	const props = $props<{
		open: boolean;
		title: string;
		onClose: () => void;
		children: Snippet;
	}>();

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Escape' && props.open) props.onClose();
	}
</script>

<svelte:window onkeydown={handleKeydown} />

{#if props.open}
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/45 px-4 py-6"
		role="presentation"
		onclick={(event) => {
			if (event.currentTarget === event.target) props.onClose();
		}}
	>
		<div
			class="max-h-full w-full max-w-2xl overflow-y-auto border border-[color:var(--border)] bg-white shadow-xl"
			role="dialog"
			aria-modal="true"
			aria-labelledby="public-help-dialog-title"
		>
			<header class="sticky top-0 flex items-start justify-between gap-5 border-b border-[color:var(--border)] bg-white px-5 py-4 sm:px-7">
				<div>
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Ayuda
					</p>
					<h2 id="public-help-dialog-title" class="font-display mt-1 text-2xl">{props.title}</h2>
				</div>
				<button
					type="button"
					class="inline-flex h-9 w-9 shrink-0 items-center justify-center border border-[color:var(--border)] text-[color:var(--muted-foreground)] transition-colors hover:border-[color:var(--gray-800)] hover:text-[color:var(--foreground)]"
					onclick={props.onClose}
					aria-label="Cerrar ayuda"
				>
					<X size={17} aria-hidden="true" />
				</button>
			</header>
			<div class="p-5 sm:p-7">
				{@render props.children()}
			</div>
		</div>
	</div>
{/if}
