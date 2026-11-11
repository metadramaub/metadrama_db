<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import type { Snippet } from 'svelte';
	let { href, children, detail }: { href: string; children: Snippet; detail?: Snippet } = $props();
</script>

<a {href} class="group flex items-center gap-3 px-3 py-3 text-sm transition-colors hover:bg-[color:var(--muted)] focus-visible:bg-[color:var(--muted)]">
	<div class="min-w-0 flex-1">{@render children()}</div>
	{@render detail?.()}
	<ArrowRight size={16} class="shrink-0 transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
</a>
