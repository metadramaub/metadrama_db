<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		eyebrow,
		title,
		description,
		descriptionContent,
		actions
	} = $props<{
		eyebrow: string;
		title: string;
		description?: string;
		descriptionContent?: Snippet;
		actions?: Snippet;
	}>();
</script>

<header class="border-l-2 border-[color:var(--primary)] pl-5 md:pl-7">
	<div class="flex flex-col items-start justify-between gap-5 sm:flex-row sm:gap-8">
		<div class="min-w-0 flex-1">
			<p class="text-[10px] font-semibold tracking-[0.2em] text-[color:var(--primary)]">{eyebrow}</p>
			<h1 class="font-display mt-3 text-4xl text-[color:var(--gray-900)] md:text-5xl">{title}</h1>
			{#if descriptionContent}
				<div class="mt-4 space-y-2 text-sm leading-7 text-[color:var(--muted-foreground)]">
					{@render descriptionContent()}
				</div>
			{:else if description}
				<p class="mt-4 text-sm leading-7 text-[color:var(--muted-foreground)]">{description}</p>
			{/if}
		</div>
		{#if actions}
			<div class="shrink-0">{@render actions()}</div>
		{/if}
	</div>
</header>
