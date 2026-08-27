<script lang="ts">
	import type { Snippet } from 'svelte';
	import CircleHelp from 'lucide-svelte/icons/circle-help';

	const props = $props<{
		category: string;
		title: string;
		description: Snippet;
		onHelp: () => void;
	}>();
</script>

<header class="border-b border-[color:var(--border)] pb-6">
	<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
		{props.category}
	</p>
	<div class="mt-2 flex flex-col items-start justify-between gap-4 sm:flex-row sm:gap-8">
		<div class="max-w-3xl">
			<h1 class="font-display text-3xl text-[color:var(--gray-900)] md:text-4xl">
				{props.title}
			</h1>
			<div class="mt-3 space-y-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
				{@render props.description()}
			</div>
		</div>
		<button
			type="button"
			class="inline-flex shrink-0 items-center gap-2 border border-[color:var(--border)] bg-white px-4 py-2 text-sm font-semibold transition-colors hover:border-[color:var(--gray-800)]"
			onclick={props.onHelp}
		>
			<CircleHelp size={16} aria-hidden="true" />
			Ayuda
		</button>
	</div>
</header>
