<script lang="ts">
	import type { Snippet } from 'svelte';
	let { children }: { children: Snippet } = $props();
</script>

<div class="overflow-x-auto">
	<table class="w-full text-left text-sm [&>thead]:text-xs [&>thead]:text-[color:var(--foreground)] [&>thead_th]:font-medium">
		{@render children()}
	</table>
</div>
