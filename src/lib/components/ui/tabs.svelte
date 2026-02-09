<script lang="ts">
	const props = $props<{
		tabs: { id: string; label: string }[];
		active: string;
		onChange: (id: string) => void;
	}>();
</script>

<div class="flex flex-wrap gap-2 border-b border-[color:var(--border)] pb-2">
	{#each props.tabs as tab}
		<button
			type="button"
			class={`rounded-md px-3 py-2 text-sm ${props.active === tab.id ? 'bg-[color:var(--primary)] text-[color:var(--primary-foreground)]' : 'bg-white text-[color:var(--foreground)] border border-[color:var(--border)]'}`}
			onclick={() => props.onChange(tab.id)}
		>
			{tab.label}
		</button>
	{/each}
</div>
