<script lang="ts">
	import type { Snippet } from 'svelte';

	const props = $props<{
		tabs: { id: string; label: string }[];
		active: string;
		onChange: (id: string) => void;
		actions?: Snippet;
	}>();
</script>

<div class="flex flex-wrap items-center gap-2 border-b border-[color:var(--border)] pb-2">
	<div class="flex flex-wrap gap-2">
		{#each props.tabs as tab}
			<button
				type="button"
				class={`border px-3 py-2 text-sm ${props.active === tab.id ? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]' : 'border-[color:var(--border)] bg-white text-[color:var(--foreground)]'}`}
				onclick={() => props.onChange(tab.id)}
			>
				{tab.label}
			</button>
		{/each}
	</div>

	{#if props.actions}
		<div class="ml-auto">
			{@render props.actions()}
		</div>
	{/if}
</div>
