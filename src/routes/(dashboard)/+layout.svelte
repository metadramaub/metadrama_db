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

<div class="grid min-h-screen grid-cols-[18rem_1fr]">
	<Sidebar profile={data.profile} misObrasCount={data.misObrasCount} />
	<main class="min-w-0 p-6">
		<div class="mb-4 text-sm text-[color:var(--muted-foreground)]">
			{#if breadcrumbs.length === 0}
				dashboard
			{:else}
				{breadcrumbs.join(' / ')}
			{/if}
		</div>
		{@render children()}
	</main>
</div>
