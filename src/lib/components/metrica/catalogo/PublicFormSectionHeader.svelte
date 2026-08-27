<script lang="ts">
	const { title, description, count } = $props<{
		title: string;
		description?: string;
		count?: number;
	}>();
</script>

<header class="border-b border-[color:var(--border)] pb-4">
	<div class="flex flex-wrap items-baseline justify-between gap-3">
		<h2 class="font-display text-2xl text-[color:var(--gray-900)] md:text-3xl">{title}</h2>
		{#if count !== undefined}
			<span class="text-sm tabular-nums text-[color:var(--muted-foreground)]">{count}</span>
		{/if}
	</div>
	{#if description}
		<p class="mt-2 max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			{description}
		</p>
	{/if}
</header>
