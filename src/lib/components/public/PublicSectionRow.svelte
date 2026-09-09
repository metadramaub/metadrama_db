<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		number,
		title,
		contentClass = 'space-y-4',
		children
	} = $props<{
		number: string;
		title: string;
		contentClass?: string;
		children: Snippet;
	}>();
</script>

<section class="grid gap-5 border-t border-[color:var(--border)] py-8 md:grid-cols-3 md:py-10">
	<header>
		<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--gray-400)]">{number}</p>
		<h2 class="font-display mt-3 text-2xl text-[color:var(--gray-900)]">{title}</h2>
	</header>
	<div class={`text-sm leading-7 text-[color:var(--gray-700)] md:col-span-2 ${contentClass}`}>
		{@render children()}
	</div>
</section>
