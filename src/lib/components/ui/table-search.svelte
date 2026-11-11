<script lang="ts">
	import { Search } from 'lucide-svelte';
	let { value = $bindable(''), label }: { value?: string; label: string } = $props();
</script>

<label class="relative block min-w-0 flex-1">
	<span class="sr-only">{label}</span>
	<Search size={16} aria-hidden="true" class="pointer-events-none absolute left-2.5 top-2 text-[color:var(--muted-foreground)]" />
	<input type="search" bind:value placeholder={label}
		class="h-8 w-full border border-[color:var(--border)] bg-white pl-8 pr-2.5 text-sm" />
</label>
