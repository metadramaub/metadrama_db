<script lang="ts">
	import type { Snippet } from 'svelte';
	let { search, controls }: { search?: Snippet; controls?: Snippet } = $props();
</script>

<div class="mb-2 flex flex-wrap items-center justify-end gap-2 text-sm">
	{#if search}
		<div class="mr-auto w-full sm:max-w-xs">{@render search()}</div>
	{/if}
	{#if controls}
		<div class="ml-auto flex flex-wrap items-center gap-2">{@render controls()}</div>
	{/if}
</div>
