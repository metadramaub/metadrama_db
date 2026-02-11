<script lang="ts">
	import Sidebar from '$lib/components/dashboard/Sidebar.svelte';
	import type { LayoutData } from './$types';
	import { page } from '$app/stores';

	let { data, children } = $props<{ data: LayoutData; children: () => unknown }>();

	const breadcrumbs = $derived(
		$page.url.pathname
			.split('/')
			.filter(Boolean)
			.map((segment) => segment.replaceAll('-', ' '))
	);
</script>

<div class="grid min-h-screen md:grid-cols-[18rem_1fr]">
	<Sidebar profile={data.profile} misObrasCount={data.misObrasCount} />
	<main class="min-w-0 bg-[color:var(--background)] p-6">
		<div class="mb-4 border-b border-[color:var(--border)] pb-3 text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]">
			{#if breadcrumbs.length === 0}
				DASHBOARD
			{:else}
				{breadcrumbs.join(' / ').toUpperCase()}
			{/if}
		</div>
		{@render children()}
	</main>
</div>
